# Recipe Video, Ingredient Detail Sheet & Cooking Mode — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a recipe video player, a rich ingredient detail bottom sheet, and a full-screen guided cooking mode to the existing `RecipeDetailPage`.

**Architecture:** Three additive features share the `Recipe` object already loaded by `recipeDetailProvider`. Cooking mode is a new page at `/recipe/:id/cook` receiving the `Recipe` via GoRouter `extra`. The ingredient detail sheet is a modal opened from both pages. Two DB migrations extend existing tables; no new tables are created.

**Tech Stack:** Flutter/Dart, Riverpod FutureProvider.family, GoRouter nested routes, `video_player` + `chewie` packages, `percent_indicator` (already in pubspec), Supabase Postgres.

---

## File Manifest

| File | Action |
|------|--------|
| `supabase/migrations/20260608100000_recipe_video_cooking_mode.sql` | Create |
| `lib/shared/models/recipe.dart` | Modify — add `videoUrl` to `Recipe`, `videoUrl`+`ingredientIds` to `RecipeStep` |
| `lib/shared/models/ingredient_detail.dart` | Create |
| `test/shared/models/ingredient_detail_test.dart` | Create |
| `lib/providers/ingredient_provider.dart` | Create |
| `lib/shared/widgets/recipe_video_card.dart` | Create |
| `lib/features/recipes/widgets/ingredient_detail_sheet.dart` | Create |
| `lib/features/cooking/cooking_mode_page.dart` | Create |
| `lib/features/recipes/recipe_detail_page.dart` | Modify — video card, tappable ingredients/steps, Start Cooking CTA |
| `lib/core/router.dart` | Modify — nested `/cook` route + `AkeliRoutes` constants |
| `pubspec.yaml` | Modify — add `video_player`, `chewie` |

---

## Task 1: DB Migration

**Files:**
- Create: `supabase/migrations/20260608100000_recipe_video_cooking_mode.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260608100000_recipe_video_cooking_mode.sql

-- recipe: presentation video URL
ALTER TABLE recipe ADD COLUMN IF NOT EXISTS video_url TEXT NULL;

-- recipe_step: per-step video and tagged ingredient IDs
ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS video_url       TEXT   NULL;
ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS ingredient_ids  UUID[] NULL;

-- ingredient: nutritional values and contextual notes (all nullable)
ALTER TABLE ingredient
  ADD COLUMN IF NOT EXISTS calories_per_100g NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS protein_g         NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS carbs_g           NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS fat_g             NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS fiber_g           NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS substitution      TEXT    NULL,
  ADD COLUMN IF NOT EXISTS market_notes      TEXT    NULL;
```

- [ ] **Step 2: Apply the migration**

```bash
supabase db push
```

Expected: `Applied 1 migration` with no errors.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260608100000_recipe_video_cooking_mode.sql
git commit -m "feat(db): add video_url/ingredient_ids to recipe_step, nutritional columns to ingredient"
```

---

## Task 2: Update Dart Models

**Files:**
- Modify: `lib/shared/models/recipe.dart`
- Create: `lib/shared/models/ingredient_detail.dart`
- Create: `test/shared/models/ingredient_detail_test.dart`

- [ ] **Step 1: Write failing tests for the new models**

Create `test/shared/models/ingredient_detail_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/ingredient_detail.dart';
import 'package:akeli/shared/models/recipe.dart';

void main() {
  group('IngredientDetail.fromJson', () {
    test('maps all fields when present', () {
      final detail = IngredientDetail.fromJson({
        'id': 'ing-1',
        'name_fr': 'Gombo',
        'calories_per_100g': 33.0,
        'protein_g': 1.9,
        'carbs_g': 7.5,
        'fat_g': 0.2,
        'fiber_g': 3.2,
        'substitution': 'Haricots verts',
        'market_notes': 'Épicerie africaine',
      });

      expect(detail.id, 'ing-1');
      expect(detail.name, 'Gombo');
      expect(detail.caloriesPer100g, 33.0);
      expect(detail.proteinG, 1.9);
      expect(detail.substitution, 'Haricots verts');
      expect(detail.marketNotes, 'Épicerie africaine');
    });

    test('returns null for nullable fields when absent', () {
      final detail = IngredientDetail.fromJson({
        'id': 'ing-2',
        'name': 'Okra',
      });

      expect(detail.caloriesPer100g, isNull);
      expect(detail.substitution, isNull);
      expect(detail.marketNotes, isNull);
    });

    test('prefers name_fr over name', () {
      final detail = IngredientDetail.fromJson({
        'id': 'ing-3',
        'name_fr': 'Gombo',
        'name': 'Okra',
      });
      expect(detail.name, 'Gombo');
    });
  });

  group('RecipeStep.fromJson with new fields', () {
    test('parses video_url and ingredient_ids', () {
      final step = RecipeStep.fromJson({
        'step_number': 1,
        'instruction': 'Couper les légumes',
        'video_url': 'https://example.com/step1.mp4',
        'ingredient_ids': ['id-a', 'id-b'],
      });

      expect(step.videoUrl, 'https://example.com/step1.mp4');
      expect(step.ingredientIds, ['id-a', 'id-b']);
    });

    test('defaults ingredient_ids to empty list when null', () {
      final step = RecipeStep.fromJson({
        'step_number': 1,
        'instruction': 'Couper',
      });
      expect(step.ingredientIds, isEmpty);
      expect(step.videoUrl, isNull);
    });
  });

  group('Recipe.fromJson videoUrl', () {
    test('parses video_url field', () {
      final recipe = Recipe.fromJson({
        'id': 'r1',
        'creator_id': 'c1',
        'title': 'Thiéboudienne',
        'prep_time_min': 30,
        'cook_time_min': 60,
        'servings': 4,
        'difficulty': 'medium',
        'average_rating': 4.5,
        'average_rating_taste': 4.5,
        'average_rating_ease': 4.0,
        'average_rating_satiety': 4.0,
        'rating_count': 10,
        'comment_count': 2,
        'like_count': 5,
        'save_count': 3,
        'is_saved': false,
        'is_liked': false,
        'is_published': true,
        'video_url': 'https://example.com/recipe.mp4',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(recipe.videoUrl, 'https://example.com/recipe.mp4');
    });

    test('videoUrl is null when absent', () {
      final recipe = Recipe.fromJson({
        'id': 'r1',
        'creator_id': 'c1',
        'title': 'Thiéboudienne',
        'prep_time_min': 30,
        'cook_time_min': 60,
        'servings': 4,
        'difficulty': 'medium',
        'average_rating': 4.5,
        'average_rating_taste': 4.5,
        'average_rating_ease': 4.0,
        'average_rating_satiety': 4.0,
        'rating_count': 10,
        'comment_count': 2,
        'like_count': 5,
        'save_count': 3,
        'is_saved': false,
        'is_liked': false,
        'is_published': true,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(recipe.videoUrl, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/shared/models/ingredient_detail_test.dart
```

Expected: FAIL — `IngredientDetail` and new fields not found.

- [ ] **Step 3: Create `IngredientDetail` model**

Create `lib/shared/models/ingredient_detail.dart`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class IngredientDetail {
  final String id;
  final String name;
  final double? caloriesPer100g;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final String? substitution;
  final String? marketNotes;

  const IngredientDetail({
    required this.id,
    required this.name,
    this.caloriesPer100g,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.substitution,
    this.marketNotes,
  });

  factory IngredientDetail.fromJson(Map<String, dynamic> json) =>
      IngredientDetail(
        id: json['id'] as String,
        name: json['name_fr'] as String? ?? json['name'] as String? ?? '',
        caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble(),
        substitution: json['substitution'] as String?,
        marketNotes: json['market_notes'] as String?,
      );
}
```

- [ ] **Step 4: Update `Recipe` model — add `videoUrl` and update `RecipeStep`**

In `lib/shared/models/recipe.dart`:

Add to `Recipe` class:
```dart
final String? videoUrl;
```

Add `videoUrl` to the `Recipe` constructor:
```dart
this.videoUrl,
```

Add to `Recipe.fromJson`:
```dart
videoUrl: json['video_url'] as String?,
```

Add to `RecipeStep` class:
```dart
final String? videoUrl;
final List<String> ingredientIds;
```

Update `RecipeStep` constructor:
```dart
const RecipeStep({
  required this.stepNumber,
  required this.instruction,
  this.durationMin,
  this.imageUrl,
  this.videoUrl,
  this.ingredientIds = const [],
});
```

Update `RecipeStep.fromJson`:
```dart
factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
  stepNumber: json['step_number'] as int,
  instruction: json['instruction'] as String?
      ?? json['content'] as String? ?? '',
  durationMin: json['duration_min'] as int?
      ?? ((json['timer_seconds'] as int?) != null
          ? ((json['timer_seconds'] as int) / 60).round()
          : null),
  imageUrl: json['image_url'] as String?,
  videoUrl: json['video_url'] as String?,
  ingredientIds: (json['ingredient_ids'] as List<dynamic>?)
          ?.cast<String>() ??
      const [],
);
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/shared/models/ingredient_detail_test.dart
```

Expected: All tests PASS.

- [ ] **Step 6: Run full test suite to check for regressions**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/models/recipe.dart lib/shared/models/ingredient_detail.dart test/shared/models/ingredient_detail_test.dart
git commit -m "feat(models): add videoUrl to Recipe, videoUrl+ingredientIds to RecipeStep, new IngredientDetail model"
```

---

## Task 3: Ingredient Provider

**Files:**
- Create: `lib/providers/ingredient_provider.dart`

- [ ] **Step 1: Create the provider**

Create `lib/providers/ingredient_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../shared/models/ingredient_detail.dart';

final ingredientDetailProvider =
    FutureProvider.family<IngredientDetail?, String>((ref, ingredientId) async {
  final logger = appLogger;
  logger.db(
      'BEFORE | table: ingredient | op: SELECT | ingredientId: $ingredientId');

  try {
    final data = await Supabase.instance.client
        .from('ingredient')
        .select(
            'id, name_fr, name, calories_per_100g, protein_g, carbs_g, fat_g, fiber_g, substitution, market_notes')
        .eq('id', ingredientId)
        .maybeSingle();

    if (data == null) {
      logger.rls(
          'Zero rows | table: ingredient | ingredientId: $ingredientId | possible RLS block');
      return null;
    }

    logger.db('AFTER | table: ingredient | rows: 1');
    return IngredientDetail.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: ingredient | ingredientId: $ingredientId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: ingredient | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    return null;
  }
});
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/providers/ingredient_provider.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/ingredient_provider.dart
git commit -m "feat(providers): add ingredientDetailProvider"
```

---

## Task 4: Add Video Packages

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

In the `dependencies:` section of `pubspec.yaml`, after `cached_network_image`:

```yaml
  video_player: ^2.9.2
  chewie: ^1.8.5
```

- [ ] **Step 2: Install packages**

```bash
flutter pub get
```

Expected: Dependencies resolved, no conflicts.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat(deps): add video_player and chewie packages"
```

---

## Task 5: RecipeVideoCard Widget

**Files:**
- Create: `lib/shared/widgets/recipe_video_card.dart`

- [ ] **Step 1: Create the widget**

Create `lib/shared/widgets/recipe_video_card.dart`:

```dart
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecipeVideoCard extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const RecipeVideoCard({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<RecipeVideoCard> createState() => _RecipeVideoCardState();
}

class _RecipeVideoCardState extends State<RecipeVideoCard> {
  final _logger = appLogger;
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _logger.provider(
        'RecipeVideoCard initState() | videoUrl: ${widget.videoUrl}');
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        placeholder: widget.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
            : null,
      );
      _videoController.addListener(_onVideoEvent);
      if (mounted) {
        setState(() => _initialized = true);
        _logger.provider('RecipeVideoCard → initialized');
      }
    } catch (e, st) {
      _logger.edge('video-player', 'ERROR | init failed | ${widget.videoUrl}',
          error: e, stackTrace: st);
    }
  }

  void _onVideoEvent() {
    if (_videoController.value.isPlaying) {
      _logger.userAction('Recipe video playing', screen: 'RecipeVideoCard');
    }
  }

  @override
  void dispose() {
    _logger.provider('RecipeVideoCard disposed');
    _videoController.removeListener(_onVideoEvent);
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('RecipeVideoCard build()');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          boxShadow: const [
            BoxShadow(
                color: Color(0x051B1C16),
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _initialized && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : widget.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                          color: AkeliColors.primary),
                    ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/shared/widgets/recipe_video_card.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/recipe_video_card.dart
git commit -m "feat(widgets): add RecipeVideoCard with chewie player"
```

---

## Task 6: Ingredient Detail Sheet

**Files:**
- Create: `lib/features/recipes/widgets/ingredient_detail_sheet.dart`

- [ ] **Step 1: Create the sheet widget**

Create `lib/features/recipes/widgets/ingredient_detail_sheet.dart`:

```dart
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/ingredient_provider.dart';
import 'package:akeli/shared/models/ingredient_detail.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class IngredientDetailSheet extends ConsumerWidget {
  final RecipeIngredient ingredient;

  const IngredientDetailSheet({super.key, required this.ingredient});

  static Future<void> show(BuildContext context, RecipeIngredient ingredient) {
    appLogger.userAction('IngredientDetailSheet opened',
        screen: 'IngredientDetailSheet',
        metadata: {'ingredientId': ingredient.ingredientId});
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IngredientDetailSheet(ingredient: ingredient),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider(
        'IngredientDetailSheet build() | ingredientId: ${ingredient.ingredientId}');
    final detailAsync =
        ref.watch(ingredientDetailProvider(ingredient.ingredientId));

    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AkeliColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                    ),
                    if (ingredient.isOptional)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AkeliColors.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.pill),
                        ),
                        child: Text(
                          'Optionnel',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AkeliColors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        AkeliColors.accentAmber.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.pill),
                  ),
                  child: Text(
                    '${ingredient.quantity.toStringAsFixed(ingredient.quantity % 1 == 0 ? 0 : 1)} ${ingredient.unit}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.accentAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: AkeliColors.surfaceContainerHighest),
                const SizedBox(height: 16),
                detailAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AkeliColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (detail) {
                    if (detail == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail.caloriesPer100g != null ||
                            detail.proteinG != null)
                          _NutritionSection(detail: detail),
                        if (detail.substitution != null)
                          _SubstitutionSection(
                              text: detail.substitution!),
                        if (detail.marketNotes != null)
                          _MarketNotesSection(
                              text: detail.marketNotes!),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  final IngredientDetail detail;
  const _NutritionSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valeurs nutritives (pour 100g)',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurface),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (detail.caloriesPer100g != null)
              Expanded(
                  child: _MacroChip(
                      label: 'Calories',
                      value:
                          '${detail.caloriesPer100g!.toStringAsFixed(0)} kcal')),
            if (detail.proteinG != null) ...[
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroChip(
                      label: 'Protéines',
                      value:
                          '${detail.proteinG!.toStringAsFixed(1)}g')),
            ],
            if (detail.carbsG != null) ...[
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroChip(
                      label: 'Glucides',
                      value: '${detail.carbsG!.toStringAsFixed(1)}g')),
            ],
          ],
        ),
        if (detail.fatG != null || detail.fiberG != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (detail.fatG != null)
                Expanded(
                    child: _MacroChip(
                        label: 'Lipides',
                        value: '${detail.fatG!.toStringAsFixed(1)}g')),
              if (detail.fiberG != null) ...[
                const SizedBox(width: 8),
                Expanded(
                    child: _MacroChip(
                        label: 'Fibres',
                        value:
                            '${detail.fiberG!.toStringAsFixed(1)}g')),
              ],
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurfaceVariant,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AkeliColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SubstitutionSection extends StatelessWidget {
  final String text;
  const _SubstitutionSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AkeliColors.accentAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          border: Border.all(
              color: AkeliColors.accentAmber.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.swap_horiz_rounded,
                color: AkeliColors.accentAmber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Substitution',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AkeliColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketNotesSection extends StatelessWidget {
  final String text;
  const _MarketNotesSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined,
                color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Où trouver',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AkeliColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/recipes/widgets/ingredient_detail_sheet.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/recipes/widgets/ingredient_detail_sheet.dart
git commit -m "feat(ui): add IngredientDetailSheet with nutrition, substitution, and market notes"
```

---

## Task 7: Cooking Mode Page

**Files:**
- Create: `lib/features/cooking/cooking_mode_page.dart`

- [ ] **Step 1: Create CookingModePage**

Create `lib/features/cooking/cooking_mode_page.dart`:

```dart
import 'dart:async';

import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/recipes/widgets/ingredient_detail_sheet.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:akeli/shared/widgets/recipe_video_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CookingModePage extends StatefulWidget {
  final Recipe recipe;
  final int initialStepIndex;

  const CookingModePage({
    super.key,
    required this.recipe,
    this.initialStepIndex = 0,
  });

  @override
  State<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends State<CookingModePage> {
  final _logger = appLogger;
  late int _currentStepIndex;
  int _timerSeconds = 0;
  bool _timerRunning = false;
  Timer? _timer;
  final Set<String> _checkedIngredients = {};

  RecipeStep get _currentStep =>
      widget.recipe.steps[_currentStepIndex];

  List<RecipeIngredient> get _stepIngredients {
    if (_currentStep.ingredientIds.isNotEmpty) {
      return widget.recipe.ingredients
          .where((i) =>
              _currentStep.ingredientIds.contains(i.ingredientId))
          .toList();
    }
    return widget.recipe.ingredients;
  }

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStepIndex
        .clamp(0, widget.recipe.steps.length - 1);
    _resetTimer();
    _logger.provider(
        'CookingModePage initState() | recipeId: ${widget.recipe.id} | initialStep: $_currentStepIndex');
    ref.onDispose(() {});
  }

  void _resetTimer() {
    _timer?.cancel();
    _timerRunning = false;
    _timerSeconds = (_currentStep.durationMin ?? 0) * 60;
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      _logger.userAction('Timer paused', screen: 'CookingModePage',
          metadata: {'step': _currentStepIndex + 1, 'remaining': _timerSeconds});
      setState(() => _timerRunning = false);
    } else {
      _logger.userAction('Timer started', screen: 'CookingModePage',
          metadata: {'step': _currentStepIndex + 1, 'totalSeconds': _timerSeconds});
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_timerSeconds <= 0) {
          t.cancel();
          HapticFeedback.mediumImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Étape terminée !'),
              backgroundColor: AkeliColors.primary,
            ));
            setState(() => _timerRunning = false);
          }
        } else {
          if (mounted) setState(() => _timerSeconds--);
        }
      });
      setState(() => _timerRunning = true);
    }
  }

  void _goToStep(int index) {
    if (index < 0 || index >= widget.recipe.steps.length) return;
    _logger.userAction('Step navigation', screen: 'CookingModePage',
        metadata: {'from': _currentStepIndex + 1, 'to': index + 1});
    setState(() {
      _currentStepIndex = index;
      _resetTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logger.provider(
        'CookingModePage disposed | recipeId: ${widget.recipe.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider(
        'CookingModePage build() | step: ${_currentStepIndex + 1}/${widget.recipe.steps.length}');
    final step = _currentStep;
    final totalSteps = widget.recipe.steps.length;
    final isLast = _currentStepIndex == totalSteps - 1;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -300) {
              _goToStep(_currentStepIndex + 1);
            } else if ((details.primaryVelocity ?? 0) > 300) {
              _goToStep(_currentStepIndex - 1);
            }
          },
          child: Column(
            children: [
              _TopBar(
                current: _currentStepIndex + 1,
                total: totalSteps,
                onClose: () {
                  _logger.userAction('Cooking mode closed',
                      screen: 'CookingModePage',
                      metadata: {'atStep': _currentStepIndex + 1});
                  context.pop();
                },
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Center(
                    child: Text(
                      step.instruction,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        height: 1.5,
                        color: AkeliColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              if (step.videoUrl != null || step.imageUrl != null)
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AkeliRadius.xl),
                      child: step.videoUrl != null
                          ? RecipeVideoCard(
                              videoUrl: step.videoUrl!,
                              thumbnailUrl: step.imageUrl)
                          : CachedNetworkImage(
                              imageUrl: step.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity),
                    ),
                  ),
                ),
              if (step.durationMin != null)
                _TimerWidget(
                  totalSeconds: step.durationMin! * 60,
                  remainingSeconds: _timerSeconds,
                  isRunning: _timerRunning,
                  onToggle: _toggleTimer,
                ),
              if (_stepIngredients.isNotEmpty)
                _IngredientStrip(
                  ingredients: _stepIngredients,
                  checked: _checkedIngredients,
                  onTap: (ing) =>
                      IngredientDetailSheet.show(context, ing),
                  onLongPress: (ing) {
                    _logger.userAction('Ingredient checked',
                        screen: 'CookingModePage',
                        metadata: {'ingredientId': ing.ingredientId});
                    setState(() {
                      if (_checkedIngredients
                          .contains(ing.ingredientId)) {
                        _checkedIngredients.remove(ing.ingredientId);
                      } else {
                        _checkedIngredients.add(ing.ingredientId);
                      }
                    });
                  },
                ),
              _NavButtons(
                isFirst: _currentStepIndex == 0,
                isLast: isLast,
                onPrev: () => _goToStep(_currentStepIndex - 1),
                onNext: isLast
                    ? () {
                        _logger.userAction('Cooking mode completed',
                            screen: 'CookingModePage',
                            metadata: {'recipeId': widget.recipe.id});
                        context.pop();
                      }
                    : () => _goToStep(_currentStepIndex + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onClose;

  const _TopBar(
      {required this.current,
      required this.total,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Étape $current / $total',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: AkeliColors.surfaceContainerHigh,
                color: AkeliColors.primary,
                minHeight: 6,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AkeliColors.onSurface),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final VoidCallback onToggle;

  const _TimerWidget({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final progress =
        totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CircularPercentIndicator(
          radius: 44,
          lineWidth: 6,
          percent: progress.clamp(0.0, 1.0),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.onSurface),
              ),
              Icon(
                isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AkeliColors.primary,
                size: 20,
              ),
            ],
          ),
          progressColor: AkeliColors.primary,
          backgroundColor: AkeliColors.surfaceContainerHigh,
        ),
      ),
    );
  }
}

class _IngredientStrip extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  final Set<String> checked;
  final ValueChanged<RecipeIngredient> onTap;
  final ValueChanged<RecipeIngredient> onLongPress;

  const _IngredientStrip({
    required this.ingredients,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: ingredients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final ing = ingredients[i];
          final isChecked = checked.contains(ing.ingredientId);
          return GestureDetector(
            onTap: () => onTap(ing),
            onLongPress: () => onLongPress(ing),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isChecked
                    ? AkeliColors.surfaceContainer
                    : AkeliColors.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(AkeliRadius.pill),
                border: Border.all(
                    color: isChecked
                        ? AkeliColors.outline
                        : Colors.transparent),
              ),
              child: Text(
                ing.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isChecked
                      ? AkeliColors.onSurfaceVariant
                      : AkeliColors.onSurface,
                  decoration: isChecked
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavButtons({
    required this.isFirst,
    required this.isLast,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isFirst ? null : onPrev,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                    color: isFirst
                        ? AkeliColors.outline.withValues(alpha: 0.3)
                        : AkeliColors.outline),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.lg)),
              ),
              child: Text(
                'Précédent',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: isFirst
                        ? AkeliColors.outline
                        : AkeliColors.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AkeliColors.primary,
                foregroundColor: AkeliColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.lg)),
              ),
              child: Text(
                isLast ? 'Terminer' : 'Suivant',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

> **Note:** `CookingModePage` calls `ref.onDispose()` in `initState` — remove that line; `StatefulWidget` does not have `ref`. The dispose logic is already in the `dispose()` override. Remove the `ref.onDispose(() {});` line from `initState`.

- [ ] **Step 2: Fix the stray `ref.onDispose` line in initState**

In `_CookingModePageState.initState()`, remove:
```dart
    ref.onDispose(() {});
```

The corrected `initState` is:
```dart
  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStepIndex
        .clamp(0, widget.recipe.steps.length - 1);
    _resetTimer();
    _logger.provider(
        'CookingModePage initState() | recipeId: ${widget.recipe.id} | initialStep: $_currentStepIndex');
  }
```

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/features/cooking/cooking_mode_page.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/cooking/cooking_mode_page.dart
git commit -m "feat(ui): add CookingModePage with step navigation, timer, ingredient strip"
```

---

## Task 8: Update RecipeDetailPage

**Files:**
- Modify: `lib/features/recipes/recipe_detail_page.dart`

- [ ] **Step 1: Add new imports to RecipeDetailPage**

At the top of `lib/features/recipes/recipe_detail_page.dart`, add:

```dart
import '../../shared/widgets/recipe_video_card.dart';
import '../../features/cooking/cooking_mode_page.dart';
import 'widgets/ingredient_detail_sheet.dart';
```

- [ ] **Step 2: Add video card between hero and meta card in `_RecipeContent.build()`**

In `_RecipeContent.build()`, locate the `Transform.translate` meta card (the one that starts with `Transform.translate(offset: const Offset(0, -24)...`).

Insert `RecipeVideoCard` immediately before it, inside the `Column`, guarded by null check:

```dart
// Insert after the closing `),` of the hero SizedBox and before Transform.translate
if (recipe.videoUrl != null)
  RecipeVideoCard(
    videoUrl: recipe.videoUrl!,
    thumbnailUrl: recipe.thumbnailUrl,
  ),
```

- [ ] **Step 3: Add "Start Cooking" button to the meta card**

In `_RecipeContent.build()`, locate the primary action `Container` (the gradient "Ajouter au plan repas" button). After its closing `,`, add a secondary "Start Cooking" button:

```dart
const SizedBox(height: 12),
OutlinedButton(
  onPressed: () {
    appLogger.userAction('Start Cooking tapped',
        screen: 'RecipeDetailPage',
        metadata: {'recipeId': recipe.id});
    context.push(
      '/recipe/${recipe.id}/cook',
      extra: {
        'recipe': recipe,
        'initialStepIndex': 0,
      },
    );
  },
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 52),
    side: const BorderSide(color: AkeliColors.primary),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.pill)),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.soup_kitchen_rounded,
          color: AkeliColors.primary, size: 20),
      const SizedBox(width: 12),
      Text(
        'Commencer la recette',
        style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AkeliColors.primary),
      ),
    ],
  ),
),
```

- [ ] **Step 4: Make ingredient rows tappable**

In `_RecipeContent.build()`, locate the ingredients `.map()` block. Each ingredient is currently a `Container` widget. Wrap each `Container` in an `InkWell`:

Replace:
```dart
...recipe.ingredients.map(
  (ing) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AkeliRadius.md),
      color: Colors.transparent,
    ),
    child: Row( ... ),
  ),
),
```

With:
```dart
...recipe.ingredients.map(
  (ing) => InkWell(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    onTap: () {
      appLogger.userAction('Ingredient tapped',
          screen: 'RecipeDetailPage',
          metadata: {'ingredientId': ing.ingredientId});
      IngredientDetailSheet.show(context, ing);
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              ing.name + (ing.isOptional ? ' (opt.)' : ''),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AkeliColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${ing.quantity.toStringAsFixed(ing.quantity % 1 == 0 ? 0 : 1)} ${ing.unit}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AkeliColors.accentAmber,
            ),
          ),
        ],
      ),
    ),
  ),
),
```

- [ ] **Step 5: Make step rows tappable**

In `_RecipeContent.build()`, locate the steps `.map()` block. Each step is a `Padding` wrapping a `Row`. Wrap each `Padding` in an `InkWell`:

Replace:
```dart
...recipe.steps.map(
  (step) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row( ... ),
  ),
),
```

With:
```dart
...recipe.steps.map(
  (step) => InkWell(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    onTap: () {
      appLogger.userAction('Step tapped',
          screen: 'RecipeDetailPage',
          metadata: {'stepNumber': step.stepNumber});
      context.push(
        '/recipe/${recipe.id}/cook',
        extra: {
          'recipe': recipe,
          'initialStepIndex': step.stepNumber - 1,
        },
      );
    },
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AkeliColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.stepNumber}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AkeliColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              step.instruction,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: AkeliColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
),
```

- [ ] **Step 6: Verify no analysis errors**

```bash
flutter analyze lib/features/recipes/recipe_detail_page.dart
```

Expected: No issues found.

- [ ] **Step 7: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/recipes/recipe_detail_page.dart
git commit -m "feat(ui): wire RecipeVideoCard, Start Cooking CTA, tappable ingredients/steps in RecipeDetailPage"
```

---

## Task 9: Update Router

**Files:**
- Modify: `lib/core/router.dart`

- [ ] **Step 1: Add AkeliRoutes constants**

In `lib/core/router.dart`, inside the `AkeliRoutes` abstract class, add after `static String recipeDetailPath(String id) => "/recipe/$id";`:

```dart
static const recipeCook = '/recipe/:id/cook';
static String recipeCookPath(String id) => '/recipe/$id/cook';
```

- [ ] **Step 2: Add nested cook route**

In `lib/core/router.dart`, locate the `recipeDetail` `GoRoute`. Change it from:

```dart
GoRoute(
  path: AkeliRoutes.recipeDetail,
  builder: (context, state) {
    final recipeId = state.pathParameters['id']!;
    final source = state.extra as TrackingSource? ?? TrackingSource.feed;
    return RecipeDetailPage(recipeId: recipeId, source: source);
  },
),
```

To:

```dart
GoRoute(
  path: AkeliRoutes.recipeDetail,
  builder: (context, state) {
    final recipeId = state.pathParameters['id']!;
    final source = state.extra as TrackingSource? ?? TrackingSource.feed;
    return RecipeDetailPage(recipeId: recipeId, source: source);
  },
  routes: [
    GoRoute(
      path: 'cook',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CookingModePage(
          recipe: extra['recipe'] as Recipe,
          initialStepIndex: (extra['initialStepIndex'] as int?) ?? 0,
        );
      },
    ),
  ],
),
```

- [ ] **Step 3: Add missing imports at top of router.dart**

Add:
```dart
import '../features/cooking/cooking_mode_page.dart';
```

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/core/router.dart
```

Expected: No issues found.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/core/router.dart
git commit -m "feat(router): add nested /recipe/:id/cook route for CookingModePage"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run full analysis**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Build to verify no compile errors**

```bash
flutter build apk --debug
```

Expected: Build succeeds with no errors.

- [ ] **Step 4: Final commit if any loose changes**

```bash
git status
```

If clean: done. If any unstaged changes, stage and commit them.
