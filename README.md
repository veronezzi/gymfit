# GymFit 🏋️

App em Flutter para consultar um catálogo de **1.324 exercícios** com animações,
grupos musculares e passo a passo. Funciona na web (e também roda em Android).

## 🌐 Acesso online

**https://veronezzi.github.io/gymfit/**

## ✨ Funcionalidades

- Busca por nome, músculo ou equipamento
- Filtro por grupo muscular (peito, costas, pernas, ombros, etc.)
- Tela de detalhe com GIF animado do movimento
- Músculo principal e secundários
- Passo a passo de execução
- Seletor de idioma das instruções: 🇧🇷 Português (padrão) / 🇺🇸 English
- Múltiplos treinos nomeados (Treino A, B, C…) com séries, repetições e descanso
- Sessão guiada "Começar treino" com timer de descanso entre séries
- Calendário com histórico dos treinos realizados

## 🗂️ Dados

Os dados vêm do dataset público
[hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset).
Um recorte enxuto (`assets/data/exercises.json`) é empacotado no app; as imagens e
GIFs são carregados sob demanda do repositório de origem. Como o dataset original
não traz português, as instruções em PT são geradas por tradução automática
(EN → PT) no momento de build, com cache em `tool/pt_cache.json`.

Para regenerar o asset (e traduções) a partir do dataset bruto:

```bash
curl -sL https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json -o tool/exercises_raw.json
dart run tool/build_data.dart
```

## 🚀 Rodando localmente

```bash
flutter pub get
flutter run -d chrome        # web
# ou
flutter run                  # dispositivo/emulador Android
```

## 🛠️ Build web

```bash
flutter build web --release --base-href /gymfit/
```

O conteúdo de `build/web` é publicado no GitHub Pages (branch `gh-pages`).
