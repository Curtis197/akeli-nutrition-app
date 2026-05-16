# Meal Detail & Batch Cooking UI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `MealDetailPage` to show meal components and a working consume button, and create `BatchCookingPage` listing cooking sessions with a creation stub.

**Architecture:** Three tasks — update MealDetailPage, create BatchCookingPage (self-contained file with private widgets), wire routing and MealPlannerPage nav card. All state comes from existing Riverpod providers; no new providers needed.

**Tech Stack:** Flutter, Riverpod (`ref.watch` / `ref.listen`), GoRouter, `AkeliColors` / `AkeliSpacing` / `AkeliRadius` from `lib/core/theme.dart`.

---

## File Map

| Action | File |
|---|---|
| Modify | `lib/features/meal_planner/meal_detail_page.dart` |
| Create | `lib/features/meal_planner/batch_cooking_page.dart` |
| Modify | `lib/core/router.dart` |
| Modify | `lib/features/meal_planner/meal_planner_page.dart` |

---

## Task 1 — Rewrite MealDetailPage

**Files:**
- Modify: `lib/features/meal_planner/meal_detail_page.dart`

### Context
Current file uses `activeMealPlanProvider`, resolves entry by `mealId`, then shows hardcoded ingredients and instructions. `entry.recipeTitle`, `entry.calories`, etc. now come from components via computed getters.

Relevant providers (already imported in the project):
- `activeMealPlanProvider` → `AsyncValue<MealPlan?>`
- `mealConsumptionProvider` → `AsyncNotifierProvider<MealConsumptionNotifier, void>` — call `.logConsumption(String mealPlanEntryId)`

Relevant models:
- `MealPlanEntry.isModular` → `bool` (true when `components.length > 1`)
- `MealPlanEntry.recipeId` → `String?` (base component recipe id)
- `MealPlanEntryComponent.role` → `'base' | 'starch' | 'side'`
- `MealPlanEntryComponent.isBatch` → `bool` (`cookingSessionId != null`)
- `MealPlanEntryComponent.recipeTitle` → `String?`

- [ ] **Step 1: Replace the file with the updated implementation**

Replace the full contents of `lib/features/meal_planner/meal_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/widgets/badge.dart';
import 'package:akeli/shared/widgets/section_header.dart';

class MealDetailPage extends ConsumerWidget {
  final String mealId;
  const MealDetailPage({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeMealPlanProvider);
    final consumeState = ref.watch(mealConsumptionProvider);

    ref.listen(mealConsumptionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Détail du repas'),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.error)),
        ),
        data: (plan) {
          final entry =
              plan?.entries.where((e) => e.id == mealId).firstOrNull;
          if (entry == null) {
            return const Center(child: Text('Repas introuvable'));
          }
          return _MealDetailBody(
            entry: entry,
            isConsumeLoading: consumeState.isLoading,
            onConsume: () => ref
                .read(mealConsumptionProvider.notifier)
                .logConsumption(entry.id),
          );
        },
      ),
    );
  }
}

class _MealDetailBody extends StatelessWidget {
  final MealPlanEntry entry;
  final bool isConsumeLoading;
  final VoidCallback onConsume;

  const _MealDetailBody({
    required this.entry,
    required this.isConsumeLoading,
    required this.onConsume,
  });

  @override
  Widget build(BuildContext context) {
    final hasBatch = entry.components.any((c) => c.isBatch);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image placeholder ──────────────────────────────────────
          Container(
            height: 200,
            width: double.infinity,
            color: AkeliColors.primary.withValues(alpha: 0.08),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 64)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AkeliSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + badges ─────────────────────────────────
                Text(
                  entry.recipeTitle ?? 'Repas',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                Wrap(
                  spacing: AkeliSpacing.sm,
                  children: [
                    AkeliBadge(label: entry.mealTypeLabel),
                    if (entry.isConsumed)
                      AkeliBadge(
                          label: 'Consommé ✓',
                          color: AkeliColors.success),
                    if (entry.isModular)
                      AkeliBadge(
                          label: 'Modulaire',
                          color: AkeliColors.primaryContainer),
                  ],
                ),

                // ── Components (modular only) ──────────────────────
                if (entry.isModular) ...[
                  const SizedBox(height: AkeliSpacing.lg),
                  const AkeliSectionHeader(title: 'Composants'),
                  const SizedBox(height: AkeliSpacing.sm),
                  Wrap(
                    spacing: AkeliSpacing.sm,
                    runSpacing: AkeliSpacing.sm,
                    children: entry.components
                        .map((c) => _ComponentChip(component: c))
                        .toList(),
                  ),
                ],

                // ── Macros ─────────────────────────────────────────
                const SizedBox(height: AkeliSpacing.lg),
                const AkeliSectionHeader(title: 'Macronutriments'),
                const SizedBox(height: AkeliSpacing.sm),
                Wrap(
                  spacing: AkeliSpacing.sm,
                  runSpacing: AkeliSpacing.sm,
                  children: [
                    AkeliMacroBadge(
                        label: 'Glucides',
                        value: '${entry.carbsG.toInt()}g',
                        type: MacroType.carbs),
                    AkeliMacroBadge(
                        label: 'Protéines',
                        value: '${entry.proteinG.toInt()}g',
                        type: MacroType.protein),
                    AkeliMacroBadge(
                        label: 'Graisses',
                        value: '${entry.fatG.toInt()}g',
                        type: MacroType.fat),
                    AkeliMacroBadge(
                        label: 'Calories',
                        value: '${entry.calories.toInt()}',
                        type: MacroType.kcal),
                  ],
                ),

                // ── Links ──────────────────────────────────────────
                const SizedBox(height: AkeliSpacing.lg),
                if (entry.recipeId != null)
                  _LinkRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Voir la recette',
                    onTap: () => context
                        .push(AkeliRoutes.recipeDetailPath(entry.recipeId!)),
                  ),
                if (hasBatch) ...[
                  const SizedBox(height: AkeliSpacing.sm),
                  _LinkRow(
                    icon: Icons.soup_kitchen_outlined,
                    label: 'Voir le batch cooking',
                    onTap: () => context.push(AkeliRoutes.batchCooking),
                  ),
                ],

                // ── Consume button ─────────────────────────────────
                if (!entry.isConsumed) ...[
                  const SizedBox(height: AkeliSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isConsumeLoading ? null : onConsume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AkeliColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AkeliSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.md),
                        ),
                      ),
                      child: isConsumeLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Marquer comme consommé',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentChip extends StatelessWidget {
  final MealPlanEntryComponent component;
  const _ComponentChip({required this.component});

  IconData get _icon {
    switch (component.role) {
      case 'starch':
        return Icons.grain;
      case 'side':
        return Icons.eco_outlined;
      default:
        return Icons.restaurant;
    }
  }

  String get _roleLabel {
    switch (component.role) {
      case 'base':
        return 'Base';
      case 'starch':
        return 'Féculent';
      case 'side':
        return 'Accompagnement';
      default:
        return component.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.sm),
        border: Border.all(color: AkeliColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: AkeliColors.primary),
          const SizedBox(width: 4),
          Text(
            '${component.recipeTitle ?? _roleLabel} · $_roleLabel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AkeliColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (component.isBatch) ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AkeliColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BATCH',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AkeliColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkeliRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AkeliColors.primary),
            const SizedBox(width: AkeliSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AkeliColors.outline),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```
dart analyze lib/features/meal_planner/meal_detail_page.dart
```

Expected: no errors (warnings about `AkeliRadius.sm` or similar are OK if `sm` exists in theme — check `lib/core/theme.dart` for `AkeliRadius` constants and substitute with the correct one if needed).

- [ ] **Step 3: Commit**

```
git add lib/features/meal_planner/meal_detail_page.dart
git commit -m "feat(ui): update MealDetailPage with components view and consume button"
```

---

## Task 2 — Create BatchCookingPage

**Files:**
- Create: `lib/features/meal_planner/batch_cooking_page.dart`

### Context
Providers available (already in `meal_plan_provider.dart`):
- `cookingSessionsProvider` → `AsyncValue<List<CookingSession>>`
- `cookingSessionNotifierProvider` — `create({mealPlanId, recipeId, plannedDate, totalPortions, notes})` — **session creation is stubbed** (disabled button) because no recipe picker exists yet.

Model: `CookingSession` fields — `id`, `recipeTitle`, `recipeThumbnail`, `plannedDate`, `totalPortions`, `portionsUsed`, `portionsAvailable`, `hasAvailablePortions`.

- [ ] **Step 1: Create the file**

Create `lib/features/meal_planner/batch_cooking_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/models/meal_plan.dart';

class BatchCookingPage extends ConsumerWidget {
  const BatchCookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(cookingSessionsProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Batch Cooking'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSessionSheet(context),
        backgroundColor: AkeliColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.error)),
        ),
        data: (sessions) => sessions.isEmpty
            ? _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AkeliSpacing.md, AkeliSpacing.md, AkeliSpacing.md, 100),
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AkeliSpacing.sm),
                itemBuilder: (_, i) =>
                    _CookingSessionCard(session: sessions[i]),
              ),
      ),
    );
  }

  void _showCreateSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AkeliSpacing.lg,
          AkeliSpacing.lg,
          AkeliSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AkeliSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle session',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AkeliSpacing.md),
            Container(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              decoration: BoxDecoration(
                color: AkeliColors.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AkeliRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AkeliColors.primary, size: 18),
                  const SizedBox(width: AkeliSpacing.sm),
                  Expanded(
                    child: Text(
                      'La création de sessions batch sera disponible prochainement avec le sélecteur de recettes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AkeliColors.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  disabledBackgroundColor:
                      AkeliColors.surfaceContainerHighest,
                  padding:
                      const EdgeInsets.symmetric(vertical: AkeliSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AkeliRadius.md)),
                ),
                child: Text('Bientôt disponible',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AkeliColors.outline,
                          fontWeight: FontWeight.w700,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkeliSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍲', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AkeliSpacing.md),
            Text(
              'Aucune session cette semaine',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkeliSpacing.sm),
            Text(
              'Appuyez sur + pour créer votre première session batch.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CookingSessionCard extends StatelessWidget {
  final CookingSession session;
  const _CookingSessionCard({required this.session});

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]}.';
  }

  @override
  Widget build(BuildContext context) {
    final progress = session.totalPortions > 0
        ? session.portionsUsed / session.totalPortions
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AkeliRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Recipe image / emoji
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AkeliColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AkeliRadius.sm),
            ),
            child: session.recipeThumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AkeliRadius.sm),
                    child: Image.network(session.recipeThumbnail!,
                        fit: BoxFit.cover),
                  )
                : const Center(
                    child: Text('🍲', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: AkeliSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.recipeTitle ?? 'Recette',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(session.plannedDate)} · ${session.totalPortions} portions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AkeliColors.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              AkeliColors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            session.hasAvailablePortions
                                ? AkeliColors.primary
                                : AkeliColors.outline,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.sm),
                    Text(
                      '${session.portionsUsed}/${session.totalPortions}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```
dart analyze lib/features/meal_planner/batch_cooking_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```
git add lib/features/meal_planner/batch_cooking_page.dart
git commit -m "feat(ui): add BatchCookingPage with session list and stubbed creation"
```

---

## Task 3 — Wire routing and MealPlannerPage nav card

**Files:**
- Modify: `lib/core/router.dart`
- Modify: `lib/features/meal_planner/meal_planner_page.dart`

### Context
`AkeliRoutes` is an abstract class in `router.dart`. GoRouter routes are defined in `routerProvider`. `MealPlannerPage._buildNavigationCard` accepts `icon`, `title`, `onTap`.

- [ ] **Step 1: Add route constant and GoRoute in router.dart**

In `lib/core/router.dart`:

1. Add the import at the top with other meal planner imports:
```dart
import '../features/meal_planner/batch_cooking_page.dart';
```

2. Add the constant inside `AkeliRoutes`:
```dart
static const batchCooking = "/batch-cooking";
```

3. Add the `GoRoute` **before** the `ShellRoute` block (alongside other non-shell routes like `mealDetail`):
```dart
GoRoute(
  path: AkeliRoutes.batchCooking,
  builder: (context, state) => const BatchCookingPage(),
),
```

- [ ] **Step 2: Add the nav card in MealPlannerPage**

In `lib/features/meal_planner/meal_planner_page.dart`, in the `// ── QUICK ACTIONS ───` section, after the existing shopping list card, add:

```dart
const SizedBox(height: 12),
_buildNavigationCard(
  context,
  icon: Icons.soup_kitchen_outlined,
  title: 'Batch Cooking',
  onTap: () => context.push(AkeliRoutes.batchCooking),
),
```

- [ ] **Step 3: Verify full analysis**

```
dart analyze lib
```

Expected: 0 errors (existing warnings about `const` or dead null-aware expressions in unrelated files are OK).

- [ ] **Step 4: Commit**

```
git add lib/core/router.dart lib/features/meal_planner/meal_planner_page.dart
git commit -m "feat(ui): add /batch-cooking route and MealPlannerPage nav card"
```

---

## Self-Review

**Spec coverage:**
- ✅ MealDetailPage: components section (isModular gate), macros, consume button with loading, "Voir la recette" link, "Voir le batch cooking" link
- ✅ BatchCookingPage: list of sessions, empty state, FAB, creation stub with info banner
- ✅ CookingSessionCard: image/emoji, title, date, portions progress bar
- ✅ Route `/batch-cooking` added
- ✅ MealPlannerPage third nav card added
- ✅ Entry from MealDetailPage via "Voir le batch cooking" link

**Placeholder scan:** No TBDs. Creation stub is an explicit design decision with a visible "Bientôt disponible" UI, not a missing implementation.

**Type consistency:**
- `mealConsumptionProvider.notifier.logConsumption(String mealPlanEntryId)` — matches updated provider signature.
- `cookingSessionsProvider` → `List<CookingSession>` — matches model.
- `AkeliRadius.card`, `AkeliRadius.md`, `AkeliRadius.sm` — verify these exist in `lib/core/theme.dart` before running; if only `card` and `md` exist, substitute `sm` with `md`.
- `AkeliColors.secondaryContainer` — defined in theme as `Color(0xFFC3EAE5)`. ✅
