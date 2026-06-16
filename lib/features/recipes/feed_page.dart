import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/creator_provider.dart';
import '../../providers/food_region_provider.dart';
import '../../providers/recipe_provider.dart';

import '../../providers/meal_plan_provider.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import '../../shared/widgets/creator_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tab_bar.dart';
import 'domain/entities/recipe_tracking.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
import '../../shared/models/creator.dart';
import '../../shared/models/recipe.dart';

List<Creator> filterAndSortCreators(
  List<Creator> all, {
  String query = '',
  String? regionId,
  String? specialty,
  String? orderBy,
}) {
  var list = all.where((c) {
    if (query.isNotEmpty &&
        !c.displayName.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    if (regionId != null && c.regionId != regionId) { return false; }
    if (specialty != null && !c.specialties.contains(specialty)) { return false; }
    return true;
  }).toList();

  if (orderBy == 'rating') {
    list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
  } else if (orderBy == 'fans') {
    list.sort((a, b) => b.fanCount.compareTo(a.fanCount));
  } else if (orderBy == 'recipes') {
    list.sort((a, b) => b.recipeCount.compareTo(a.recipeCount));
  }

  return list;
}

class FeedPage extends ConsumerStatefulWidget {
  final String? swapEntryId;

  const FeedPage({super.key, this.swapEntryId});

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
  int? _minCal;
  int? _maxCal;
  String? _orderBy;
  String? _mealType;

  int _tabIndex = 0;

  // ---- Recipe feed pagination (personalized) ----
  final List<Recipe> _recipes = [];
  bool _hasMoreRecipes = true;
  bool _loadingMoreRecipes = false;
  final Set<String> _seenRecipeIds = {};

  // ---- Recipe feed pagination (search) ----
  final List<Recipe> _searchResults = [];
  bool _hasMoreSearch = true;
  bool _loadingMoreSearch = false;
  int _searchOffset = 0;

  // ---- Creator feed pagination ----
  final List<Creator> _creators = [];
  bool _hasMoreCreators = true;
  bool _loadingMoreCreators = false;
  final Set<String> _seenCreatorIds = {};

  // ---- Creator search/filter/sort ----
  final _creatorsSearchCtrl = TextEditingController();
  String  _creatorsQuery    = '';
  String? _creatorsRegionId;
  String? _creatorsSpecialty;
  String? _creatorsOrderBy;

  bool get _hasActiveFilter =>
      _regionId != null || _difficulty != null || _maxTimeMin != null || _minCal != null || _maxCal != null || _orderBy != null || _mealType != null;

  bool get _hasActiveCreatorFilter =>
      _creatorsRegionId != null || _creatorsSpecialty != null;

  List<Creator> get _filteredCreators => filterAndSortCreators(
        _creators,
        query: _creatorsQuery,
        regionId: _creatorsRegionId,
        specialty: _creatorsSpecialty,
        orderBy: _creatorsOrderBy,
      );

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _logger.provider('FeedPage initState()');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _creatorsSearchCtrl.dispose();
    _logger.provider('FeedPage disposed');
    super.dispose();
  }

  void _resetRecipes() {
    _recipes.clear();
    _seenRecipeIds.clear();
    _hasMoreRecipes = true;
    _loadingMoreRecipes = false;
    _searchResults.clear();
    _searchOffset = 0;
    _hasMoreSearch = true;
    _loadingMoreSearch = false;
  }

  void _resetCreators() {
    _creators.clear();
    _seenCreatorIds.clear();
    _hasMoreCreators = true;
    _loadingMoreCreators = false;
  }

  Future<void> _loadMoreRecipes() async {
    if (_loadingMoreRecipes || !_hasMoreRecipes) return;
    _logger.userAction('Load more recipes triggered', screen: 'FeedPage',
        metadata: {'seenCount': _seenRecipeIds.length.toString()});
    setState(() => _loadingMoreRecipes = true);

    final params = FeedParams(
      limit: _pageSize,
      excludeIds: _seenRecipeIds.toList(),
      regionId: _regionId,
      difficulty: _difficulty,
      maxTimeMin: _maxTimeMin,
      minCal: _minCal,
      maxCal: _maxCal,
      orderBy: _orderBy,
      mealType: _mealType,
    );

    try {
      final page = await ref.read(feedProvider(params).future);
      _logger.db('AFTER rpc | fn: generate_feed_personalized | page rows: ${page.length}');
      if (mounted) {
        setState(() {
          if (page.isEmpty || page.length < _pageSize) {
            _hasMoreRecipes = false;
          }
          _recipes.addAll(page);
          _seenRecipeIds.addAll(page.map((r) => r.id));
        });
      }
    } catch (e, st) {
      _logger.db('ERROR | _loadMoreRecipes | $e', error: e, stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => _loadingMoreRecipes = false);
      }
    }
  }

  Future<void> _loadMoreSearch() async {
    if (_loadingMoreSearch || !_hasMoreSearch) return;
    _logger.userAction('Load more search triggered', screen: 'FeedPage',
        metadata: {'offset': _searchOffset.toString(), 'query': _searchQuery});
    setState(() => _loadingMoreSearch = true);

    final params = SearchParams(
      query: _searchQuery,
      regionId: _regionId,
      difficulty: _difficulty,
      maxTimeMin: _maxTimeMin,
      minCal: _minCal,
      maxCal: _maxCal,
      orderBy: _orderBy ?? 'relevance',
      limit: _pageSize,
      offset: _searchOffset,
      mealType: _mealType,
    );

    try {
      final page = await ref.read(searchRecipesProvider(params).future);
      _logger.db('AFTER | searchRecipesProvider | page rows: ${page.length} | offset: $_searchOffset');
      if (mounted) {
        setState(() {
          if (page.isEmpty || page.length < _pageSize) {
            _hasMoreSearch = false;
          }
          _searchResults.addAll(page);
          _searchOffset += page.length;
        });
      }
    } catch (e, st) {
      _logger.db('ERROR | _loadMoreSearch | $e', error: e, stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => _loadingMoreSearch = false);
      }
    }
  }

  Future<void> _loadMoreCreators() async {
    if (_loadingMoreCreators || !_hasMoreCreators) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Load more creators triggered', screen: 'FeedPage',
        metadata: {'seenCount': _seenCreatorIds.length.toString()});
    setState(() => _loadingMoreCreators = true);

    final client = ref.read(supabaseClientProvider);
    try {
      _logger.db('BEFORE rpc | fn: generate_creators_personalized | p_exclude: ${_seenCreatorIds.length}');
      final rpcRows = await client.rpc('generate_creators_personalized', params: {
        'p_user_id': user.id,
        'p_limit': _pageSize,
        'p_exclude': _seenCreatorIds.toList(),
      }) as List<dynamic>;
      _logger.db('AFTER rpc | fn: generate_creators_personalized | rows: ${rpcRows.length}');

      if (rpcRows.isEmpty) {
        _logger.rls('Zero rows | table: generate_creators_personalized | userId: ${user.id} | possible RLS block');
        if (mounted) {
          setState(() => _hasMoreCreators = false);
        }
        return;
      }

      final orderedIds = rpcRows
          .map((r) => (r as Map<String, dynamic>)['creator_id'] as String)
          .toList();

      _logger.db('BEFORE | table: creator | op: SELECT IN | ids: ${orderedIds.length}');
      final rows = await client
          .from('creator')
          .select('id, user_id, display_name, profile_image_url, bio, specialties, recipe_count, fan_count, average_rating, heritage_region')
          .inFilter('id', orderedIds) as List<dynamic>;
      _logger.db('AFTER | table: creator | rows: ${rows.length}');

      if (rows.isEmpty) {
        _logger.rls('Zero rows | table: creator | userId: ${user.id} | possible RLS block');
      }

      final creatorMap = {
        for (final r in rows)
          (r as Map<String, dynamic>)['id'] as String: Creator.fromJson(r)
      };
      final page = orderedIds
          .where((id) => creatorMap.containsKey(id))
          .map((id) => creatorMap[id]!)
          .toList();

      if (mounted) {
        setState(() {
          if (page.isEmpty || page.length < _pageSize) {
            _hasMoreCreators = false;
          }
          _creators.addAll(page);
          _seenCreatorIds.addAll(page.map((c) => c.id));
        });
      }
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | table: creator | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | table: creator | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
      }
    } catch (e, st) {
      _logger.db('ERROR | _loadMoreCreators | $e', error: e, stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => _loadingMoreCreators = false);
      }
    }
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

  String _mealTypeLabel() => switch (_mealType) {
        'breakfast' => 'Petit-déjeuner',
        'lunch'     => 'Déjeuner',
        'dinner'    => 'Dîner',
        'snack'     => 'Collation',
        _           => 'Type ▾',
      };

  String _creatorsRegionLabel() {
    if (_creatorsRegionId == null) return 'Région';
    final names = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
    return names[_creatorsRegionId] ?? _creatorsRegionId!;
  }

  String _creatorsSpecialtyLabel() => _creatorsSpecialty ?? 'Spécialité';

  String _creatorsSortLabel() => switch (_creatorsOrderBy) {
        'rating'  => 'Mieux notés',
        'fans'    => 'Plus de fans',
        'recipes' => 'Plus de recettes',
        _         => 'Tri',
      };

  void _showCombinedFilterSheet(BuildContext context) {
    _logger.userAction('Combined filter sheet opened', screen: 'FeedPage');
    final regionNames = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
    
    String? tempRegion = _regionId;
    String? tempDiff = _difficulty;
    int? tempTime = _maxTimeMin;
    int? tempMinCal = _minCal;
    int? tempMaxCal = _maxCal;
    String? tempMealType = _mealType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.surface,
      builder: (ctx) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              onSecondaryContainer: Colors.white,
            ),
            chipTheme: ChipThemeData(
              selectedColor: AkeliColors.primary,
              backgroundColor: AkeliColors.surfaceContainerHigh,
              side: BorderSide(color: AkeliColors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AkeliSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filtres', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Région', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: tempRegion == null,
                          onSelected: (v) => setModalState(() => tempRegion = null),
                        ),
                        ...regionNames.entries.map((e) => ChoiceChip(
                          label: Text(e.value),
                          selected: tempRegion == e.key,
                          onSelected: (v) => setModalState(() => tempRegion = e.key),
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Difficulté', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: tempDiff == null,
                          onSelected: (v) => setModalState(() => tempDiff = null),
                        ),
                        ChoiceChip(
                          label: const Text('Facile'),
                          selected: tempDiff == 'easy',
                          onSelected: (v) => setModalState(() => tempDiff = 'easy'),
                        ),
                        ChoiceChip(
                          label: const Text('Moyen'),
                          selected: tempDiff == 'medium',
                          onSelected: (v) => setModalState(() => tempDiff = 'medium'),
                        ),
                        ChoiceChip(
                          label: const Text('Difficile'),
                          selected: tempDiff == 'hard',
                          onSelected: (v) => setModalState(() => tempDiff = 'hard'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Type de repas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tous'),
                          selected: tempMealType == null,
                          onSelected: (v) => setModalState(() => tempMealType = null),
                        ),
                        ChoiceChip(
                          label: const Text('Petit-déjeuner'),
                          selected: tempMealType == 'breakfast',
                          onSelected: (v) => setModalState(() => tempMealType = 'breakfast'),
                        ),
                        ChoiceChip(
                          label: const Text('Déjeuner'),
                          selected: tempMealType == 'lunch',
                          onSelected: (v) => setModalState(() => tempMealType = 'lunch'),
                        ),
                        ChoiceChip(
                          label: const Text('Dîner'),
                          selected: tempMealType == 'dinner',
                          onSelected: (v) => setModalState(() => tempMealType = 'dinner'),
                        ),
                        ChoiceChip(
                          label: const Text('Collation'),
                          selected: tempMealType == 'snack',
                          onSelected: (v) => setModalState(() => tempMealType = 'snack'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Temps maximum', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tous'),
                          selected: tempTime == null,
                          onSelected: (v) => setModalState(() => tempTime = null),
                        ),
                        ChoiceChip(
                          label: const Text('< 30 min'),
                          selected: tempTime == 30,
                          onSelected: (v) => setModalState(() => tempTime = 30),
                        ),
                        ChoiceChip(
                          label: const Text('< 60 min'),
                          selected: tempTime == 60,
                          onSelected: (v) => setModalState(() => tempTime = 60),
                        ),
                        ChoiceChip(
                          label: const Text('< 90 min'),
                          selected: tempTime == 90,
                          onSelected: (v) => setModalState(() => tempTime = 90),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Calories (kcal/100g)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(
                        (tempMinCal ?? 0).toDouble(),
                        (tempMaxCal ?? 800).toDouble(),
                      ),
                      min: 0,
                      max: 800,
                      divisions: 40,
                      labels: RangeLabels(
                        '${tempMinCal ?? 0} kcal/100g',
                        '${tempMaxCal ?? '800+'} kcal/100g',
                      ),
                      activeColor: AkeliColors.primary,
                      onChanged: (RangeValues values) {
                        setModalState(() {
                          tempMinCal = values.start.toInt();
                          tempMaxCal = values.end.toInt();
                          if (tempMinCal == 0) tempMinCal = null;
                          if (tempMaxCal == 800) tempMaxCal = null;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${tempMinCal ?? 0} kcal/100g', style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant)),
                        Text(tempMaxCal == null ? '800+ kcal/100g' : '$tempMaxCal kcal/100g', style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _regionId = tempRegion;
                            _difficulty = tempDiff;
                            _maxTimeMin = tempTime;
                            _minCal = tempMinCal;
                            _maxCal = tempMaxCal;
                            _mealType = tempMealType;
                            _resetRecipes();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Appliquer les filtres'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          ),
        );
      }
    );
  }

  void _showSortSheet(BuildContext context) {
    _logger.userAction('Sort sheet opened', screen: 'FeedPage');
    showModalBottomSheet(
      context: context,
      backgroundColor: AkeliColors.surface,
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
          setState(() {
            _orderBy = key;
            _resetRecipes();
          });
        },
      ),
    );
  }

  static const _creatorSpecialties = [
    'Cuisine traditionnelle',
    'Cuisine fusion',
    'Cuisine végétarienne',
    'Pâtisserie',
    'Street food',
  ];

  void _showCreatorFilterSheet(BuildContext context, Map<String, String> regionNames) {
    _logger.userAction('Creator filter sheet opened', screen: 'FeedPage');
    String? tempRegion    = _creatorsRegionId;
    String? tempSpecialty = _creatorsSpecialty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.surface,
      builder: (ctx) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              onSecondaryContainer: Colors.white,
            ),
            chipTheme: ChipThemeData(
              selectedColor: AkeliColors.primary,
              backgroundColor: AkeliColors.surfaceContainerHigh,
              side: BorderSide(color: AkeliColors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AkeliSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filtres', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Région', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: tempRegion == null,
                          onSelected: (_) => setModalState(() => tempRegion = null),
                        ),
                        ...regionNames.entries.map((e) => ChoiceChip(
                          label: Text(e.value),
                          selected: tempRegion == e.key,
                          onSelected: (_) => setModalState(() => tempRegion = e.key),
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Spécialité', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: tempSpecialty == null,
                          onSelected: (_) => setModalState(() => tempSpecialty = null),
                        ),
                        ..._creatorSpecialties.map((s) => ChoiceChip(
                          label: Text(s),
                          selected: tempSpecialty == s,
                          onSelected: (_) => setModalState(() => tempSpecialty = s),
                        )),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          _logger.userAction('Creator filter applied', screen: 'FeedPage',
                              metadata: {'regionId': tempRegion, 'specialty': tempSpecialty});
                          setState(() {
                            _creatorsRegionId  = tempRegion;
                            _creatorsSpecialty = tempSpecialty;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Appliquer les filtres'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
        );
      },
    );
  }

  void _showCreatorSortSheet(BuildContext context) {
    _logger.userAction('Creator sort sheet opened', screen: 'FeedPage');
    showModalBottomSheet(
      context: context,
      backgroundColor: AkeliColors.surface,
      builder: (_) => _FilterSheet<String>(
        title: 'Trier par',
        options: const [
          MapEntry(null, 'Personnalisé'),
          MapEntry('rating', 'Mieux notés'),
          MapEntry('fans', 'Plus de fans'),
          MapEntry('recipes', 'Plus de recettes'),
        ],
        selectedKey: _creatorsOrderBy,
        onSelect: (key) {
          _logger.userAction('Creator sort changed', screen: 'FeedPage',
              metadata: {'orderBy': key});
          setState(() => _creatorsOrderBy = key);
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
            minCal: _minCal,
            maxCal: _maxCal,
            orderBy: _orderBy ?? 'relevance',
            limit: _pageSize,
            mealType: _mealType,
          )))
        : ref.watch(feedProvider(FeedParams(
            limit: _pageSize,
            regionId: _regionId,
            difficulty: _difficulty,
            maxTimeMin: _maxTimeMin,
            minCal: _minCal,
            maxCal: _maxCal,
            orderBy: _orderBy,
            mealType: _mealType,
          )));


    final regionNames = ref.watch(foodRegionNamesProvider).valueOrNull ?? {};

    _logger.provider('FeedPage build() | isSearching: $isSearching | feedAsync.isLoading: ${feedAsync.isLoading}');

    final body = NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 500) {
          if (_tabIndex == 0) {
            isSearching ? _loadMoreSearch() : _loadMoreRecipes();
          } else {
            _loadMoreCreators();
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AkeliColors.background,
          leading: widget.swapEntryId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                )
              : null,
          title: widget.swapEntryId != null
              ? const Text('Sélectionner une recette', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              : Text(
                  'Recettes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AkeliColors.onSurface,
                  ),
                ),
          actions: const [],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_tabIndex == 0 ? 164 : 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
                  child: AkeliTabBar(
                    tabs: const ['Recettes', 'Créateurs'],
                    selectedIndex: _tabIndex,
                    onTabSelected: (i) {
                      _logger.userAction('Feed tab selected', screen: 'FeedPage',
                          metadata: {'tabIndex': i.toString()});
                      setState(() {
                        _tabIndex = i;
                        _resetRecipes();
                        _resetCreators();
                      });
                    },
                  ),
                ),
                if (_tabIndex == 0) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              searchBarTheme: const SearchBarThemeData(
                                backgroundColor: WidgetStatePropertyAll(AkeliColors.surfaceContainerLow),
                              ),
                            ),
                            child: SearchBar(
                              controller: _searchCtrl,
                              hintText: 'Rechercher...',
                              leading: const Icon(Icons.search_rounded),
                              trailing: _searchQuery.isNotEmpty
                                  ? [
                                      IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _logger.userAction('Search cleared', screen: 'FeedPage');
                                          _searchCtrl.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _resetRecipes();
                                          });
                                        },
                                      )
                                    ]
                                  : null,
                              onChanged: (v) {
                                setState(() {
                                  _searchQuery = v;
                                  _resetRecipes();
                                });
                              },
                              elevation: const WidgetStatePropertyAll(0),
                              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                              constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _regionId != null || _difficulty != null || _maxTimeMin != null || _minCal != null || _maxCal != null
                                ? AkeliColors.primaryContainer
                                : AkeliColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune_rounded),
                            color: _regionId != null || _difficulty != null || _maxTimeMin != null || _minCal != null || _maxCal != null
                                ? AkeliColors.onPrimaryContainer
                                : AkeliColors.onSurfaceVariant,
                            onPressed: () => _showCombinedFilterSheet(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _orderBy != null
                                ? AkeliColors.primaryContainer
                                : AkeliColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.sort_rounded),
                            color: _orderBy != null
                                ? AkeliColors.onPrimaryContainer
                                : AkeliColors.onSurfaceVariant,
                            onPressed: () => _showSortSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: !_hasActiveFilter
                      ? const SizedBox.shrink()
                      : ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
                        children: [
                          if (_regionId != null) ...[
                            _ActiveFilterChip(
                              label: _regionLabel(),
                              onDeleted: () => setState(() {
                                _regionId = null;
                                _resetRecipes();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_difficulty != null) ...[
                            _ActiveFilterChip(
                              label: _difficultyLabel(),
                              onDeleted: () => setState(() {
                                _difficulty = null;
                                _resetRecipes();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_maxTimeMin != null) ...[
                            _ActiveFilterChip(
                              label: _timeLabel(),
                              onDeleted: () => setState(() {
                                _maxTimeMin = null;
                                _resetRecipes();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_minCal != null || _maxCal != null) ...[
                            _ActiveFilterChip(
                              label: '${_minCal ?? 0} - ${_maxCal ?? '800+'} kcal/100g',
                              onDeleted: () => setState(() {
                                _minCal = null;
                                _maxCal = null;
                                _resetRecipes();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_orderBy != null) ...[
                            _ActiveFilterChip(
                              label: _sortLabel(),
                              onDeleted: () => setState(() {
                                _orderBy = null;
                                _resetRecipes();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_mealType != null) ...[
                            _ActiveFilterChip(
                              label: _mealTypeLabel(),
                              onDeleted: () => setState(() {
                                _mealType = null;
                                _resetRecipes();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _regionId = null;
                                _difficulty = null;
                                _maxTimeMin = null;
                                _minCal = null;
                                _maxCal = null;
                                _orderBy = null;
                                _resetRecipes();
                              });
                            },
                            child: const Text('Tout effacer', style: TextStyle(fontSize: 13)),
                          )
                        ],
                      ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),

        // Content
        if (_tabIndex == 0)
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
          data: (initialPage) {
            if (isSearching) {
              if (_searchResults.isEmpty && initialPage.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _searchResults.isEmpty) {
                    setState(() {
                      _searchResults.addAll(initialPage);
                      _searchOffset = initialPage.length;
                      _hasMoreSearch = initialPage.length == _pageSize;
                    });
                  }
                });
              }
            } else {
              if (_recipes.isEmpty && initialPage.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _recipes.isEmpty) {
                    setState(() {
                      _recipes.addAll(initialPage);
                      _seenRecipeIds.addAll(initialPage.map((r) => r.id));
                      _hasMoreRecipes = initialPage.length == _pageSize;
                    });
                  }
                });
              }
            }

            final displayList = isSearching ? _searchResults : _recipes;

            if (displayList.isEmpty) {
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
              padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.md,
                vertical: AkeliSpacing.sm,
              ),
              sliver: SliverList.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final recipe = displayList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AkeliSpacing.md),
                    child: AkeliRecipeCard(
                    horizontal: true,
                    title: recipe.title,
                    calories100g: recipe.calories100g?.toInt(),
                    rating: recipe.averageRating,
                    likes: recipe.likeCount,
                    comments: recipe.commentCount,
                    saves: recipe.saveCount,
                    emoji: null,
                    region: recipe.regionId != null
                        ? regionNames[recipe.regionId!] ?? recipe.regionId
                        : null,
                    tags: recipe.tagIds.take(2).toList(),
                    onTap: () async {
                      _logger.userAction('Recipe card tapped', screen: 'FeedPage', metadata: {'recipeId': recipe.id});

                      if (widget.swapEntryId != null) {
                        try {
                          await ref.read(mealPlanSwapProvider.notifier).swapMeal(widget.swapEntryId!, recipe.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Repas remplacé avec succès'),
                            backgroundColor: AkeliColors.primary,
                          ));
                          context.pop();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Erreur lors du remplacement du repas'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      } else {
                        context.push(
                          AkeliRoutes.recipeDetailPath(recipe.id),
                          extra: TrackingSource.feed,
                        );
                      }
                    },
                    ),
                  );
                },
              ),
            );
          },
          ),
        if (_tabIndex == 0 && (isSearching ? _searchResults.isNotEmpty : _recipes.isNotEmpty))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: (isSearching ? _loadingMoreSearch : _loadingMoreRecipes)
                    ? const CircularProgressIndicator()
                    : (!(isSearching ? _hasMoreSearch : _hasMoreRecipes)
                        ? const Text('Fin des résultats', style: TextStyle(color: Colors.grey))
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        if (_tabIndex != 0) ...[
          _buildCreatorSearchControls(regionNames),
          _buildCreateursSliver(regionNames),
        ],
        if (_tabIndex != 0 && _creators.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: _loadingMoreCreators
                    ? const CircularProgressIndicator()
                    : (!_hasMoreCreators
                        ? const Text('Fin des résultats', style: TextStyle(color: Colors.grey))
                        : const SizedBox.shrink()),
              ),
            ),
          ),
      ],
    ));

    if (widget.swapEntryId != null) {
      return Scaffold(backgroundColor: AkeliColors.background, body: body);
    }
    return body;
  }

  Widget _buildCreateursSliver(Map<String, String> regionNames) {
    final creatorsAsync = ref.watch(creatorsListProvider);
    _logger.provider('_buildCreateursSliver | creatorsAsync.isLoading: ${creatorsAsync.isLoading}');

    return creatorsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(creatorsListProvider),
        ),
      ),
      data: (initialPage) {
        if (_creators.isEmpty && initialPage.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _creators.isEmpty) {
              setState(() {
                _creators.addAll(initialPage);
                _seenCreatorIds.addAll(initialPage.map((c) => c.id));
                _hasMoreCreators = initialPage.length == _pageSize;
              });
            }
          });
        }

        final displayList = _filteredCreators;

        if (displayList.isEmpty) {
          final isFiltered = _creatorsQuery.isNotEmpty || _hasActiveCreatorFilter;
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.person_rounded,
              title: isFiltered
                  ? 'Aucun créateur trouvé'
                  : 'Aucun créateur disponible',
              subtitle: isFiltered
                  ? 'Essayez d\'autres termes ou réinitialisez les filtres.'
                  : 'Les créateurs apparaîtront ici.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final creator = displayList[index];
                return CreatorCard(
                  creator: creator,
                  regionName: creator.regionId != null
                      ? regionNames[creator.regionId!] ?? creator.regionId
                      : null,
                  onTap: () {
                    _logger.userAction('Creator card tapped', screen: 'FeedPage',
                        metadata: {'creatorId': creator.id});
                    context.push(AkeliRoutes.creatorDetailPath(creator.id));
                  },
                );
              },
              childCount: displayList.length,
            ),
          ),
        );
      },
    );
  }
  Widget _buildCreatorSearchControls(Map<String, String> regionNames) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AkeliSpacing.md, AkeliSpacing.sm, AkeliSpacing.md, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search row: text field + filter icon + sort icon
            Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _creatorsSearchCtrl,
                    hintText: 'Rechercher un créateur…',
                    leading: const Icon(Icons.search_rounded),
                    trailing: _creatorsQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _creatorsSearchCtrl.clear();
                                setState(() => _creatorsQuery = '');
                              },
                            )
                          ]
                        : null,
                    onChanged: (v) {
                      _logger.userAction('Creators search query changed',
                          screen: 'FeedPage', metadata: {'query': v});
                      setState(() => _creatorsQuery = v);
                    },
                    elevation: const WidgetStatePropertyAll(0),
                    padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12)),
                    constraints:
                        const BoxConstraints(minHeight: 48, maxHeight: 48),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _hasActiveCreatorFilter
                        ? AkeliColors.primaryContainer
                        : AkeliColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    color: _hasActiveCreatorFilter
                        ? AkeliColors.onPrimaryContainer
                        : AkeliColors.onSurfaceVariant,
                    onPressed: () =>
                        _showCreatorFilterSheet(context, regionNames),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _creatorsOrderBy != null
                        ? AkeliColors.primaryContainer
                        : AkeliColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    color: _creatorsOrderBy != null
                        ? AkeliColors.onPrimaryContainer
                        : AkeliColors.onSurfaceVariant,
                    onPressed: () => _showCreatorSortSheet(context),
                  ),
                ),
              ],
            ),
            if (_hasActiveCreatorFilter) const SizedBox(height: 8),
            // Active filter chips row
            SizedBox(
              height: _hasActiveCreatorFilter ? 36 : 0,
              child: !_hasActiveCreatorFilter
                  ? const SizedBox.shrink()
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (_creatorsRegionId != null) ...[
                          _ActiveFilterChip(
                            label: _creatorsRegionLabel(),
                            onDeleted: () =>
                                setState(() => _creatorsRegionId = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_creatorsSpecialty != null) ...[
                          _ActiveFilterChip(
                            label: _creatorsSpecialtyLabel(),
                            onDeleted: () =>
                                setState(() => _creatorsSpecialty = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_creatorsOrderBy != null) ...[
                          _ActiveFilterChip(
                            label: _creatorsSortLabel(),
                            onDeleted: () =>
                                setState(() => _creatorsOrderBy = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () {
                            _creatorsSearchCtrl.clear();
                            setState(() {
                              _creatorsQuery     = '';
                              _creatorsRegionId  = null;
                              _creatorsSpecialty = null;
                              _creatorsOrderBy   = null;
                            });
                          },
                          child: const Text('Tout effacer',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
            ),
            if (_hasActiveCreatorFilter) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _ActiveFilterChip({
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: AkeliColors.primaryContainer.withValues(alpha: 0.5),
      deleteIconColor: AkeliColors.onPrimaryContainer,
      labelStyle: const TextStyle(color: AkeliColors.onPrimaryContainer),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      padding: EdgeInsets.zero,
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
