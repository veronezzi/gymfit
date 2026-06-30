import 'package:flutter/material.dart';
import '../state/workout_store.dart';

/// Abre um seletor para incluir/remover o exercício em treinos (A, B, C...).
Future<void> showAddToRoutineSheet(BuildContext context, String exerciseId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _AddToRoutineSheet(exerciseId: exerciseId),
  );
}

class _AddToRoutineSheet extends StatelessWidget {
  final String exerciseId;
  const _AddToRoutineSheet({required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: workoutStore,
      builder: (context, _) {
        final routines = workoutStore.routines;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Adicionar a um treino',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (routines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Você ainda não tem treinos. Crie um (ex.: Treino A) '
                      'para começar a montar sua rotina.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final r in routines)
                          CheckboxListTile(
                            value: workoutStore.routineHas(r.id, exerciseId),
                            title: Text(r.name),
                            subtitle: Text('${r.items.length} '
                                'exercício${r.items.length == 1 ? '' : 's'}'),
                            onChanged: (checked) {
                              if (checked == true) {
                                workoutStore.addExercise(r.id, exerciseId);
                              } else {
                                workoutStore.removeExercise(r.id, exerciseId);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.add,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: const Text('Criar novo treino'),
                  onTap: () => _createAndAdd(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createAndAdd(BuildContext context) async {
    final controller =
        TextEditingController(text: workoutStore.suggestRoutineName());
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Nome', hintText: 'Ex.: Treino A, Peito e Tríceps'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Criar')),
        ],
      ),
    );
    if (name == null) return;
    final routine = workoutStore
        .createRoutine(name.trim().isEmpty ? null : name.trim());
    workoutStore.addExercise(routine.id, exerciseId);
  }
}
