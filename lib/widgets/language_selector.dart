import 'package:flutter/material.dart';
import '../state/app_lang.dart';

/// Botão que abre um menu para escolher o idioma das instruções.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, current, _) {
        final lang = languageOf(current);
        return PopupMenuButton<String>(
          tooltip: 'Idioma das instruções',
          onSelected: (code) => appLang.value = code,
          itemBuilder: (context) => [
            for (final l in kLanguages)
              PopupMenuItem<String>(
                value: l.code,
                child: Row(
                  children: [
                    Text(l.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(l.label),
                    if (l.code == current) ...[
                      const Spacer(),
                      Icon(Icons.check,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                    ],
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(lang.code.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }
}
