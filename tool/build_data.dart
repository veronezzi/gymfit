// Lê tool/exercises_raw.json, traduz nomes e instruções (EN -> PT) e gera
// assets/data/exercises.json enxuto com `name` e `instructions` como mapas
// {pt, en}.
//
// As traduções ficam em cache (tool/pt_cache.json e tool/pt_name_cache.json)
// para que reexecuções não refaçam o trabalho.
//
// Rode com: dart run tool/build_data.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _concurrency = 4;
final _client = HttpClient()..connectionTimeout = const Duration(seconds: 20);

Future<void> main() async {
  final raw = File('tool/exercises_raw.json').readAsStringSync();
  final List<dynamic> data = json.decode(raw) as List<dynamic>;

  // Mapas id -> texto em inglês.
  final enInstructions = <String, String>{};
  final enNames = <String, String>{};
  for (final dynamic e in data) {
    final m = e as Map<String, dynamic>;
    final id = m['id'].toString();
    enInstructions[id] =
        ((m['instructions'] as Map<String, dynamic>?)?['en'] ?? '').toString();
    enNames[id] = (m['name'] ?? '').toString();
  }

  final ptInstructions = await _translateAll(
      enInstructions, File('tool/pt_cache.json'), 'instruções');
  final ptNames =
      await _translateAll(enNames, File('tool/pt_name_cache.json'), 'nomes');
  _client.close();

  // Monta o JSON final.
  final out = <Map<String, dynamic>>[];
  for (final dynamic e in data) {
    final m = e as Map<String, dynamic>;
    final id = m['id'].toString();
    out.add({
      'id': m['id'],
      'name': {
        'pt': ptNames[id] ?? enNames[id],
        'en': enNames[id],
      },
      'category': m['category'],
      'equipment': m['equipment'],
      'target': m['target'],
      'secondary_muscles': m['secondary_muscles'] ?? <String>[],
      'image': m['image'],
      'gif_url': m['gif_url'],
      'instructions': {
        'pt': ptInstructions[id] ?? enInstructions[id],
        'en': enInstructions[id],
      },
    });
  }

  final encoded = json.encode(out);
  File('assets/data/exercises.json').writeAsStringSync(encoded);
  stdout.writeln('Escreveu ${out.length} exercícios em '
      'assets/data/exercises.json');
  stdout.writeln('Tamanho: ${(encoded.length / 1024 / 1024).toStringAsFixed(2)} MB');
}

/// Traduz todos os textos de [source] (id -> EN), usando [cacheFile] para
/// retomar trabalho já feito. Retorna mapa id -> tradução PT.
Future<Map<String, String>> _translateAll(
    Map<String, String> source, File cacheFile, String label) async {
  final Map<String, String> cache = cacheFile.existsSync()
      ? (json.decode(cacheFile.readAsStringSync()) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()))
      : <String, String>{};

  final pending = <String>[];
  source.forEach((id, en) {
    if (en.isNotEmpty && !cache.containsKey(id)) pending.add(id);
  });
  stdout.writeln('[$label] total ${source.length} | em cache ${cache.length} '
      '| a traduzir ${pending.length}');

  var done = 0;
  var sinceSave = 0;
  Future<void> worker(List<String> ids) async {
    for (final id in ids) {
      try {
        cache[id] = await _translate(source[id]!);
      } catch (err) {
        // Não cacheia falha: fica pendente para retry numa próxima execução.
        // No JSON final cai no fallback para inglês.
        stderr.writeln('[$label] falha no id $id: $err');
      }
      done++;
      sinceSave++;
      if (sinceSave >= 50) {
        cacheFile.writeAsStringSync(json.encode(cache));
        sinceSave = 0;
        stdout.writeln('  [$label] ...$done/${pending.length}');
      }
    }
  }

  final chunks = List.generate(_concurrency, (_) => <String>[]);
  for (var i = 0; i < pending.length; i++) {
    chunks[i % _concurrency].add(pending[i]);
  }
  await Future.wait(chunks.map(worker));
  cacheFile.writeAsStringSync(json.encode(cache));
  return cache;
}

/// Traduz [text] de inglês para português via endpoint público do Google.
Future<String> _translate(String text) async {
  final uri = Uri.parse('https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=en&tl=pt&dt=t');
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      final req = await _client.postUrl(uri);
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
