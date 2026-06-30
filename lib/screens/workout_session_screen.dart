import 'package:flutter/material.dart';
import '../data/exercise_repository.dart';
import '../data/labels.dart';
import '../models/exercise.dart';
import '../state/app_lang.dart';
import '../state/workout_store.dart';
import '../widgets/rest_timer.dart';

/// Sessão de treino guiada: percorre os exercícios na ordem do plano,
/// contando séries e abrindo o timer de descanso entre elas.
class WorkoutSessionScreen extends StatefulWidget {
  final List<WorkoutItem> plan;
  const WorkoutSessionScreen({super.key, required this.plan});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int _exerciseIndex = 0;
  int _currentSet = 1; // 1-based
  int _completedSets = 0;
  final DateTime _startedAt = DateTime.now();

  WorkoutItem get _item => widget.plan[_exerciseIndex];
  Exercise? get _exercise => exerciseRepo.byId(_item.exerciseId);

  int get _totalSets =>
      widget.plan.fold(0, (sum, e) => sum + e.sets);

  Future<void> _completeSet() async {
    _completedSets++;
    final isLastSetOfExercise = _currentSet >= _item.sets;
    final isLastExercise = _exerciseIndex >= widget.plan.length - 1;

    if (isLastSetOfExercise && isLastExercise) {
      _finish();
      return;
    }

    // Descanso entre séries/exercícios.
    await showRestTimer(context, _item.restSeconds);
    if (!mounted) return;

    setState(() {
      if (isLastSetOfExercise) {
        _exerciseIndex++;
        _currentSet = 1;
      } else {
        _currentSet++;
      }
    });
  }

  void _skipExercise() {
    final isLastExercise = _exerciseIndex >= widget.plan.length - 1;
    if (isLastExercise) {
      _finish();
      return;
    }
    setState(() {
      _exerciseIndex++;
      _currentSet = 1;
    });
  }

  void _finish() {
    final elapsed = DateTime.now().difference(_startedAt).inSeconds;
    workoutStore.logWorkout(WorkoutLog(
      date: DateTime.now(),
      exerciseIds: widget.plan.map((e) => e.exerciseId).toList(),
      durationSeconds: elapsed,
    ));
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emoji_events, size: 40, color: Color(0xFFFFC107)),
        title: const Text('Treino concluído! 🎉'),
        content: Text(
            'Você completou $_completedSets séries em '
            '${(elapsed / 60).ceil()} min.\nMandou bem!'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // fecha diálogo
              Navigator.of(context).pop(); // fecha sessão
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmQuit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar treino?'),
        content: const Text('Seu progresso desta sessão não será salvo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continuar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Encerrar')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = _exercise;
    final progress = _totalSets == 0 ? 0.0 : _completedSets / _totalSets;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final quit = await _confirmQuit();
        if (quit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Exercício ${_exerciseIndex + 1} de ${widget.plan.length}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: progress),
          ),
        ),
        body: exercise == null
            ? const Center(child: Text('Exercício indisponível'))
            : ValueListenableBuilder<String>(
                valueListenable: appLang,
                builder: (context, lang, _) => Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Image.network(
                          exercise.gifUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (c, child, p) => p == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator()),
                          errorBuilder: (c, e, s) => const Center(
                              child: Icon(Icons.fitness_center, size: 56)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            sentenceCase(exercise.nameFor(lang)),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${targetPt(exercise.target)} • '
                            '${equipmentPt(exercise.equipment)}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Stat(
                                  label: 'Série',
                                  value: '$_currentSet/${_item.sets}'),
                              _Stat(label: 'Reps', value: '${_item.reps}'),
                              _Stat(
                                  label: 'Descanso',
                                  value: '${_item.restSeconds}s'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _completeSet,
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54)),
                            icon: const Icon(Icons.check),
                            label: Text(
                              _currentSet >= _item.sets &&
                                      _exerciseIndex >= widget.plan.length - 1
                                  ? 'Concluir treino'
                                  : 'Concluir série',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _skipExercise,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Pular exercício'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
