# Meal Consumption Rating — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 4-dimension optional rating bottom sheet (overall + taste/ease/satiety) that appears immediately after a meal is marked consumed, gated entirely behind `meal_plan_entry.is_consumed`.

**Architecture:** A new DB migration adds three nullable rating columns to `meal_consumption`. A new `rate-meal-consumption` edge function validates ownership + consumed state before writing ratings. The Flutter side changes `MealConsumptionNotifier` to return `bool` so `MealDetailPage` can trigger the `RatingBottomSheet` on success.

**Tech Stack:** Flutter/Riverpod, Supabase Edge Functions (Deno/TypeScript), PostgreSQL.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260529000005_add_rating_dimensions_to_consumption.sql` | Add `rating_taste`, `rating_ease`, `rating_satiety` columns |
| Create | `supabase/functions/rate-meal-consumption/index.ts` | Edge function: validate + write rating |
| Modify | `lib/providers/meal_plan_provider.dart` | Change `MealConsumptionNotifier` to `AsyncNotifier<bool>`; add `RatingNotifier` |
| Create | `lib/features/meal_planner/rating_bottom_sheet.dart` | Rating UI widget |
| Create | `tests/widgets/rating_bottom_sheet_test.dart` | Widget tests |
| Modify | `lib/features/meal_planner/meal_detail_page.dart` | Import sheet, update listener to show sheet on consumed |

---

## Task 1: DB Migration — Rating Dimension Columns

**Files:**
- Create: `supabase/migrations/20260529000005_add_rating_dimensions_to_consumption.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260529000005_add_rating_dimensions_to_consumption.sql
-- Add optional sub-dimension rating columns to meal_consumption.
-- The existing `rating` column (overall, feeds recipe.average_rating via trigger)
-- is unchanged. These three are nullable and never aggregated publicly.

ALTER TABLE public.meal_consumption
  ADD COLUMN IF NOT EXISTS rating_taste   integer CHECK (rating_taste   BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_ease    integer CHECK (rating_ease    BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_satiety integer CHECK (rating_satiety BETWEEN 1 AND 5);
```

- [ ] **Step 2: Verify SQL is valid**

Open the file and confirm three `ADD COLUMN IF NOT EXISTS` statements, each with a `CHECK` constraint using `BETWEEN 1 AND 5`.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260529000005_add_rating_dimensions_to_consumption.sql
git commit -m "feat(db): add rating_taste, rating_ease, rating_satiety to meal_consumption"
```

---

## Task 2: Edge Function — `rate-meal-consumption`

**Files:**
- Create: `supabase/functions/rate-meal-consumption/index.ts`

- [ ] **Step 1: Create the edge function**

```typescript
// supabase/functions/rate-meal-consumption/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("rate-meal-consumption");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: unauthorized");
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parsing request body");
    const body = await req.json();
    const { meal_plan_entry_id, rating, rating_taste, rating_ease, rating_satiety } = body;
    logger.debug("[STEP 1] Body parsed", { meal_plan_entry_id, rating });

    if (!meal_plan_entry_id) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry_id missing");
      return err("meal_plan_entry_id is required");
    }
    if (rating == null || rating < 1 || rating > 5) {
      logger.warn("EARLY RETURN | reason: invalid rating | value: " + rating);
      return err("rating must be an integer between 1 and 5");
    }
    for (const [key, val] of [["rating_taste", rating_taste], ["rating_ease", rating_ease], ["rating_satiety", rating_satiety]] as [string, unknown][]) {
      if (val != null && (typeof val !== "number" || val < 1 || val > 5)) {
        logger.warn("EARLY RETURN | reason: invalid " + key + " | value: " + val);
        return err(key + " must be an integer between 1 and 5 if provided");
      }
    }

    logger.debug("[STEP 2] Verify meal_plan_entry ownership and consumed state");
    logRLSCheck(logger, "meal_plan_entry", "SELECT", user.id);
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("id, is_consumed")
      .eq("id", meal_plan_entry_id)
      .maybeSingle();
    logQueryResult(logger, "meal_plan_entry", "SELECT", entry ? 1 : 0, entryError ?? undefined);

    if (entryError || !entry) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry not found | id: " + meal_plan_entry_id);
      return err("Meal plan entry not found", 404);
    }
    if (!entry.is_consumed) {
      logger.warn("EARLY RETURN | reason: meal_not_consumed | id: " + meal_plan_entry_id);
      return err("meal_not_consumed", 403);
    }

    logger.debug("[STEP 3] Update meal_consumption rating columns");
    const admin = serviceClient();
    logRLSCheck(logger, "meal_consumption", "UPDATE", user.id);
    const { error: updateError } = await admin
      .from("meal_consumption")
      .update({
        rating,
        rating_taste: rating_taste ?? null,
        rating_ease: rating_ease ?? null,
        rating_satiety: rating_satiety ?? null,
      })
      .eq("meal_plan_entry_id", meal_plan_entry_id);
    logQueryResult(logger, "meal_consumption", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);

    if (updateError) throw updateError;

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ rated: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Verify the file matches CLAUDE.md logging standard**

Check:
- `createLogger("rate-meal-consumption")` at top ✓
- `logger.info("⚡ ENTRY | method: ...")` first line ✓
- `logger.setUserId(user.id)` after auth ✓
- Every step labelled `[STEP N]` ✓
- `logRLSCheck` before every DB op ✓
- `logQueryResult` after every DB op ✓
- Every early return has `logger.warn("EARLY RETURN | reason: ...")` ✓
- `logger.info("✅ EXIT | ...")` before `return ok(...)` ✓
- Catch-all `logger.error("💥 Unhandled error", ...)` ✓

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/rate-meal-consumption/index.ts
git commit -m "feat(edge): add rate-meal-consumption edge function"
```

---

## Task 3: Provider Changes — `MealConsumptionNotifier` + `RatingNotifier`

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart`

**Context:** `MealConsumptionNotifier` currently extends `AutoDisposeAsyncNotifier<void>`. We change it to `AutoDisposeAsyncNotifier<bool>` so `MealDetailPage` can react to `AsyncData(true)` to show the rating sheet. We then add `RatingNotifier` at the end of the file.

- [ ] **Step 1: Change `MealConsumptionNotifier` type parameter from `void` to `bool`**

Find the block at lines ~303-339 and replace it entirely:

```dart
// ---------------------------------------------------------------------------
// Log meal consumption — Edge Function
// Logs all components of a meal entry in one call.
// Returns true on success so MealDetailPage can trigger the rating sheet.
// ---------------------------------------------------------------------------

class MealConsumptionNotifier extends AutoDisposeAsyncNotifier<bool> {
  final _logger = appLogger;

  @override
  FutureOr<bool> build() {
    _logger.provider('MealConsumptionNotifier build()');
    ref.onDispose(() => _logger.provider('MealConsumptionNotifier disposed'));
    return false;
  }

  Future<void> logConsumption(String mealPlanEntryId) async {
    _logger.userAction('Log meal consumption', metadata: {'mealPlanEntryId': mealPlanEntryId});
    _logger.edge('log-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
    _logger.provider('MealConsumptionNotifier → loading');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'log-meal-consumption',
          body: {'meal_plan_entry_id': mealPlanEntryId},
        );
        _logger.edge('log-meal-consumption', 'AFTER | success');
        _logger.provider('MealConsumptionNotifier → data (true)');
        return true;
      } catch (e, st) {
        _logger.edge('log-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('MealConsumptionNotifier → error | $e');
        rethrow;
      }
    });
    if (state is AsyncData) ref.invalidate(activeMealPlanProvider);
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, bool>(
        MealConsumptionNotifier.new);
```

- [ ] **Step 2: Add `RatingNotifier` at the end of `meal_plan_provider.dart` (before any final closing)**

```dart
// ---------------------------------------------------------------------------
// Rate meal consumption — Edge Function
// Writes overall + optional sub-dimension ratings to meal_consumption rows.
// Only callable after the meal has been marked consumed.
// ---------------------------------------------------------------------------

class RatingNotifier extends AutoDisposeAsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('RatingNotifier build()');
    ref.onDispose(() => _logger.provider('RatingNotifier disposed'));
  }

  Future<void> submitRating(
    String mealPlanEntryId, {
    required int rating,
    int? ratingTaste,
    int? ratingEase,
    int? ratingSatiety,
  }) async {
    _logger.userAction('Submit meal rating', metadata: {
      'mealPlanEntryId': mealPlanEntryId,
      'rating': rating,
      'ratingTaste': ratingTaste,
      'ratingEase': ratingEase,
      'ratingSatiety': ratingSatiety,
    });
    _logger.edge('rate-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId | rating: $rating');
    _logger.provider('RatingNotifier → loading');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'rate-meal-consumption',
          body: {
            'meal_plan_entry_id': mealPlanEntryId,
            'rating': rating,
            if (ratingTaste != null) 'rating_taste': ratingTaste,
            if (ratingEase != null) 'rating_ease': ratingEase,
            if (ratingSatiety != null) 'rating_satiety': ratingSatiety,
          },
        );
        _logger.edge('rate-meal-consumption', 'AFTER | success');
        _logger.provider('RatingNotifier → data (submitRating success)');
      } catch (e, st) {
        _logger.edge('rate-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('RatingNotifier → error | $e');
        rethrow;
      }
    });
  }
}

final ratingProvider =
    AsyncNotifierProvider.autoDispose<RatingNotifier, void>(RatingNotifier.new);
```

- [ ] **Step 3: Run `flutter analyze` and fix any type errors**

```bash
flutter analyze lib/providers/meal_plan_provider.dart
```

Expected: no errors. If you see `AsyncNotifier<void>` vs `AsyncNotifier<bool>` mismatch warnings, recheck the provider declaration line matches the class type parameter.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/meal_plan_provider.dart
git commit -m "feat(provider): MealConsumptionNotifier returns bool; add RatingNotifier"
```

---

## Task 4: `RatingBottomSheet` Widget + Tests

**Files:**
- Create: `lib/features/meal_planner/rating_bottom_sheet.dart`
- Create: `tests/widgets/rating_bottom_sheet_test.dart`

- [ ] **Step 1: Write the failing widget tests first**

```dart
// tests/widgets/rating_bottom_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/rating_bottom_sheet.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

class _MockRatingNotifier extends RatingNotifier {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> submitRating(
    String mealPlanEntryId, {
    required int rating,
    int? ratingTaste,
    int? ratingEase,
    int? ratingSatiety,
  }) async {}
}

Widget _buildSheet() => ProviderScope(
      overrides: [ratingProvider.overrideWith(_MockRatingNotifier.new)],
      child: const MaterialApp(
        home: Scaffold(
          body: RatingBottomSheet(mealPlanEntryId: 'test-entry-id'),
        ),
      ),
    );

void main() {
  group('RatingBottomSheet', () {
    testWidgets('submit button is disabled initially', (tester) async {
      await tester.pumpWidget(_buildSheet());

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Soumettre'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('submit button enabled after tapping an overall star', (tester) async {
      await tester.pumpWidget(_buildSheet());

      await tester.tap(find.byKey(const Key('overall-star-4')));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Soumettre'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('renders three optional dimension rows', (tester) async {
      await tester.pumpWidget(_buildSheet());

      expect(find.text('Goût'), findsOneWidget);
      expect(find.text('Facilité'), findsOneWidget);
      expect(find.text('Satiété'), findsOneWidget);
    });

    testWidgets('Passer button is present and tappable', (tester) async {
      await tester.pumpWidget(_buildSheet());

      expect(find.widgetWithText(TextButton, 'Passer'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Passer'));
      await tester.pump();
      // No exception = pass
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure (widget not yet created)**

```bash
flutter test tests/widgets/rating_bottom_sheet_test.dart
```

Expected output: `Error: Could not find package 'akeli'` or `Target file not found` — the widget file does not exist yet. This confirms the test is wired correctly.

- [ ] **Step 3: Create the `RatingBottomSheet` widget**

```dart
// lib/features/meal_planner/rating_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';

class RatingBottomSheet extends ConsumerStatefulWidget {
  final String mealPlanEntryId;

  const RatingBottomSheet({super.key, required this.mealPlanEntryId});

  @override
  ConsumerState<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<RatingBottomSheet> {
  final _logger = appLogger;

  int? _rating;
  int? _ratingTaste;
  int? _ratingEase;
  int? _ratingSatiety;

  Future<void> _submit() async {
    if (_rating == null) return;
    _logger.userAction('Rating submit tapped', screen: 'RatingBottomSheet', metadata: {
      'mealPlanEntryId': widget.mealPlanEntryId,
      'rating': _rating,
    });
    await ref.read(ratingProvider.notifier).submitRating(
          widget.mealPlanEntryId,
          rating: _rating!,
          ratingTaste: _ratingTaste,
          ratingEase: _ratingEase,
          ratingSatiety: _ratingSatiety,
        );
    if (mounted && ref.read(ratingProvider).hasValue && !ref.read(ratingProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(ratingProvider);
    final isLoading = ratingState.isLoading;

    ref.listen(ratingProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AkeliColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Comment était ce repas ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 24),
          Center(
            child: _StarRow(
              value: _rating,
              iconSize: 36,
              keyPrefix: 'overall',
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 28),
          _DimensionRow(
            label: 'Goût',
            value: _ratingTaste,
            onChanged: (v) => setState(() => _ratingTaste = v),
          ),
          const SizedBox(height: 16),
          _DimensionRow(
            label: 'Facilité',
            value: _ratingEase,
            onChanged: (v) => setState(() => _ratingEase = v),
          ),
          const SizedBox(height: 16),
          _DimensionRow(
            label: 'Satiété',
            value: _ratingSatiety,
            onChanged: (v) => setState(() => _ratingSatiety = v),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: isLoading ? null : () {
                  _logger.userAction('Rating skipped', screen: 'RatingBottomSheet');
                  Navigator.of(context).pop();
                },
                child: const Text('Passer'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (_rating == null || isLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.pill),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Soumettre', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int? value;
  final double iconSize;
  final String keyPrefix;
  final ValueChanged<int> onChanged;

  const _StarRow({
    required this.value,
    required this.iconSize,
    required this.keyPrefix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= (value ?? 0);
        return GestureDetector(
          key: Key('$keyPrefix-star-$star'),
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: iconSize,
              color: filled ? AkeliColors.secondary : AkeliColors.outline,
            ),
          ),
        );
      }),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int> onChanged;

  const _DimensionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AkeliColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        _StarRow(
          value: value,
          iconSize: 22,
          keyPrefix: label.toLowerCase(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test tests/widgets/rating_bottom_sheet_test.dart
```

Expected output:
```
00:0x +4: All tests passed!
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/rating_bottom_sheet.dart tests/widgets/rating_bottom_sheet_test.dart
git commit -m "feat(ui): add RatingBottomSheet with 4-dimension star rating"
```

---

## Task 5: Wire `MealDetailPage` — Show Sheet on Consumption Success

**Files:**
- Modify: `lib/features/meal_planner/meal_detail_page.dart`

- [ ] **Step 1: Add import at the top of `meal_detail_page.dart`**

After the existing imports, add:

```dart
import 'rating_bottom_sheet.dart';
```

- [ ] **Step 2: Replace the `ref.listen(mealConsumptionProvider, ...)` block**

Find the existing listener (currently only handles errors):

```dart
ref.listen(mealConsumptionProvider, (_, next) {
  if (next.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(next.error.toString()),
      backgroundColor: AkeliColors.error,
    ));
  }
});
```

Replace with:

```dart
ref.listen(mealConsumptionProvider, (_, next) {
  if (next.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(next.error.toString()),
      backgroundColor: AkeliColors.error,
    ));
  } else if (next.valueOrNull == true) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(mealPlanEntryId: mealId),
    );
  }
});
```

- [ ] **Step 3: Run `flutter analyze` on the changed file**

```bash
flutter analyze lib/features/meal_planner/meal_detail_page.dart
```

Expected: no errors. Common issue: `mealId` may need to be in scope — it is, since `MealDetailPage.mealId` is the constructor parameter and it's referenced in the `build` method body.

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```

Expected: all tests pass. The changed `mealConsumptionProvider` type (`void` → `bool`) has no other call sites that access `.value`, so no cascading failures expected.

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/meal_detail_page.dart
git commit -m "feat(ui): show RatingBottomSheet after meal consumption"
```

---

## Task 6: Apply Migration to Supabase

**Files:** (no code changes — deployment step)

- [ ] **Step 1: Apply migration to remote Supabase project**

```bash
supabase db push
```

Expected output includes:
```
Applying migration 20260529000005_add_rating_dimensions_to_consumption.sql...
```

If `supabase db push` is not available locally, apply via Supabase MCP:
```
mcp__claude_ai_Supabase__apply_migration with the SQL from migration 20260529000005
```

- [ ] **Step 2: Deploy the edge function**

```bash
supabase functions deploy rate-meal-consumption
```

Expected: `Deployed rate-meal-consumption`

- [ ] **Step 3: Verify the function appears in the Supabase dashboard under Edge Functions**

- [ ] **Step 4: Final commit (if any leftover staged changes)**

```bash
git status
# If clean, no commit needed. If any config/lock files changed:
git add <changed files>
git commit -m "chore: post-deploy cleanup"
```

---

## Self-Review Checklist

- [x] **Task 1** covers spec requirement: add `rating_taste`, `rating_ease`, `rating_satiety` columns
- [x] **Task 2** covers spec requirement: edge function validates consumed gate + writes all 4 rating columns
- [x] **Task 3** covers spec requirement: `MealConsumptionNotifier` returns `bool`; `RatingNotifier` calls edge function
- [x] **Task 4** covers spec requirement: bottom sheet UI with overall (required) + 3 optional dimensions; `isDismissible: false`; Passer/Soumettre actions
- [x] **Task 5** covers spec requirement: sheet triggered from `MealDetailPage` only on `AsyncData(true)` (consumed this session)
- [x] **Task 6** covers deployment of migration + function
- [x] Type consistency: `mealConsumptionProvider` declared as `AsyncNotifierProvider<MealConsumptionNotifier, bool>` in Task 3 and consumed as `bool` in Task 5 ✓
- [x] Method signatures: `submitRating(String, {required int, int?, int?, int?})` consistent across Task 3 definition and Task 4 call site ✓
- [x] `Key('overall-star-N')` used in widget (Task 4 step 3) matches keys expected in tests (Task 4 step 1) ✓
- [x] No TBDs, no placeholder steps ✓
