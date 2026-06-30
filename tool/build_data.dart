// Lê tool/exercises_raw.json, traduz as instruções (EN -> PT) e gera
// assets/data/exercises.json enxuto com instruções em pt e en.
//
// As traduções ficam em cache em tool/pt_cache.json para que reexecuções
// não refaçam o trabalho (e para poder retomar caso seja interrompido).
//
// Rode com: dart run tool/build_data.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _concurrency = 6;

Future<void> main() async {
  final raw = File('tool/exercises_raw.json').readAsStringSync();
  final List<dynamic> data = json.decode(raw) as List<dynamic>;

  // Carrega cache existente (id -> tradução PT).
  final cacheFile = File('tool/pt_cache.json');
  final Map<String, String> cache = cacheFile.existsSync()
      ? (json.decode(cacheFile.readAsStringSync()) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()))
      : <String, String>{};

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  // Itens que ainda precisam de tradução.
  final pending = <Map<String, dynamic>>[];
  for (final dynamic e in data) {
    final m = e as Map<String, dynamic>;
    final id = m['id'].toString();
    final en = ((m['instructions'] as Map<String, dynamic>?)?['en'] ?? '')
        .toString();
    if (en.isNotEmpty && !cache.containsKey(id)) pending.add(m);
  }
  stdout.writeln('Total: ${data.length} | já em cache: ${cache.length} | '
      'a traduzir: ${pending.length}');

  var done = 0;
  var sinceSave = 0;
  Future<void> worker(List<Map<String, dynamic>> chunk) async {
    for (final m in chunk) {
      final id = m['id'].toString();
      final en =
          ((m['instructions'] as Map<String, dynamic>)['en'] ?? '').toString();
      try {
        cache[id] = await _translate(client, en);
      } catch (err) {
        stderr.writeln('Falha no id $id: $err');
        cache[id] = en; // fallback: mantém inglês
      }
      done++;
      sinceSave++;
      if (sinceSave >= 50) {
        cacheFile.writeAsStringSync(json.encode(cache));
        sinceSave = 0;
        stdout.writeln('  ...$done/${pending.length} traduzidos');
      }
    }
  }

  // Divide o trabalho em N filas e roda em paralelo.
  final chunks = List.generate(_concurrency, (_) => <Map<String, dynamic>>[]);
  for (var i = 0; i < pending.length; i++) {
    chunks[i % _concurrency].add(pending[i]);
  }
  await Future.wait(chunks.map(worker));
  cacheFile.writeAsStringSync(json.encode(cache));
  client.close();

  // Monta o JSON final.
  final out = <Map<String, dynamic>>[];
  for (final dynamic e in data) {
    final m = e as Map<String, dynamic>;
    final id = m['id'].toString();
    final en = ((m['instructions'] as Map<String, dynamic>?)?['en'] ?? '')
        .toString();
    out.add({
      'id': m['id'],
      'name': m['name'],
      'category': m['category'],
      'equipment': m['equipment'],
      'target': m['target'],
      'secondary_muscles': m['secondary_muscles'] ?? <String>[],
      'image': m['image'],
      'gif_url': m['gif_url'],
      'instructions': {
        'pt': cache[id] ?? en,
        'en': en,
      },
    });
  }

  final encoded = json.encode(out);
  File('assets/data/exercises.json').writeAsStringSync(encoded);
  stdout.writeln('Escreveu ${out.length} exercícios em '
      'assets/data/exercises.json');
  stdout.writeln('Tamanho: ${(encoded.length / 1024 / 1024).toStringAsFixed(2)} MB');
}

/// Traduz [text] de inglês para português via endpoint público do Google.
Future<String> _translate(HttpClient client, String text) async {
  final uri = Uri.parse('https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=en&tl=pt&dt=t');
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      req.write('q=${Uri.encodeQueryComponent(text)}');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        throw HttpException('status ${resp.statusCode}');
      }
      final decoded = json.decode(body) as List<dynamic>;
      final segments = decoded[0] as List<dynamic>;
      final buffer = StringBuffer();
      for (final seg in segments) {
        buffer.write((seg as List<dynamic>)[0].toString());
      }
      return buffer.toString().trim();
    } catch (err) {
      if (attempt == 3) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }
  return text;
}
