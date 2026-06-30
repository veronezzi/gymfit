/// Modelo de um exercício carregado do dataset.
class Exercise {
  final String id;
  final String name;
  final String category;
  final String equipment;
  final String target;
  final List<String> secondaryMuscles;
  final String imagePath;
  final String gifPath;

  /// Instruções por idioma (ex.: {'pt': '...', 'en': '...'}).
  final Map<String, String> instructionsByLang;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.target,
    required this.equipment,
    required this.secondaryMuscles,
    required this.imagePath,
    required this.gifPath,
    required this.instructionsByLang,
  });

  /// Base do repositório de origem onde estão as imagens e GIFs.
  static const String _mediaBase =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/';

  String get imageUrl => _mediaBase + imagePath;
  String get gifUrl => _mediaBase + gifPath;

  /// Instruções no idioma pedido, com fallback para pt e depois en.
  String instructions(String lang) =>
      instructionsByLang[lang] ??
      instructionsByLang['pt'] ??
      instructionsByLang['en'] ??
      '';

  /// Instruções quebradas em passos individuais para o idioma pedido.
  List<String> stepsFor(String lang) => instructions(lang)
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final rawInstructions = json['instructions'];
    final Map<String, String> instr;
    if (rawInstructions is Map) {
      instr = rawInstructions
          .map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
    } else {
      // Compatibilidade com formato antigo (string única em inglês).
      instr = {'en': (rawInstructions ?? '').toString()};
    }
    return Exercise(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      equipment: (json['equipment'] ?? '').toString(),
      target: (json['target'] ?? '').toString(),
      secondaryMuscles: ((json['secondary_muscles'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      imagePath: (json['image'] ?? '').toString(),
      gifPath: (json['gif_url'] ?? '').toString(),
      instructionsByLang: instr,
    );
  }
}
