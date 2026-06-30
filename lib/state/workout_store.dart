import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um exercício dentro de um treino, com séries, repetições e descanso.
class WorkoutItem {
  final String exerciseId;
  int sets;
  int reps;
  int restSeconds;

  WorkoutItem({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 12,
    this.restSeconds = 60,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
      };

  factory WorkoutItem.fromJson(Map<String, dynamic> j) => WorkoutItem(
        exerciseId: j['exerciseId'].toString(),
        sets: (j['sets'] ?? 3) as int,
        reps: (j['reps'] ?? 12) as int,
        restSeconds: (j['restSeconds'] ?? 60) as int,
      );
}

/// Um treino nomeado (ex.: "Treino A"), com sua lista de exercícios.
class Routine {
  final String id;
  String name;
  final List<WorkoutItem> items;

  Routine({required this.id, required this.name, List<WorkoutItem>? items})
      : items = items ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
        id: j['id'].toString(),
        name: (j['name'] ?? 'Treino').toString(),
        items: ((j['items'] as List<dynamic>?) ?? [])
            .map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Registro de um treino concluído (para o calendário/histórico).
class WorkoutLog {
  final DateTime date;
  final String routineName;
  final List<String> exerciseIds;
  final int durationSeconds;

  WorkoutLog({
    required this.date,
    required this.routineName,
    required this.exerciseIds,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'routineName': routineName,
        'exerciseIds': exerciseIds,
        'durationSeconds': durationSeconds,
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
        date: DateTime.parse(j['date'].toString()),
        routineName: (j['routineName'] ?? 'Treino').toString(),
        exerciseIds: ((j['exerciseIds'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
        durationSeconds: (j['durationSeconds'] ?? 0) as int,
      );
}

/// Guarda os treinos (A, B, C...) e o histórico, persistindo localmente.
class WorkoutStore extends ChangeNotifier {
  static const _routinesKey = 'gymfit_routines';
  static const _historyKey = 'gymfit_history';
  static const _legacyPlanKey = 'gymfit_plan'; // formato antigo (treino único)

  final List<Routine> _routines = [];
  final List<WorkoutLog> _history = [];
  SharedPreferences? _prefs;
  int _idSeq = 0;

  List<Routine> get routines => List.unmodifiable(_routines);
  List<WorkoutLog> get history => List.unmodifiable(_history);

  String _newId() => '${DateTime.now().millisecondsSinceEpoch}_${_idSeq++}';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final routinesRaw = _prefs!.getString(_routinesKey);
    if (routinesRaw != null) {
      _routines
        ..clear()
        ..addAll((json.decode(routinesRaw) as List<dynamic>)
            .map((e) => Routine.fromJson(e as Map<String, dynamic>)));
    } else {
      // Migração: se havia um treino único no formato antigo, vira "Treino A".
      final legacy = _prefs!.getString(_legacyPlanKey);
      if (legacy != null) {
        final items = (json.decode(legacy) as List<dynamic>)
            .map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (items.isNotEmpty) {
          _routines.add(
              Routine(id: _newId(), name: 'Treino A', items: items));
        }
        _prefs!.remove(_legacyPlanKey);
      }
    }

    final histRaw = _prefs!.getString(_historyKey);
    if (histRaw != null) {
      _history
        ..clear()
        ..addAll((json.decode(histRaw) as List<dynamic>)
            .map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>)));
    }
    notifyListeners();
  }

  void _save() {
    _prefs?.setString(
        _routinesKey, json.encode(_routines.map((e) => e.toJson()).toList()));
    _prefs?.setString(
        _historyKey, json.encode(_history.map((e) => e.toJson()).toList()));
  }

  Routine? routineById(String id) {
    for (final r in _routines) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Sugere o próximo nome no padrão "Treino A", "Treino B"...
  String suggestRoutineName() {
    final n = _routines.length;
    if (n < 26) return 'Treino ${String.fromCharCode(65 + n)}';
    return 'Treino ${n + 1}';
  }

  Routine createRoutine([String? name]) {
    final r = Routine(id: _newId(), name: name ?? suggestRoutineName());
    _routines.add(r);
    _save();
    notifyListeners();
    return r;
  }

  void renameRoutine(String routineId, String name) {
    final r = routineById(routineId);
    if (r == null) return;
    r.name = name.trim().isEmpty ? r.name : name.trim();
    _save();
    notifyListeners();
  }

  void deleteRoutine(String routineId) {
    _routines.removeWhere((r) => r.id == routineId);
    _save();
    notifyListeners();
  }

  /// Treinos que contêm o exercício.
  List<Routine> routinesContaining(String exerciseId) => _routines
      .where((r) => r.items.any((i) => i.exerciseId == exerciseId))
      .toList();

  bool routineHas(String routineId, String exerciseId) =>
      routineById(routineId)?.items.any((i) => i.exerciseId == exerciseId) ??
      false;

  void addExercise(String routineId, String exerciseId) {
    final r = routineById(routineId);
    if (r == null || routineHas(routineId, exerciseId)) return;
    r.items.add(WorkoutItem(exerciseId: exerciseId));
    _save();
    notifyListeners();
  }

  void removeExercise(String routineId, String exerciseId) {
    routineById(routineId)
        ?.items
        .removeWhere((i) => i.exerciseId == exerciseId);
    _save();
    notifyListeners();
  }

  void removeAt(String routineId, int index) {
    routineById(routineId)?.items.removeAt(index);
    _save();
    notifyListeners();
  }

  void updateItem(String routineId, int index,
      {int? sets, int? reps, int? restSeconds}) {
    final r = routineById(routineId);
    if (r == null || index >= r.items.length) return;
    final item = r.items[index];
    if (sets != null) item.sets = sets.clamp(1, 20);
    if (reps != null) item.reps = reps.clamp(1, 100);
    if (restSeconds != null) item.restSeconds = restSeconds.clamp(5, 600);
    _save();
    notifyListeners();
  }

  void reorder(String routineId, int oldIndex, int newIndex) {
    final r = routineById(routineId);
    if (r == null) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = r.items.removeAt(oldIndex);
    r.items.insert(newIndex, item);
    _save();
    notifyListeners();
  }

  void logWorkout(WorkoutLog log) {
    _history.add(log);
    _save();
    notifyListeners();
  }

  /// Logs de um dia específico (ignora a hora).
  List<WorkoutLog> logsOn(DateTime day) => _history
      .where((l) =>
          l.date.year == day.year &&
          l.date.month == day.month &&
          l.date.day == day.day)
      .toList();

  /// Total de dias distintos com treino registrado.
  int get totalWorkoutDays => _history
      .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
      .toSet()
      .length;
}

/// Instância global, carregada uma vez em main().
final workoutStore = WorkoutStore();
