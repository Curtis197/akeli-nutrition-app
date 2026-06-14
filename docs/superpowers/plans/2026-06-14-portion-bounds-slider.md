# Portion Bounds Slider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional, per-meal-type RangeSlider to `NutritionPlanPage` so users can set `min_portion_g` / `max_portion_g` for each meal, saving them into `meal_distribution` which the generator already reads.

**Architecture:** Single file change — `NutritionPlanPage`. Each meal distribution row gains a collapsible `_PortionBoundsPanel` (stateless `RangeSlider` widget) toggled by a `_BoundsChip`. Expand state lives in a `Set<int>` on `NutritionPlanPageState`. No provider, DB, or RPC changes needed.

**Tech Stack:** Flutter / Riverpod, `RangeSlider` (Flutter material), Supabase MCP (`execute_sql`) for DB + RPC testing.

---

## File Map

| File | Change |
|------|--------|
| `lib/features/nutrition_plan/nutrition_plan_page.dart` | Add `_expandedBoundsIndices`, `_updateSlotBounds()`, `_BoundsChip`, `_PortionBoundsPanel`; update meal row build |

No other files require changes.

---

### Task 1: Add expand-state tracker and `_updateSlotBounds()` to `NutritionPlanPageState`

**Files:**
- Modify: `lib/features/nutrition_plan/nutrition_plan_page.dart`

- [ ] **Step 1: Add `_expandedBoundsIndices` field**

In `NutritionPlanPageState`, after the existing `bool _isSaving = false;` field (line ~61), add:

```dart
final Set<int> _expandedBoundsIndices = {};
```

- [ ] **Step 2: Add `_updateSlotBounds()` method**

After the existing `_updateSlotPct()` method (~line 201), add:

```dart
void _updateSlotBounds(int index, int minG, int maxG) {
  _logger.userAction('Portion bounds changed', screen: 'NutritionPlanPage',
      metadata: {'index': index, 'minG': minG, 'maxG': maxG});
  setState(() {
    final updated = [..._distributions];
    updated[index] = updated[index].copyWith(minPortionG: minG, maxPortionG: maxG);
    _distributions = updated;
  });
}
```

- [ ] **Step 3: Clear expanded state when distributions reset**

In `_calculateResults()`, after `_distributions = newDistributions;` inside the `setState` call, add:

```dart
_expandedBoundsIndices.clear();
```

- [ ] **Step 4: Shift expanded indices when a slot is removed**

Replace the body of `_removeMealSlot(int index)` with:

```dart
void _removeMealSlot(int index) {
  _logger.userAction('Remove meal slot tapped | index: $index', screen: 'NutritionPlanPage');
  setState(() {
    _distributions = [..._distributions]..removeAt(index);
    _expandedBoundsIndices.remove(index);
    final shifted = _expandedBoundsIndices
        .where((i) => i > index)
        .map((i) => i - 1)
        .toSet();
    _expandedBoundsIndices.removeWhere((i) => i > index);
    _expandedBoundsIndices.addAll(shifted);
  });
}
```

- [ ] **Step 5: Verify the app still compiles**

```bash
flutter analyze lib/features/nutrition_plan/nutrition_plan_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart
git commit -m "feat(nutrition-plan): add portion bounds state + updateSlotBounds()"
```

---

### Task 2: Add `_BoundsChip` private widget

**Files:**
- Modify: `lib/features/nutrition_plan/nutrition_plan_page.dart`

- [ ] **Step 1: Add `_BoundsChip` at the bottom of the file, before the closing brace**

```dart
class _BoundsChip extends StatelessWidget {
  final int minG;
  final int maxG;
  final bool expanded;
  final VoidCallback onTap;

  const _BoundsChip({
    required this.minG,
    required this.maxG,
    required this.expanded,
    required this.onTap,
  });

  bool get _isCustom => minG != 50 || maxG != 1500;

  @override
  Widget build(BuildContext context) {
    final color = _isCustom ? AkeliColors.primary : AkeliColors.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _isCustom
              ? AkeliColors.primaryContainer
              : AkeliColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              '$minG–${maxG}g',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 13,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/features/nutrition_plan/nutrition_plan_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart
git commit -m "feat(nutrition-plan): add _BoundsChip widget"
```

---

### Task 3: Add `_PortionBoundsPanel` private widget

**Files:**
- Modify: `lib/features/nutrition_plan/nutrition_plan_page.dart`

- [ ] **Step 1: Add `_PortionBoundsPanel` at the bottom of the file**

```dart
class _PortionBoundsPanel extends StatelessWidget {
  final int minG;
  final int maxG;
  final void Function(int minG, int maxG) onChanged;

  const _PortionBoundsPanel({
    required this.minG,
    required this.maxG,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.fromLTRB(
          AkeliSpacing.md, AkeliSpacing.sm, AkeliSpacing.md, AkeliSpacing.sm),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUANTITÉ DE PORTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurfaceVariant,
              letterSpacing: 0.08,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AkeliColors.secondaryContainer,
              inactiveTrackColor: AkeliColors.surfaceContainerHighest,
              thumbColor: AkeliColors.surfaceContainerLowest,
              overlayColor: AkeliColors.primary.withValues(alpha: 0.1),
              trackHeight: 8,
            ),
            child: RangeSlider(
              values: RangeValues(minG.toDouble(), maxG.toDouble()),
              min: 50,
              max: 1500,
              divisions: 58, // step = (1500 - 50) / 58 = 25g
              onChanged: (v) => onChanged(v.start.round(), v.end.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min : $minG g',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AkeliColors.onSurfaceVariant),
              ),
              Text(
                'Max : $maxG g',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AkeliColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/features/nutrition_plan/nutrition_plan_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart
git commit -m "feat(nutrition-plan): add _PortionBoundsPanel RangeSlider widget"
```

---

### Task 4: Wire the chip and panel into each meal distribution row

**Files:**
- Modify: `lib/features/nutrition_plan/nutrition_plan_page.dart`

The existing meal row (lines ~423–468) is a bare `Row(...)`. Replace the entire `.asMap().entries.map(...)` block with the version below.

- [ ] **Step 1: Replace the meal distribution row builder**

Find this block (inside the `if (_isCalculated) ...` section):

```dart
..._distributions.asMap().entries.map((entry) {
  final i = entry.key;
  final dist = entry.value;
  final kcal = (_calorieGoal * (dist.caloriePct / 100)).round();
  return Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(_mealLabel(dist.mealType),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        color: dist.caloriePct > 0 ? AkeliColors.primary : Colors.grey,
        onPressed: dist.caloriePct > 0 ? () => _updateSlotPct(i, dist.caloriePct - 1) : null,
      ),
      Expanded(
        child: Center(
          child: Text(
            '${dist.caloriePct.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AkeliColors.primary,
            ),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        color: dist.caloriePct < 100 ? AkeliColors.primary : Colors.grey,
        onPressed: dist.caloriePct < 100 ? () => _updateSlotPct(i, dist.caloriePct + 1) : null,
      ),
      SizedBox(
        width: 65,
        child: Text('$kcal kcal',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.right),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
        onPressed: _distributions.length > 1 ? () => _removeMealSlot(i) : null,
      ),
    ],
  );
}),
```

Replace it with:

```dart
..._distributions.asMap().entries.map((entry) {
  final i = entry.key;
  final dist = entry.value;
  final kcal = (_calorieGoal * (dist.caloriePct / 100)).round();
  final expanded = _expandedBoundsIndices.contains(i);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(_mealLabel(dist.mealType),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: dist.caloriePct > 0 ? AkeliColors.primary : Colors.grey,
            onPressed: dist.caloriePct > 0 ? () => _updateSlotPct(i, dist.caloriePct - 1) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${dist.caloriePct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.primary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: dist.caloriePct < 100 ? AkeliColors.primary : Colors.grey,
            onPressed: dist.caloriePct < 100 ? () => _updateSlotPct(i, dist.caloriePct + 1) : null,
          ),
          SizedBox(
            width: 65,
            child: Text('$kcal kcal',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right),
          ),
          _BoundsChip(
            minG: dist.minPortionG,
            maxG: dist.maxPortionG,
            expanded: expanded,
            onTap: () {
              _logger.userAction('Bounds chip tapped', screen: 'NutritionPlanPage',
                  metadata: {'index': i, 'expanded': !expanded});
              setState(() {
                if (expanded) {
                  _expandedBoundsIndices.remove(i);
                } else {
                  _expandedBoundsIndices.add(i);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: _distributions.length > 1 ? () => _removeMealSlot(i) : null,
          ),
        ],
      ),
      if (expanded)
        _PortionBoundsPanel(
          minG: dist.minPortionG,
          maxG: dist.maxPortionG,
          onChanged: (min, max) => _updateSlotBounds(i, min, max),
        ),
    ],
  );
}),
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/features/nutrition_plan/nutrition_plan_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart
git commit -m "feat(nutrition-plan): wire bounds chip + panel into meal distribution rows"
```

---

### Task 5: Manual smoke test

- [ ] **Step 1: Run the app**

```bash
flutter run
```

- [ ] **Step 2: Navigate to Settings → Suivi nutritionnel**

Verify: Each meal row (Petit-déjeuner, Déjeuner, Dîner) shows a muted `⚙ 50–1500g ▾` chip on the right.

- [ ] **Step 3: Tap the chip on "Petit-déjeuner"**

Verify: Panel expands below the row. RangeSlider appears with both handles at the extremes (50g / 1500g). Min and Max labels show `50 g` and `1500 g`.

- [ ] **Step 4: Drag the left handle to ~200g, right handle to ~600g**

Verify:
- Min label updates to `200 g`, Max label to `600 g`
- Chip label updates to `200–600g`
- Chip turns `AkeliColors.primaryContainer` background

- [ ] **Step 5: Tap the chip again**

Verify: Panel collapses. Chip still shows `200–600g` in primary colour.

- [ ] **Step 6: Tap "Calculer mon objectif" (non-onboarding mode)**

Verify: The bounds chip resets to `50–1500g` (muted) because `_calculateResults()` clears `_distributions` and `_expandedBoundsIndices`.

- [ ] **Step 7: Set custom bounds again (200–600g on Petit-déjeuner), tap "Enregistrer mon plan"**

Verify: No error snackbar. Page pops.

---

### Task 6: SQL query test — verify saved bounds in `meal_distribution`

Run via Supabase MCP `execute_sql` or `supabase db query`.

- [ ] **Step 1: Query saved bounds for the active plan**

Replace `<your-user-uuid>` with your actual user ID (visible in Supabase Auth or from `SELECT auth.uid()` in a session).

```sql
SELECT
  md.meal_type,
  md.sort_order,
  md.calorie_pct,
  md.calorie_target,
  md.min_portion_g,
  md.max_portion_g
FROM meal_distribution md
JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
WHERE np.user_id = '<your-user-uuid>'
  AND np.is_active = true
ORDER BY md.sort_order;
```

Expected result (after saving with Petit-déjeuner custom bounds of 200–600g):

| meal_type | min_portion_g | max_portion_g |
|-----------|--------------|--------------|
| breakfast | 200 | 600 |
| lunch | 50 | 1500 |
| dinner | 50 | 1500 |

- [ ] **Step 2: Verify other meal types retained defaults**

Confirm that `lunch` and `dinner` rows show `min_portion_g = 50` and `max_portion_g = 1500`.

- [ ] **Step 3: Set bounds on all three meal types from the app, re-run the query**

Set: breakfast 150–500g, lunch 250–800g, dinner 300–1000g. Save. Re-query.

Expected:

| meal_type | min_portion_g | max_portion_g |
|-----------|--------------|--------------|
| breakfast | 150 | 500 |
| lunch | 250 | 800 |
| dinner | 300 | 1000 |

---

### Task 7: RPC test — verify `generate_meal_plan` respects custom bounds

Run via Supabase MCP `execute_sql`. Uses the auth bypass pattern so the function's `auth.uid()` check passes without a real JWT.

- [ ] **Step 1: Set tight bounds on breakfast to make the test observable**

Use test user `f068c92c-b9ea-496d-af52-94f40c8fab26` (test_3). Set breakfast bounds to 100–200g — a narrow range easy to verify.

```sql
UPDATE meal_distribution
SET min_portion_g = 100, max_portion_g = 200
FROM nutrition_plan np
WHERE meal_distribution.nutrition_plan_id = np.id
  AND np.user_id = 'f068c92c-b9ea-496d-af52-94f40c8fab26'
  AND np.is_active = true
  AND meal_distribution.meal_type = 'breakfast';
```

Expected: `UPDATE 1`

- [ ] **Step 2: Delete existing meal plan for test_3 to get a clean generation**

```sql
DELETE FROM meal_plan
WHERE user_id = 'f068c92c-b9ea-496d-af52-94f40c8fab26';
```

Expected: `DELETE 1` (or more if multiple plans existed — all cascade-deleted).

- [ ] **Step 3: Bypass auth and call `generate_meal_plan`**

```sql
SELECT set_config('request.jwt.claims', '{"sub":"f068c92c-b9ea-496d-af52-94f40c8fab26"}', true);

SELECT
  scheduled_date,
  meal_type,
  calories,
  protein_g
FROM public.generate_meal_plan(
  'f068c92c-b9ea-496d-af52-94f40c8fab26'::uuid,
  7,
  3,
  CURRENT_DATE,
  2
)
ORDER BY scheduled_date, meal_type;
```

Expected: 21 rows (7 days × 3 meals). No error.

- [ ] **Step 4: Verify breakfast servings (grams) are within 100–200g**

```sql
SELECT
  mpe.scheduled_date,
  mpe.meal_type,
  mpe.servings   AS grams,
  mpe.calories_computed,
  md.min_portion_g,
  md.max_portion_g
FROM meal_plan_entry mpe
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
JOIN nutrition_plan np ON np.user_id = mp.user_id AND np.is_active = true
JOIN meal_distribution md
  ON md.nutrition_plan_id = np.id AND md.meal_type = mpe.meal_type
WHERE mp.user_id = 'f068c92c-b9ea-496d-af52-94f40c8fab26'
  AND mpe.meal_type = 'breakfast'
ORDER BY mpe.scheduled_date;
```

Expected: 7 rows. For every row: `grams >= 100 AND grams <= 200`. `calories_computed` should equal approximately `recipe.calories_per_100g × grams / 100`.

- [ ] **Step 5: Verify lunch and dinner still use default bounds (50–1500g)**

```sql
SELECT
  mpe.meal_type,
  MIN(mpe.servings) AS min_grams_used,
  MAX(mpe.servings) AS max_grams_used
FROM meal_plan_entry mpe
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id = 'f068c92c-b9ea-496d-af52-94f40c8fab26'
  AND mpe.meal_type IN ('lunch', 'dinner')
GROUP BY mpe.meal_type;
```

Expected: both meal types show grams within the 50–1500g range (no entries outside bounds).

- [ ] **Step 6: Restore test_3 breakfast bounds to defaults**

```sql
UPDATE meal_distribution
SET min_portion_g = 50, max_portion_g = 1500
FROM nutrition_plan np
WHERE meal_distribution.nutrition_plan_id = np.id
  AND np.user_id = 'f068c92c-b9ea-496d-af52-94f40c8fab26'
  AND np.is_active = true
  AND meal_distribution.meal_type = 'breakfast';
```

Expected: `UPDATE 1`

- [ ] **Step 7: Final commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart
git commit -m "feat(nutrition-plan): portion bounds slider — complete with DB and RPC verification"
```

---

## Self-Review

**Spec coverage:**
- ✅ Per-meal-type expandable panel (Option A)
- ✅ `_BoundsChip` — muted at defaults, primary when customised
- ✅ `_PortionBoundsPanel` — `RangeSlider`, 50–1500g, 25g step, `divisions: 58`
- ✅ `_updateSlotBounds()` updates `_distributions`
- ✅ `_expandedBoundsIndices` cleared on `_calculateResults()`
- ✅ Index shift on `_removeMealSlot()`
- ✅ Returning users see saved bounds via `_loadInitialData()` (no code change needed — `_distributions` is populated from DB)
- ✅ SQL query test for saved bounds per meal type
- ✅ RPC test with auth bypass verifying `servings` within custom bounds

**Placeholder scan:** None found. All steps contain actual code or exact SQL.

**Type consistency:**
- `_updateSlotBounds(int index, int minG, int maxG)` — matches usage in `_PortionBoundsPanel.onChanged`
- `_BoundsChip.onTap: VoidCallback` — matches `setState` lambda
- `_expandedBoundsIndices: Set<int>` — consistent across all tasks
- `dist.minPortionG` / `dist.maxPortionG` — `MealDistribution` fields confirmed present
