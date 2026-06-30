import 'package:flutter/material.dart';
import '../data/exercise_repository.dart';
import '../data/labels.dart';
import '../state/app_lang.dart';
import '../state/workout_store.dart';
import 'workout_session_screen.dart';

class MyWorkoutScreen extends StatelessWidget {
  const MyWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Treino'),
        actions: [
          ListenableBuilder(
            listenable: workoutStore,
            builder: (context, _) => workoutStore.plan.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Limpar treino',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmClear(context),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([workoutStore, appLang]),
        builder: (context, _) {
          final plan = workoutStore.plan;
          if (plan.isEmpty) return const _EmptyWorkout();
          final lang = appLang.value;
          return Column(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  itemCount: plan.length,
                  onReorder: workoutStore.reorder,
                  itemBuilder: (context, i) {
                    final item = plan[i];
                    final ex = exerciseRepo.byId(item.exerciseId);
                    return Card(
                      key: ValueKey(item.exerciseId),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHigh,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 6, 8, 6),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: Colors.white,
                            child: ex == null
                                ? const Icon(Icons.fitness_center)
                                : Image.network(ex.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.fitness_center)),
                          ),
                        ),
                        title: Text(
                          ex == null
                              ? item.exerciseId
                              : sentenceCase(ex.nameFor(lang)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${item.sets} séries × ${item.reps} reps  •  '
                            '${item.restSeconds}s descanso',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.tune),
                              tooltip: 'Ajustar',
                              onPressed: () => _editItem(context, i),
                            ),
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ListenableBuilder(
        listenable: workoutStore,
        builder: (context, _) {
          if (workoutStore.plan.isEmpty) return const SizedBox.shrink();
          return FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(260, 54),
              textStyle: theme.textTheme.titleMedium,
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Começar treino'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    WorkoutSessionScreen(plan: workoutStore.plan.toList()),
              ));
            },
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar treino?'),
        content: const Text('Remove todos os exercícios do seu plano.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Limpar')),
        ],
      ),
    );
    if (ok == true) workoutStore.clearPlan();
  }

  void _editItem(BuildContext context, int index) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditItemSheet(index: index),
    );
  }
}

class _EditItemSheet extends StatelessWidget {
  final int index;
  const _EditItemSheet({required this.index});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: workoutStore,
      builder: (context, _) {
        if (index >= workoutStore.plan.length) return const SizedBox.shrink();
        final item = workoutStore.plan[index];
        final ex = exerciseRepo.byId(item.exerciseId);
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ex == null ? 'Ajustar' : sentenceCase(ex.nameFor(appLang.value)),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _Stepper(
                label: 'Séries',
                value: item.sets,
                onChanged: (v) => workoutStore.updateItem(index, sets: v),
                min: 1,
                max: 20,
              ),
              _Stepper(
                label: 'Repetições',
                value: item.reps,
                onChanged: (v) => workoutStore.updateItem(index, reps: v),
                min: 1,
                max: 100,
              ),
              _Stepper(
                label: 'Descanso (s)',
                value: item.restSeconds,
                step: 15,
                onChanged: (v) =>
                    workoutStore.updateItem(index, restSeconds: v),
                min: 5,
                max: 600,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  workoutStore.removeAt(index);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover do treino'),
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton.filledTonal(
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 56,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton.filledTonal(
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkout extends StatelessWidget {
  const _EmptyWorkout();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_task,
                size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Seu treino está vazio',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Vá até a aba Exercícios, abra um exercício e toque em '
              '"Adicionar ao treino" para montar sua rotina.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
