import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um exercício dentro do plano de treino, com séries, repetições e descanso.
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

/// Registro de um treino concluído (para o calendário/histórico).
class WorkoutLog {
  final DateTime date;
  final List<String> exerciseIds;
  final int durationSeconds;

  WorkoutLog({
    required this.date,
    required this.exerciseIds,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'exerciseIds': exerciseIds,
        'durationSeconds': durationSeconds,
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
        date: DateTime.parse(j['date'].toString()),
        exerciseIds: ((j['exerciseIds'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
        durationSeconds: (j['durationSeconds'] ?? 0) as int,
      );
}

/// Guarda o plano de treino e o histórico, persistindo localmente.
class WorkoutStore extends ChangeNotifier {
  static const _planKey = 'gymfit_plan';
  static const _historyKey = 'gymfit_history';

  final List<WorkoutItem> _plan = [];
  final List<WorkoutLog> _history = [];
  SharedPreferences? _prefs;

  List<WorkoutItem> get plan => List.unmodifiable(_plan);
  List<WorkoutLog> get history => List.unmodifiable(_history);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final planRaw = _prefs!.getString(_planKey);
    if (planRaw != null) {
      _plan
        ..clear()
        ..addAll((json.decode(planRaw) as List<dynamic>)
            .map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>)));
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
        _planKey, json.encode(_plan.map((e) => e.toJson()).toList()));
    _prefs?.setString(
        _historyKey, json.encode(_history.map((e) => e.toJson()).toList()));
  }

  bool isInPlan(String exerciseId) =>
      _plan.any((e) => e.exerciseId == exerciseId);

  void addExercise(String exerciseId) {
    if (isInPlan(exerciseId)) return;
    _plan.add(WorkoutItem(exerciseId: exerciseId));
    _save();
    notifyListeners();
  }

  void removeExercise(String exerciseId) {
    _plan.removeWhere((e) => e.exerciseId == exerciseId);
    _save();
    notifyListeners();
  }

  void removeAt(int index) {
    _plan.removeAt(index);
    _save();
    notifyListeners();
  }

  void updateItem(int index, {int? sets, int? reps, int? restSeconds}) {
    final item = _plan[index];
    if (sets != null) item.sets = sets.clamp(1, 20);
    if (reps != null) item.reps = reps.clamp(1, 100);
    if (restSeconds != null) item.restSeconds = restSeconds.clamp(5, 600);
    _save();
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _plan.removeAt(oldIndex);
    _plan.insert(newIndex, item);
    _save();
    notifyListeners();
  }

  void clearPlan() {
    _plan.clear();
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
