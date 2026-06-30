import 'package:flutter/material.dart';
import '../data/exercise_repository.dart';
import '../data/labels.dart';
import '../state/app_lang.dart';
import '../state/workout_store.dart';
import 'routine_screen.dart';
import 'workout_session_screen.dart';

/// Lista os treinos montados (A, B, C...) com opções de criar/editar.
class MyWorkoutScreen extends StatelessWidget {
  const MyWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Treinos')),
      body: ListenableBuilder(
        listenable: Listenable.merge([workoutStore, appLang]),
        builder: (context, _) {
          final routines = workoutStore.routines;
          if (routines.isEmpty) return _EmptyState(onCreate: () => _create(context));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: routines.length,
            itemBuilder: (context, i) =>
                _RoutineCard(routine: routines[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo treino'),
      ),
    );
  }

  void _create(BuildContext context) async {
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
    final routine = workoutStore.createRoutine(
        name.trim().isEmpty ? null : name.trim());
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RoutineScreen(routineId: routine.id)));
    }
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = appLang.value;

    // Resumo de grupos musculares do treino (até 3).
    final cats = <String>[];
    for (final item in routine.items) {
      final ex = exerciseRepo.byId(item.exerciseId);
      final c = ex == null ? null : categoryPt(ex.category);
      if (c != null && !cats.contains(c)) cats.add(c);
    }
    final preview = routine.items
        .take(3)
        .map((i) => exerciseRepo.byId(i.exerciseId))
        .where((e) => e != null)
        .map((e) => sentenceCase(e!.nameFor(lang)))
        .join(', ');

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RoutineScreen(routineId: routine.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(routine.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'rename') _rename(context);
                      if (v == 'delete') _delete(context);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Renomear')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              Text(
                '${routine.items.length} '
                'exercício${routine.items.length == 1 ? '' : 's'}'
                '${cats.isEmpty ? '' : '  •  ${cats.take(3).join(', ')}'}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: routine.items.isEmpty
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => WorkoutSessionScreen(
                                  plan: routine.items.toList(),
                                  routineName: routine.name,
                                ),
                              )),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Começar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                RoutineScreen(routineId: routine.id))),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rename(BuildContext context) async {
    final controller = TextEditingController(text: routine.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      workoutStore.renameRoutine(routine.id, name);
    }
  }

  void _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir "${routine.name}"?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) workoutStore.deleteRoutine(routine.id);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Nenhum treino ainda',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Crie treinos como A, B e C e adicione exercícios a cada um '
              'pela aba Exercícios.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeiro treino'),
            ),
          ],
        ),
      ),
    );
  }
}
