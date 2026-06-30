/// Modelo de um exercício carregado do dataset.
class Exercise {
  final String id;
  final String category;
  final String equipment;
  final String target;
  final List<String> secondaryMuscles;

  /// Identificador da mídia no CDN do ExerciseDB (ex.: '2gPfomN').
  final String mediaId;

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
    required this.mediaId,
    required this.nameByLang,
    required this.instructionsByLang,
  });

  // O GIF fica no CDN oficial do ExerciseDB, que não envia cabeçalhos CORS.
  // Por isso passamos pelo proxy de imagens weserv.nl, que adiciona CORS
  // (necessário para o Flutter Web/CanvasKit carregar a imagem).
  String get _cdnGif => 'static.exercisedb.dev/media/$mediaId.gif';
  String _proxied(String extra) =>
      'https://images.weserv.nl/?url=${Uri.encodeQueryComponent(_cdnGif)}&$extra';

  /// Miniatura estática (primeiro quadro do GIF) para os cards.
  String get imageUrl => mediaId.isEmpty ? '' : _proxied('w=400&output=jpg');

  /// GIF animado para a tela de detalhe.
  String get gifUrl => mediaId.isEmpty ? '' : _proxied('n=-1&output=gif');

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
      mediaId: (json['media_id'] ?? '').toString(),
    );
  }
}
