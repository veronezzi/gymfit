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
  final String instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.target,
    required this.secondaryMuscles,
    required this.imagePath,
    required this.gifPath,
    required this.instructions,
  });

  /// Base do repositório de origem onde estão as imagens e GIFs.
  static const String _mediaBase =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/';

  String get imageUrl => _mediaBase + imagePath;
  String get gifUrl => _mediaBase + gifPath;

  /// Instruções quebradas em passos individuais.
  List<String> get steps => instructions
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory Exercise.fromJson(Map<String, dynamic> json) {
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
      instructions: (json['instructions'] ?? '').toString(),
    );
  }
}
