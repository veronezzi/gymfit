import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';

/// Carrega e fornece acesso aos exercícios do asset empacotado.
class ExerciseRepository {
  List<Exercise> _all = const [];
  bool _loaded = false;

  List<Exercise> get all => _all;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final List<dynamic> data = json.decode(raw) as List<dynamic>;
    _all = data
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  /// Lista ordenada de categorias (grupos musculares) presentes.
  List<String> get categories {
    final set = _all.map((e) => e.category).toSet().toList();
    set.sort();
    return set;
  }

  /// Filtra por texto de busca e categoria selecionada.
  List<Exercise> filter({String query = '', String? category}) {
    final q = query.trim().toLowerCase();
    return _all.where((e) {
      final matchesCategory = category == null || e.category == category;
      if (!matchesCategory) return false;
      if (q.isEmpty) return true;
      return e.searchableName.contains(q) ||
          e.target.toLowerCase().contains(q) ||
          e.equipment.toLowerCase().contains(q);
    }).toList();
  }
}
