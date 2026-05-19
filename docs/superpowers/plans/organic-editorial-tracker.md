# Organic Editorial Redesign — Master Tracker

> **For agents:** Claim a page by setting its status to `IN PROGRESS` (include your agent ID or session), then create a plan file at `docs/superpowers/plans/YYYY-MM-DD-wave-N-<page-name>.md` and execute it. When done, update status to `DONE` and fill in the commit SHA.
>
> **Logging is mandatory.** Every file you touch must comply with the CLAUDE.md logging standard. Do not remove or skip logging steps.
>
> **Design tokens** are in `lib/core/theme.dart`:
> `AkeliColors`, `AkeliRadius`, `AkeliSpacing`, `AkeliShadows`
> Typography: `GoogleFonts.plusJakartaSans` (headlines/display) + `GoogleFonts.inter` (body/labels)

---

## Status Table

| Page | File | Complexity | Status | Commit |
|------|------|------------|--------|--------|
| Auth | `lib/features/auth/auth_page.dart` | Low | ✅ DONE | Wave 1 |
| Onboarding | `lib/features/auth/onboarding_page.dart` | Medium | ✅ DONE | Wave 1 |
| Home Dashboard | `lib/features/home/home_page.dart` | Medium | ✅ DONE | d2635f5 |
| Feed | `lib/features/recipes/feed_page.dart` | Low | ✅ DONE | cb84a1f |
| Recipe Detail | `lib/features/recipes/recipe_detail_page.dart` | Medium | 🔲 PENDING | — |
| Meal Planner | `lib/features/meal_planner/meal_planner_page.dart` | Medium | 🔲 PENDING | — |
| Meal Detail | `lib/features/meal_planner/meal_detail_page.dart` | Low | 🔲 PENDING | — |
| Batch Cooking | `lib/features/meal_planner/batch_cooking_page.dart` | Medium | 🔲 PENDING | — |
| Shopping List | `lib/features/meal_planner/shopping_list_page.dart` | Medium | 🔲 PENDING | — |
| Nutrition | `lib/features/nutrition/nutrition_page.dart` | High | 🔲 PENDING | — |
| Diet Plan | `lib/features/diet_plan/diet_plan_page.dart` | High | 🔲 PENDING | — |
| AI Chat | `lib/features/ai_assistant/ai_chat_page.dart` | High | 🔲 PENDING | — |
| Profile | `lib/features/profile/profile_page.dart` | High | 🔲 PENDING | — |
| Fan Mode | `lib/features/fan_mode/fan_mode_page.dart` | Medium | 🔲 PENDING | — |
| Subscription | `lib/features/subscription/subscription_page.dart` | Low | 🔲 PENDING | — |
| Community | `lib/features/community/community_page.dart` | Low | 🔲 PENDING | — |
| Group Chat | `lib/features/community/group_chat_page.dart` | Low | 🔲 PENDING | — |
| Group Detail | `lib/features/community/group_detail_page.dart` | Low | 🔲 PENDING | — |
| Notifications | `lib/features/notifications/notifications_page.dart` | Low | 🔲 PENDING | — |

---

## Issue Legend

| Symbol | Meaning |
|--------|---------|
| 🟥 `Colors.white` | Replace with `AkeliColors.surfaceContainerLowest` (or appropriate surface tier) |
| 🟧 `textTheme` / raw `TextStyle` | Replace with `GoogleFonts.plusJakartaSans` (headlines) or `GoogleFonts.inter` (body/labels) |
| 🟨 `textSecondary` | Replace `AkeliColors.textSecondary` with `AkeliColors.onSurfaceVariant` |
| 🟦 Comment banners | Remove multi-line `// ═══`, `// ───`, explanatory comment blocks |
| 🟩 Missing `dispose()` | Add `dispose()` override with `_logger.provider('ClassName disposed')` |
| ⬛ Hardcoded radius | Replace `BorderRadius.circular(<number>)` with `AkeliRadius.*` token |
| 🔷 Inline BoxShadow | Replace inline `BoxShadow(...)` with `AkeliShadows.sm/md/lg` |
| 🔴 `Colors.black` | Replace with `AkeliColors.onSurface.withValues(alpha: ...)` |

---

## Page-by-Page Issues

---

### `lib/features/recipes/recipe_detail_page.dart`
**Complexity:** Medium | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 192, 336 |
| 🟧 `textTheme` / raw `TextStyle` | 212, 257, 269, 282, 287, 298, 316, 349, 356, 430 |
| 🟨 `AkeliColors.textSecondary` | 258, 290, 301, 360, 403 |
| ⬛ Hardcoded `BorderRadius` | 195, 422 |

> **Logging status:** dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/meal_planner/meal_planner_page.dart`
**Complexity:** Medium | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 213, 224 |
| 🟧 `textTheme` / raw `TextStyle` | 44, 82, 91, 110, 248, 283 |
| 🟦 Comment banners | 29, 69, 122 |
| ⬛ Hardcoded `BorderRadius` | 225, 241, 268 |
| 🔷 Inline `BoxShadow` | 227–232 |
| 🔴 `Colors.black` | 229 |

> **Logging status:** dispose n/a (ConsumerWidget) · build() entry ✅ · userAction ✅

---

### `lib/features/meal_planner/meal_detail_page.dart`
**Complexity:** Low | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 201, 214 |
| 🟧 `textTheme` / raw `TextStyle` | 107, 279, 295, 330 |
| 🟨 `AkeliColors.textSecondary` | 280, 299 |
| 🟦 Comment banners | 89, 104, 128, 142, 169, 192 |
| ⬛ Hardcoded `BorderRadius` | 206, 269, 291, 321 |

> **Logging status:** dispose n/a (ConsumerWidget) · build() entry ✅ · userAction ✅

---

### `lib/features/meal_planner/batch_cooking_page.dart`
**Complexity:** Medium | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 31 |
| 🟧 `textTheme` / raw `TextStyle` | 77, 96, 119, 152, 159, 234, 241, 267 |
| 🟨 `AkeliColors.textSecondary` | 97, 162, 242, 268 |
| 🟦 Comment banners | 132, 172 |
| ⬛ Hardcoded `BorderRadius` | 63, 86, 214, 218, 250 |
| 🔷 Inline `BoxShadow` | 198–203 |
| 🔴 `Colors.black` | 200 |

> **Logging status:** dispose n/a (ConsumerWidget) · build() entry ✅ · userAction ✅

---

### `lib/features/meal_planner/shopping_list_page.dart`
**Complexity:** Medium | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟧 `textTheme` / raw `TextStyle` | 89, 148, 150, 155, 157 |
| 🟨 `AkeliColors.textSecondary` | 159 |
| ⬛ Hardcoded `BorderRadius` | 123 |
| 🔷 Inline `BoxShadow` | 124 |

> **Logging status:** dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/nutrition/nutrition_page.dart`
**Complexity:** High | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 190, 201, 212 |
| 🟧 `textTheme` / raw `TextStyle` | 89, 110, 142, 147, 258, 292, 336, 356, 364 |
| 🟨 `AkeliColors.textSecondary` | 299, 313, 357, 468 |
| ⬛ Hardcoded `BorderRadius` | 255, 436 |

> **Logging status:** dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/diet_plan/diet_plan_page.dart`
**Complexity:** High | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 147, 206 |
| 🟧 `textTheme` / raw `TextStyle` | 39, 62, 95, 110, 177, 215, 219, 233, 253, 260 |
| 🟨 `AkeliColors.textSecondary` | 179, 219 |
| 🟦 Comment banners | 11, 31, 69, 101, 123, 130, 152 |
| 🟩 Missing `dispose()` | no override despite ConsumerStatefulWidget |
| ⬛ Hardcoded `BorderRadius` | 155, 160, 195, 231 |
| 🔷 Inline `BoxShadow` | 162–167 |
| 🔴 `Colors.black` | 164 |

> **Logging status:** build() entry ✅ · userAction ✅

---

### `lib/features/ai_assistant/ai_chat_page.dart`
**Complexity:** High | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 90, 172, 269, 307, 387, 438 |
| 🟧 `textTheme` / raw `TextStyle` | 312, 318, 326, 350 |
| 🟨 `AkeliColors.textSecondary` | 321, 353 |
| 🟦 Comment banners | 7, 27, 110 |
| ⬛ Hardcoded `BorderRadius` | 232, 262, 333, 339 |
| 🔷 Inline `BoxShadow` | 410–415 |
| 🔴 `Colors.black` | 412 |

> **Logging status:** dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/profile/profile_page.dart`
**Complexity:** High | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 75, 146 |
| 🟧 `textTheme` / raw `TextStyle` | 39, 84, 102, 104, 106, 127, 135, 187, 189, 244, 246, 345 |
| 🟨 `AkeliColors.textSecondary` | 189, 247 |
| 🟦 Comment banners | 44, 119, 167, 198 |
| ⬛ Hardcoded `BorderRadius` | 94 |

> **Logging status:** dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/fan_mode/fan_mode_page.dart`
**Complexity:** Medium | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 172 |
| 🟧 `textTheme` / raw `TextStyle` | 54, 231, 277, 287, 343, 347, 350, 362, 373 |
| 🟨 `AkeliColors.textSecondary` | 240, 287, 350, 364, 376 |
| 🟦 Comment banners | 32, 43 |
| 🟩 Missing `dispose()` | ConsumerWidget — no override needed; if refactored to ConsumerStatefulWidget, add dispose |
| ⬛ Hardcoded `BorderRadius` | 221, 262 |

> **Logging status:** build() entry ✅ · userAction ✅

---

### `lib/features/subscription/subscription_page.dart`
**Complexity:** Low | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 42, 47, 57, 90 |
| 🟧 `textTheme` / raw `TextStyle` | 46, 57, 75, 95, 109, 116, 119, 185, 194, 203 |
| 🟨 `AkeliColors.textSecondary` | 117, 122, 195, 204 |
| 🟦 Comment banners | 29 |
| ⬛ Hardcoded `BorderRadius` | 38 |

> **Logging status:** build() entry ✅ · userAction ✅

---

### `lib/features/community/community_page.dart`
**Complexity:** Low | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟧 `textTheme` / raw `TextStyle` | 102, 108, 120, 122 |
| 🟨 `AkeliColors.textSecondary` | 117, 123 |
| 🟦 Comment banners | 37 |
| ⬛ Hardcoded `BorderRadius` | 80, 86 |
| 🔷 Inline `BoxShadow` | 87 |

> **Logging status:** build() entry ✅ · userAction ✅

---

### `lib/features/community/group_chat_page.dart`
**Complexity:** Low | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| ⬛ Hardcoded `BorderRadius` | 108 |

> **Logging status:** dispose ✅ · build() entry ✅ · userAction ✅
> **Note:** Cleanest file in the codebase — one minor radius token swap needed.

---

### `lib/features/community/group_detail_page.dart`
**Complexity:** Low | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟧 `textTheme` / raw `TextStyle` | 43, 54, 75 |
| 🟨 `AkeliColors.textSecondary` | 54 |

> **Logging status:** build() entry ✅ · userAction ✅
> **Note:** StatelessWidget — no dispose needed.

---

### `lib/features/notifications/notifications_page.dart`
**Complexity:** Low | **Status:** 🔲 PENDING

> No design token issues found. File passes all audit checks.
>
> **Note:** StatelessWidget with no interactive elements. Only confirm `import 'package:akeli/core/logger.dart'` is present — if not, add it.

---

## How to Execute a Page Redesign

1. Pick a `🔲 PENDING` page from the table above.
2. Read the page-level issues section for that file.
3. Run `superpowers:writing-plans` to create a plan at `docs/superpowers/plans/YYYY-MM-DD-wave-N-<page>.md`.
   - The plan must include the complete replacement code for every changed block (no placeholders).
   - Every changed file must pass `flutter analyze`.
4. Run `superpowers:subagent-driven-development` to execute the plan.
5. Update this tracker: set status to `✅ DONE`, add the commit SHA.

## Recommended Execution Order

Group pages into waves to minimize context switching:

| Wave | Pages | Reason |
|------|-------|--------|
| Wave 3 | Recipe Detail, Meal Planner, Meal Detail | Core cooking flow |
| Wave 4 | Nutrition, Diet Plan, Batch Cooking, Shopping List | Nutrition & planning flow |
| Wave 5 | Profile, Subscription, Fan Mode | User account flow |
| Wave 6 | AI Chat, Community, Group Chat, Group Detail, Notifications | Social & utility |
