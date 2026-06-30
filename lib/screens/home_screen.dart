import 'package:flutter/material.dart';
import '../data/exercise_repository.dart';
import '../data/labels.dart';
import '../models/exercise.dart';
import '../state/app_lang.dart';
import '../widgets/exercise_card.dart';
import '../widgets/language_selector.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ExerciseRepository();
  late Future<void> _loadFuture;

  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadFuture = _repo.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erro ao carregar exercícios:\n${snapshot.error}',
                  textAlign: TextAlign.center),
            ));
          }

          final results =
              _repo.filter(query: _query, category: _selectedCategory);

          return ValueListenableBuilder<String>(
            valueListenable: appLang,
            builder: (context, lang, _) => CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 132,
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Center(child: LanguageSelector()),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 20, bottom: 70, top: 0),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center,
                          color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('GymFit',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SearchBar(
                      hintText: 'Buscar exercício, músculo, equipamento…',
                      leading: const Icon(Icons.search),
                      elevation: const WidgetStatePropertyAll(0),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _categoryFilter(theme)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    '${results.length} exercício${results.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ),
              if (results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisExtent: 250,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ExerciseCard(
                        exercise: results[i],
                        lang: lang,
                        onTap: () => _openDetail(results[i]),
                      ),
                      childCount: results.length,
                    ),
                  ),
                ),
            ],
          ),
          );
        },
      ),
    );
  }

  Widget _categoryFilter(ThemeData theme) {
    final cats = _repo.categories;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todos'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
          ),
          ...cats.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(categoryPt(c)),
                  selected: _selectedCategory == c,
                  onSelected: (sel) =>
                      setState(() => _selectedCategory = sel ? c : null),
                ),
              )),
        ],
      ),
    );
  }

  void _openDetail(Exercise e) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(exercise: e)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text('Nenhum exercício encontrado',
              style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
