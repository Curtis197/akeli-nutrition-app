---
name: modular-removal
description: Surgical UI removal of multi-component (modular) meal rendering — entries always display as a single complete recipe
metadata:
  type: spec
---

# Modular Removal — Design Spec

**Date:** 2026-05-28
**Approach:** Surgical UI removal (Approach A) — DB and RPC unchanged
**Reference:** [Meal Plan Philosophy](../../meal_plan_generator_philosophy.md)

---

## Context

The modular meal feature (one entry composed of a base + starch + side recipe) is being deferred post-launch. Creators handle dish composition themselves — every recipe is a complete dish. The `meal_plan_entry_component` table remains in the DB (always exactly one row per entry with `role='base'`), but the UI stops treating entries as multi-component.

Batch cooking is **not affected** — it operates on complete recipes independently of the modular concept.

---

## Scope

### Removed
| Location | What |
|----------|------|
| `meal_detail_page.dart` | Multi-component loop/list rendering; starch and side display widgets |
| `meal_planner_page.dart` | Unimplemented snack addition stub button (lines 313–330) |
| `meal_plan_provider.dart` | Any `isModular` conditional branching |
| `meal_plan.dart` | `isModular` getter (`bool get isModular => components.length > 1`) |

### Untouched
| Location | Why |
|----------|-----|
| `BatchCookingPage` + cooking session providers/models | Independent of modular |
| `create_batch_sessions` RPC call in edge function | Still needed for repeated recipes |
| `meal_plan_entry_component` DB table | Stays dormant with one row per entry |
| `MealPlanEntryComponent` Dart model | Still used to read base recipe data |
| `_base` getter on `MealPlanEntry` | Still the correct way to access the single recipe |
| All swap flows (recipe + personal meal) | Unaffected |
| Snack generation via `meals_per_day=4` RPC path | Removed stub was manual add, not generation |

---

## Behaviour After Change

- Every meal entry renders as a single complete recipe: title, thumbnail, macros from `_base` component
- `MealDetailPage` reads `entry._base` directly — no iteration over components
- Batch cooking displays and functions identically
- Snack entries remain generatable via the existing RPC path
- No DB migration required
- No user-facing message or change in perceived behaviour

---

## File Changes

### `lib/shared/models/meal_plan.dart`
- Remove `isModular` getter

### `lib/features/meal_planner/meal_detail_page.dart`
- Replace any component list iteration with direct `entry._base` read
- Remove starch/side component display blocks

### `lib/features/meal_planner/meal_planner_page.dart`
- Remove snack addition stub button and its dead `onPressed` handler

### `lib/providers/meal_plan_provider.dart`
- Remove `isModular` conditional branches

---

## Out of Scope

- Any DB migration
- Batch cooking changes
- Swap flow changes
- Generator algorithm changes (covered in Spec 2)
