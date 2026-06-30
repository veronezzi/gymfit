/// Modelo de um exercício carregado do dataset.
class Exercise {
  final String id;
  final String category;
  final String equipment;
  final String target;
  final List<String> secondaryMuscles;
  final String imagePath;
  final String gifPath;

  /// Nome por idioma (ex.: {'pt': '...', 'en': '...'}).
  final Map<String, String> nameByLang;

  /// Instruções por idioma (ex.: {'pt': '...', 'en': '...'}).
  final Map<String, String> instructionsByLang;

  const Exercise({
    required this.id,
    required this.category,
    required this.target,
    required this.equipment,
    required this.secondaryMuscles,
    required this.imagePath,
    required this.gifPath,
    required this.nameByLang,
    required this.instructionsByLang,
  });

  /// Base do repositório de origem onde estão as imagens e GIFs.
  static const String _mediaBase =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/';

  String get imageUrl => _mediaBase + imagePath;
  String get gifUrl => _mediaBase + gifPath;

  /// Nome no idioma pedido, com fallback para pt e depois en.
  String nameFor(String lang) =>
      nameByLang[lang] ?? nameByLang['pt'] ?? nameByLang['en'] ?? '';

  /// Texto usado na busca (procura em todos os idiomas do nome).
  String get searchableName => nameByLang.values.join(' ').toLowerCase();

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

  static Map<String, String> _asLangMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
    }
    // Compatibilidade com formato antigo (string única em inglês).
    return {'en': (raw ?? '').toString()};
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id']?.toString() ?? '',
      nameByLang: _asLangMap(json['name']),
      instructionsByLang: _asLangMap(json['instructions']),
      category: (json['category'] ?? '').toString(),
      equipment: (json['equipment'] ?? '').toString(),
      target: (json['target'] ?? '').toString(),
      secondaryMuscles: ((json['secondary_muscles'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      imagePath: (json['image'] ?? '').toString(),
      gifPath: (json['gif_url'] ?? '').toString(),
    );
  }
}
