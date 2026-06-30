import 'dart:async';
import 'package:flutter/material.dart';

/// Abre um timer de descanso em modal. Resolve quando termina ou é pulado.
Future<void> showRestTimer(BuildContext context, int seconds) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _RestTimerSheet(seconds: seconds),
  );
}

class _RestTimerSheet extends StatefulWidget {
  final int seconds;
  const _RestTimerSheet({required this.seconds});

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  late int _total;
  late int _remaining;
  Timer? _timer;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _total = widget.seconds;
    _remaining = widget.seconds;
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_running) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  void _addTime(int s) => setState(() {
        _remaining += s;
        _total = _remaining > _total ? _remaining : _total;
      });

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    final m = (_remaining ~/ 60).toString();
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return _remaining >= 60 ? '$m:$s' : '$_remaining';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _total == 0 ? 0.0 : _remaining / _total;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Descanso',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_label,
                          style: theme.textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('segundos',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addTime(15),
                  icon: const Icon(Icons.add),
                  label: const Text('15s'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _running = !_running),
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pausar' : 'Retomar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Pular descanso'),
            ),
          ],
        ),
      ),
    );
  }
}
