# Nutrition Plan Workflow — Design Spec

**Date:** 2026-05-25
**Branch:** fix-compliance-and-router-issues-814be

---

## Problem

`generate_meal_plan()` currently divides `calorie_goal / meals_per_day` uniformly — no per-meal-type weighting, no stored macro targets, and no workflow to derive the calorie goal from user health parameters. This spec covers a full nutrition plan setup flow accessible from both onboarding and settings.

---

## Goals

- Calculate daily calorie goal from user health parameters (BMR via Mifflin-St Jeor → TDEE → goal adjustment)
- Derive macro targets (protein/carb/fat in grams) from primary goal, user-adjustable
- Let users distribute calories across custom meal slots (e.g. breakfast 25%, lunch 35%, dinner 30%, snack 10%) with live kcal display
- Update `generate_meal_plan()` to read per-meal calorie targets from `meal_distribution` instead of flat division
- Expose this in onboarding (new step) and in a settings page

---

## Data Model

### `nutrition_plan`

One active plan per user. Stores the calorie goal, macro targets, and calculation inputs (BMR, TDEE) for reference.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → `user_profile` | |
| `calorie_goal` | INT | TDEE-adjusted daily target |
| `protein_goal_g` | NUMERIC | auto-calculated, user-overridable |
| `carb_goal_g` | NUMERIC | |
| `fat_goal_g` | NUMERIC | |
| `bmr` | NUMERIC | stored for display/recalculation |
| `tdee` | NUMERIC | |
| `is_active` | BOOLEAN | only one active per user (trigger-enforced) |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

### `meal_distribution`

One row per meal slot. Child of `nutrition_plan`. Calorie target is trigger-computed from `calorie_pct × calorie_goal`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `nutrition_plan_id` | UUID FK → `nutrition_plan` | |
| `meal_type` | TEXT | `'breakfast'`, `'lunch'`, `'dinner'`, `'snack_1'`, etc. |
| `sort_order` | INT | display order |
| `calorie_pct` | NUMERIC | user-adjustable; must sum to 100 across plan |
| `calorie_target` | NUMERIC | trigger-computed: `calorie_goal × calorie_pct / 100` |
| `created_at` | TIMESTAMPTZ | |

**Triggers:**
- `trg_one_active_nutrition_plan` — deactivates previous active plan on new insert
- `trg_sync_calorie_target_on_plan` — recomputes `calorie_target` for all slots when `calorie_goal` changes
- `trg_sync_calorie_target_on_dist` — recomputes `calorie_target` for a slot when its `calorie_pct` changes

**RLS:** users can only read/write their own `nutrition_plan` and `meal_distribution` rows.

---

## Calorie Calculation Formulas

### BMR — Mifflin-St Jeor

```
Male:   (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
Female: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
```

### TDEE — Activity Multiplier

| Activity Level | Multiplier |
|---------------|------------|
| sedentary | 1.2 |
| lightly_active | 1.375 |
| moderately_active | 1.55 |
| very_active | 1.725 |
| extremely_active | 1.9 |

### Goal Adjustment

| Primary Goal | Adjustment |
|-------------|------------|
| weight_loss | TDEE − 500 kcal |
| maintenance | TDEE |
| muscle_gain / weight_gain | TDEE + 300 kcal |

### Macro Defaults (auto-filled, user-adjustable)

| Goal | Protein | Carbs | Fat |
|------|---------|-------|-----|
| weight_loss | 30% | 40% | 30% |
| maintenance | 25% | 50% | 25% |
| muscle_gain | 30% | 45% | 25% |

Gram conversion: protein/carbs = `(pct × cal) / 4`, fat = `(pct × cal) / 9`.

### Default Meal Splits

| Meal Count | Breakfast | Lunch | Dinner | Snack |
|-----------|-----------|-------|--------|-------|
| 3 meals | 30% | 35% | 35% | — |
| 3 meals + 1 snack | 25% | 35% | 30% | 10% |
| N meals (other) | equal split (100% / N each) | | | |

---

## RPC Update: `generate_meal_plan()`

Current: `v_target_meal_cal := v_calorie_goal / meals_per_day`

New (with fallback):
```sql
SELECT md.calorie_target INTO v_target_meal_cal
FROM meal_distribution md
JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
WHERE np.user_id = p_user_id
  AND np.is_active = true
  AND md.meal_type = v_current_meal_type
LIMIT 1;

IF v_target_meal_cal IS NULL THEN
  v_target_meal_cal := v_calorie_goal / meals_per_day;  -- fallback for users without a nutrition plan
END IF;
```

---

## Flutter Architecture

### New files

| File | Purpose |
|------|---------|
| `lib/core/nutrition_calculator.dart` | `NutritionCalculatorService` — pure Dart, static methods for BMR/TDEE/macros/default splits |
| `lib/shared/models/nutrition_plan.dart` | `NutritionPlan` + `MealDistribution` data classes with `fromJson`/`toJson` |
| `lib/providers/nutrition_plan_provider.dart` | `activeNutritionPlanProvider` (fetch) + `NutritionPlanNotifier` (save/preview) |
| `lib/features/nutrition_plan/nutrition_plan_page.dart` | Settings page + reusable `NutritionPlanForm` widget |

### Modified files

| File | Change |
|------|--------|
| `lib/core/router.dart` | Add `/nutrition-plan` named route |
| `lib/features/auth/onboarding_page.dart` | Add nutrition plan step after health profile step |
| `supabase/migrations/` | New migration files (see below) |

### `NutritionPlanPage` — 4-section layout

1. **Health Parameters** — pre-filled from `user_health_profile` (weight, height, age, sex, activity level, primary goal); all editable
2. **Calculate button** — runs `NutritionCalculatorService` locally; shows BMR / TDEE / calorie goal result card; no save
3. **Macro distribution** — protein/carbs/fat fields showing both grams and %; soft warning if macros don't add up to calorie goal (±5% tolerance)
4. **Meal distribution** — list of meal slots; each shows meal type label, % slider, and live kcal value (`calorie_goal × pct / 100`); add/remove slots; validation banner when sum ≠ 100%

**Save button** — disabled until pct sum == 100. Saves `nutrition_plan` + `meal_distribution` rows. Also saves any changed health parameters back to `user_health_profile`. Syncs `user_goal.calorie_goal` for backward compatibility.

### Onboarding

`NutritionPlanForm` widget is reused in both onboarding (with "Continuer" button) and the settings page (with "Enregistrer" button).

---

## Migration Files

| File | Purpose |
|------|---------|
| `supabase/migrations/20260525000003_nutrition_plan.sql` | Create `nutrition_plan` + `meal_distribution` tables, triggers, RLS |
| `supabase/migrations/20260525000004_patch_generate_meal_plan.sql` | Patch RPC to read from `meal_distribution` with fallback |

---

## Verification Checklist

- [ ] `supabase db push` applies without errors
- [ ] Two-user RLS test: each user sees only their own plan
- [ ] Unit test: male 30yo 80kg 175cm moderately_active weight_loss → BMR≈1783, TDEE≈2764, goal≈2264 kcal
- [ ] UI: Calculate button fills result card; macro fields update; meal slot sliders update kcal live
- [ ] Save: `nutrition_plan` + `meal_distribution` rows created; previous plan deactivated
- [ ] Meal plan generation: breakfast slot uses `meal_distribution.calorie_target`, not `calorie_goal / N`
- [ ] Fallback: user with no `nutrition_plan` can still generate a meal plan
- [ ] Onboarding: nutrition plan step appears and saves correctly
