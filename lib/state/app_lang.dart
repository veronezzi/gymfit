import 'package:flutter/foundation.dart';

/// Idiomas disponíveis para as instruções dos exercícios.
class AppLanguage {
  final String code; // ex.: 'pt'
  final String label; // ex.: 'Português'
  final String flag; // emoji da bandeira
  const AppLanguage(this.code, this.label, this.flag);
}

const List<AppLanguage> kLanguages = [
  AppLanguage('pt', 'Português', '🇧🇷'),
  AppLanguage('en', 'English', '🇺🇸'),
];

/// Idioma selecionado para as instruções. Padrão: português.
final ValueNotifier<String> appLang = ValueNotifier<String>('pt');

AppLanguage languageOf(String code) =>
    kLanguages.firstWhere((l) => l.code == code, orElse: () => kLanguages.first);
