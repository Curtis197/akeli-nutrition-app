import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/food_region_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'domain/entities/recipe_tracking.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _logger = appLogger;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _regionId;
  String? _difficulty;
  int? _maxTimeMin;
  String? _orderBy;

  bool get _hasActiveFilter =>
      _regionId != null || _difficulty != null || _maxTimeMin != null || _orderBy != null;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _logger.provider('FeedPage initState()');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _logger.provider('FeedPage disposed');
    super.dispose();
  }

  String _regionLabel() {
    if (_regionId == null) return 'Région ▾';
    final names = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
    return names[_regionId!] ?? _regionId!;
  }

  String _difficultyLabel() => switch (_difficulty) {
        'easy' => 'Facile',
        'medium' => 'Moyen',
        'hard' => 'Difficile',
        _ => 'Difficulté ▾',
      };

  String _timeLabel() => switch (_maxTimeMin) {
        30 => '< 30 min',
        60 => '< 60 min',
        90 => '< 90 min',
        _ => 'Temps ▾',
      };

  String _sortLabel() => switch (_orderBy) {
        'rating' => 'Mieux noté',
        'likes' => 'Populaire',
        'created_at' => 'Plus récent',
        _ => 'Trier ▾',
      };

  void _showRegionSheet(BuildContext context) {
    _logger.userAction('Region filter sheet opened', screen: 'FeedPage');
    final regionNames = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
    final options = [
      const MapEntry<String?, String>(null, 'Toutes les régions'),
      ...regionNames.entries.map((e) => MapEntry<String?, String>(e.key, e.value)),
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet<String>(
        title: 'Région',
        options: options,
        selectedKey: _regionId,
        onSelect: (key) {
          _logger.userAction('Region filter selected', screen: 'FeedPage',
              metadata: {'regionId': key});
          setState(() => _regionId = key);
        },
      ),
    );
  }

  void _showDifficultySheet(BuildContext context) {
    _logger.userAction('Difficulty filter sheet opened', screen: 'FeedPage');
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet<String>(
        title: 'Difficulté',
        options: const [
          MapEntry(null, 'Tous'),
          MapEntry('easy', 'Facile'),
          MapEntry('medium', 'Moyen'),
          MapEntry('hard', 'Difficile'),
        ],
        selectedKey: _difficulty,
        onSelect: (key) {
          _logger.userAction('Difficulty filter selected', screen: 'FeedPage',
              metadata: {'difficulty': key});
          setState(() => _difficulty = key);
        },
      ),
    );
  }

  void _showTimeSheet(BuildContext context) {
    _logger.userAction('Time filter sheet opened', screen: 'FeedPage');
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet<int>(
        title: 'Temps de préparation',
        options: const [
          MapEntry(null, 'Tous'),
          MapEntry(30, 'Moins de 30 min'),
          MapEntry(60, 'Moins de 60 min'),
          MapEntry(90, 'Moins de 90 min'),
        ],
        selectedKey: _maxTimeMin,
        onSelect: (key) {
          _logger.userAction('Time filter selected', screen: 'FeedPage',
              metadata: {'maxTimeMin': key});
          setState(() => _maxTimeMin = key);
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    _logger.userAction('Sort sheet opened', screen: 'FeedPage');
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet<String>(
        title: 'Trier par',
        options: const [
          MapEntry(null, 'Pertinence'),
          MapEntry('rating', 'Mieux noté'),
          MapEntry('likes', 'Plus populaire'),
          MapEntry('created_at', 'Plus récent'),
        ],
        selectedKey: _orderBy,
        onSelect: (key) {
          _logger.userAction('Sort selected', screen: 'FeedPage',
              metadata: {'orderBy': key});
          setState(() => _orderBy = key);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.length >= 2;
    final feedAsync = isSearching
        ? ref.watch(searchRecipesProvider(SearchParams(
            query: _searchQuery,
            regionId: _regionId,
            difficulty: _difficulty,
            maxTimeMin: _maxTimeMin,
            orderBy: _orderBy ?? 'relevance',
            limit: _pageSize,
          )))
        : ref.watch(feedProvider(FeedParams(
            limit: _pageSize,
            regionId: _regionId,
            difficulty: _difficulty,
            maxTimeMin: _maxTimeMin,
            orderBy: _orderBy,
          )));

    final profileAsync = ref.watch(userProfileProvider);
    final regionNames = ref.watch(foodRegionNamesProvider).valueOrNull ?? {};

    _logger.provider('FeedPage build() | isSearching: $isSearching | feedAsync.isLoading: ${feedAsync.isLoading}');

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AkeliColors.background,
          title: Row(
            children: [
              profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 18,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  backgroundColor: AkeliColors.primary,
                  child: profile?.avatarUrl == null
                      ? Text(
                          (profile?.displayName.isNotEmpty == true
                                  ? profile!.displayName[0]
                                  : 'A')
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                loading: () => const CircleAvatar(
                    radius: 18, backgroundColor: AkeliColors.primary),
                error: (_, __) => const CircleAvatar(
                    radius: 18, backgroundColor: AkeliColors.primary),
              ),
              const SizedBox(width: AkeliSpacing.sm),
              Expanded(
                child: Text(
                  profileAsync.when(
                    data: (p) => p?.displayName != null
                        ? 'Bonjour, ${p!.displayName} 👋'
                        : 'Bienvenue sur Akeli',
                    loading: () => 'Bienvenue sur Akeli',
                    error: (_, __) => 'Bienvenue sur Akeli',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () {
                _logger.userAction('AI Chat button tapped', screen: 'FeedPage');
                context.push(AkeliRoutes.aiChat);
              },
              tooltip: 'Assistant IA',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AkeliSpacing.md, 0, AkeliSpacing.md, AkeliSpacing.xs),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      searchBarTheme: const SearchBarThemeData(
                        backgroundColor:
                            WidgetStatePropertyAll(AkeliColors.surfaceContainerLow),
                      ),
                    ),
                    child: SearchBar(
                      controller: _searchCtrl,
                      hintText: 'Rechercher une recette...',
                      leading: const Icon(Icons.search_rounded),
                      trailing: _searchQuery.isNotEmpty
                          ? [
                              IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _logger.userAction('Search cleared', screen: 'FeedPage');
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            ]
                          : null,
                      onChanged: (v) {
                        _logger.userAction('Search query changed',
                            screen: 'FeedPage',
                            metadata: {'length': v.length, 'triggerSearch': v.length >= 2});
                        setState(() => _searchQuery = v);
                      },
                      elevation: const WidgetStatePropertyAll(1),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
                    children: [
                      _FeedFilterChip(
                        label: _regionLabel(),
                        active: _regionId != null,
                        onTap: () => _showRegionSheet(context),
                      ),
                      const SizedBox(width: AkeliSpacing.xs),
                      _FeedFilterChip(
                        label: _difficultyLabel(),
                        active: _difficulty != null,
                        onTap: () => _showDifficultySheet(context),
                      ),
                      const SizedBox(width: AkeliSpacing.xs),
                      _FeedFilterChip(
                        label: _timeLabel(),
                        active: _maxTimeMin != null,
                        onTap: () => _showTimeSheet(context),
                      ),
                      const SizedBox(width: AkeliSpacing.xs),
                      _FeedFilterChip(
                        label: _sortLabel(),
                        active: _orderBy != null,
                        onTap: () => _showSortSheet(context),
                      ),
                      if (_hasActiveFilter) ...[
                        const SizedBox(width: AkeliSpacing.xs),
                        _FeedFilterChip(
                          label: '× Effacer',
                          active: false,
                          onTap: () {
                            _logger.userAction('Feed filters cleared', screen: 'FeedPage');
                            setState(() {
                              _regionId = null;
                              _difficulty = null;
                              _maxTimeMin = null;
                              _orderBy = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AkeliSpacing.xs),
              ],
            ),
          ),
        ),

        // Content
        feedAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SliverFillRemaining(
            child: ErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(feedProvider),
            ),
          ),
          data: (recipes) {
            if (recipes.isEmpty) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.restaurant_menu_rounded,
                  title: isSearching
                      ? 'Aucune recette trouvée'
                      : 'Pas encore de recettes',
                  subtitle: isSearching
                      ? 'Essayez d\'autres termes de recherche.'
                      : 'Explorez et découvrez des recettes africaines.',
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              sliver: SliverGrid.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AkeliSpacing.md,
                  mainAxisSpacing: AkeliSpacing.md,
                  childAspectRatio: 0.68,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return AkeliRecipeCard(
                    hasImage: true,
                    title: recipe.title,
                    calories: recipe.calories?.toInt() ?? 0,
                    rating: recipe.averageRating,
                    likes: recipe.likeCount,
                    comments: 0,
                    saves: 0,
                    emoji: null,
                    region: recipe.regionId != null
                        ? regionNames[recipe.regionId!] ?? recipe.regionId
                        : null,
                    tags: recipe.tagIds.take(2).toList(),
                    onTap: () {
                      _logger.userAction('Recipe card tapped', screen: 'FeedPage', metadata: {'recipeId': recipe.id});
                      context.push(
                        AkeliRoutes.recipeDetailPath(recipe.id),
                        extra: TrackingSource.feed,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _FeedFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FeedFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.sm, vertical: AkeliSpacing.xs),
        decoration: BoxDecoration(
          color: active ? AkeliColors.primary : AkeliColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AkeliColors.primary : AkeliColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AkeliColors.onPrimary : AkeliColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FilterSheet<T> extends StatelessWidget {
  final String title;
  final List<MapEntry<T?, String>> options;
  final T? selectedKey;
  final void Function(T? key) onSelect;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AkeliSpacing.lg, AkeliSpacing.md, AkeliSpacing.lg, AkeliSpacing.xs),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...options.map((entry) => ListTile(
                title: Text(entry.value),
                trailing: entry.key == selectedKey
                    ? const Icon(Icons.check_rounded, color: AkeliColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(entry.key);
                },
              )),
          const SizedBox(height: AkeliSpacing.sm),
        ],
      ),
    );
  }
}
