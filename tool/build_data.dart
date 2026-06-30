// Lê tool/exercises_raw.json e gera assets/data/exercises.json enxuto.
// Mantém apenas os campos usados pelo app e instruções em inglês.
// Rode com: dart run tool/build_data.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final raw = File('tool/exercises_raw.json').readAsStringSync();
  final List<dynamic> data = json.decode(raw) as List<dynamic>;

  final out = <Map<String, dynamic>>[];
  for (final dynamic e in data) {
    final m = e as Map<String, dynamic>;
    final instructions = (m['instructions'] as Map<String, dynamic>?) ?? {};
    out.add({
      'id': m['id'],
      'name': m['name'],
      'category': m['category'],
      'equipment': m['equipment'],
      'target': m['target'],
      'secondary_muscles': m['secondary_muscles'] ?? <String>[],
      'image': m['image'],
      'gif_url': m['gif_url'],
      'instructions': instructions['en'] ?? '',
    });
  }

  final encoded = json.encode(out);
  File('assets/data/exercises.json').writeAsStringSync(encoded);
  stdout.writeln('Escreveu ${out.length} exercícios em assets/data/exercises.json');
  stdout.writeln('Tamanho: ${(encoded.length / 1024 / 1024).toStringAsFixed(2)} MB');
}
