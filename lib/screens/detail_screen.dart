import 'package:flutter/material.dart';
import '../data/labels.dart';
import '../models/exercise.dart';
import '../state/app_lang.dart';
import '../state/workout_store.dart';
import '../widgets/add_to_routine_sheet.dart';
import '../widgets/language_selector.dart';

/// Tela de detalhe com o GIF animado, músculos e passo a passo.
class DetailScreen extends StatelessWidget {
  final Exercise exercise;
  const DetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 56),
                child: Image.network(
                  exercise.gifUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 56, color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: appLang,
                    builder: (context, lang, _) => Text(
                      sentenceCase(exercise.nameFor(lang)),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: categoryPt(exercise.category),
                      ),
                      _InfoChip(
                        icon: Icons.fitness_center,
                        label: equipmentPt(exercise.equipment),
                      ),
                      _InfoChip(
                        icon: Icons.my_location,
                        label: targetPt(exercise.target),
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: workoutStore,
                    builder: (context, _) {
                      final inRoutines =
                          workoutStore.routinesContaining(exercise.id);
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              showAddToRoutineSheet(context, exercise.id),
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48)),
                          icon: Icon(inRoutines.isEmpty
                              ? Icons.add
                              : Icons.playlist_add_check),
                          label: Text(inRoutines.isEmpty
                              ? 'Adicionar ao treino'
                              : 'Em ${inRoutines.length} treino'
                                  '${inRoutines.length == 1 ? '' : 's'} • gerenciar'),
                        ),
                      );
                    },
                  ),
                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionTitle('Músculos secundários'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.secondaryMuscles
                          .map((m) => Chip(
                                label: Text(targetPt(m)),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Como executar')),
                      const LanguageSelector(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: appLang,
                    builder: (context, lang, _) {
                      final steps = exercise.stepsFor(lang);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (steps.isEmpty)
                            Text('Sem instruções disponíveis.',
                                style: theme.textTheme.bodyMedium)
                          else
                            ...List.generate(
                                steps.length, (i) => _Step(i + 1, steps[i])),
                          const SizedBox(height: 24),
                          Text(
                            lang == 'pt'
                                ? 'Tradução automática do inglês.'
                                : 'Instructions in the original language.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  const _InfoChip(
      {required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlight
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = highlight
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}
