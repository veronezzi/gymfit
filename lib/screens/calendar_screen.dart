import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/exercise_repository.dart';
import '../data/labels.dart';
import '../state/app_lang.dart';
import '../state/workout_store.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: ListenableBuilder(
        listenable: Listenable.merge([workoutStore, appLang]),
        builder: (context, _) {
          final dayLogs = workoutStore.logsOn(_selectedDay);
          return ListView(
            children: [
              _StatsBar(),
              Card(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<WorkoutLog>(
                    locale: 'pt_BR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    eventLoader: (d) => workoutStore.logsOn(d),
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    onPageChanged: (focused) => _focusedDay = focused,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      isTodayHighlighted: true,
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  _titleForDay(_selectedDay),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (dayLogs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Text('Nenhum treino registrado neste dia.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              else
                ...dayLogs.map((log) => _LogCard(log: log)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  String _titleForDay(DateTime d) {
    final today = DateTime.now();
    if (isSameDay(d, today)) return 'Hoje';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = workoutStore.history
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          _StatCard(
              icon: Icons.local_fire_department,
              value: '${workoutStore.totalWorkoutDays}',
              label: 'dias treinados'),
          const SizedBox(width: 12),
          _StatCard(
              icon: Icons.calendar_month,
              value: '$thisMonth',
              label: 'neste mês'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer)),
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final WorkoutLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = appLang.value;
    final names = log.exerciseIds
        .map((id) => exerciseRepo.byId(id))
        .where((e) => e != null)
        .map((e) => sentenceCase(e!.nameFor(lang)))
        .toList();
    final time =
        '${log.date.hour.toString().padLeft(2, '0')}:${log.date.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.fitness_center,
              color: theme.colorScheme.onPrimary, size: 20),
        ),
        title: Text(
            '${log.routineName} • ${log.exerciseIds.length} exercícios',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$time • ${(log.durationSeconds / 60).ceil()} min'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: names
            .map((n) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline, size: 20),
                  title: Text(n),
                ))
            .toList(),
      ),
    );
  }
}
