# Organic Editorial Redesign — Master Tracker

> **For agents:** Claim a page by setting its status to `IN PROGRESS`, then create a plan file at `docs/superpowers/plans/YYYY-MM-DD-wave-N-<page-name>.md` and execute it. When done, set status to `DONE` and fill in the commit SHA.
>
> **Logging is mandatory.** Every file you touch must comply with the CLAUDE.md logging standard. Never skip logging steps.
>
> **Design tokens** live in `lib/core/theme.dart`: `AkeliColors`, `AkeliRadius`, `AkeliSpacing`, `AkeliShadows`
> Typography: `GoogleFonts.plusJakartaSans` (headlines/display) + `GoogleFonts.inter` (body/labels)
>
> **Design system reference:** `stitch/stitch_modern_dashboard_akeli_victoire/akeli_oasis_v2/DESIGN.md`

---

## How to Use Stitch References

Every page in this tracker has a **Stitch Reference** — an HTML/PNG design mockup generated during the design phase. Use it as your visual spec when implementing changes.

```
stitch{N}/stitch_modern_dashboard_akeli_victoire/{stitch-name}/
  ├── code.html   ← full HTML+CSS design mockup → read this for colors, layout, component structure
  └── screen.png  ← screenshot of the final design → visual reference
```

**Priority rule:** Use the highest-numbered stitch that contains the page. stitch4 > stitch3 > stitch2 > stitch1. When a page appears in multiple stitches, the higher number is the latest iteration.

**Before writing any code for a page:**
1. Read `screen.png` (image) to understand the visual target
2. Read `code.html` to extract exact token usage, layout structure, and component details
3. Cross-reference with `lib/core/theme.dart` to map CSS values to Dart `AkeliColors`/`AkeliRadius` constants

---

## Status Tables

### Existing Pages — Redesign Queue

| Page | File | Complexity | Stitch Reference | Status | Commit |
|------|------|------------|-----------------|--------|--------|
| Auth (login + signup) | `lib/features/auth/auth_page.dart` | Low | `stitch4/.../akeli_auth_login` + `akeli_auth_sign_up` | ✅ DONE | Wave 1 |
| Onboarding | `lib/features/auth/onboarding_page.dart` | Medium | `stitch2/.../akeli_onboarding_*` (6 screens) | ✅ DONE | Wave 1 |
| Home Dashboard | `lib/features/home/home_page.dart` | Medium | `stitch4/.../akeli_digital_editorial_dashboard` | ✅ DONE | d2635f5 |
| Feed | `lib/features/recipes/feed_page.dart` | Low | `stitch2/.../akeli_recipe_discovery_editorial` | ✅ DONE | cb84a1f |
| Recipe Detail | `lib/features/recipes/recipe_detail_page.dart` | Medium | `stitch2/.../akeli_premium_recipe_detail_editorial` | 🔲 PENDING | — |
| Meal Planner | `lib/features/meal_planner/meal_planner_page.dart` | Medium | `stitch4/.../akeli_full_week_planner_v2` | 🔲 PENDING | — |
| Meal Detail | `lib/features/meal_planner/meal_detail_page.dart` | Low | `stitch4/.../akeli_meal_detail_simplified_ingredients` | 🔲 PENDING | — |
| Batch Cooking | `lib/features/meal_planner/batch_cooking_page.dart` | Medium | `stitch3/.../akeli_batch_cooking_tracker` | 🔲 PENDING | — |
| Shopping List | `lib/features/meal_planner/shopping_list_page.dart` | Medium | `stitch2/.../akeli_editorial_shopping_list` | 🔲 PENDING | — |
| Nutrition | `lib/features/nutrition/nutrition_page.dart` | High | *(no stitch — use design system spec)* | 🔲 PENDING | — |
| Diet Plan | `lib/features/diet_plan/diet_plan_page.dart` | High | `stitch3/.../akeli_diet_plan_editorial` | 🔲 PENDING | — |
| AI Chat | `lib/features/ai_assistant/ai_chat_page.dart` | High | `stitch3/.../akeli_editorial_chat` | 🔲 PENDING | — |
| Profile | `lib/features/profile/profile_page.dart` | High | `stitch2/.../akeli_profile_digital_editorial` + `stitch3/.../akeli_profile_create_edit` + `stitch3/.../akeli_edit_info_editorial` | 🔲 PENDING | — |
| Fan Mode | `lib/features/fan_mode/fan_mode_page.dart` | Medium | *(no stitch — use design system spec)* | 🔲 PENDING | — |
| Subscription | `lib/features/subscription/subscription_page.dart` | Low | `stitch2/.../akeli_subscription_management_editorial` | 🔲 PENDING | — |
| Community | `lib/features/community/community_page.dart` | Low | `stitch3/.../akeli_community_groups` | 🔲 PENDING | — |
| Group Chat | `lib/features/community/group_chat_page.dart` | Low | `stitch3/.../akeli_community_conversations` | 🔲 PENDING | — |
| Group Detail | `lib/features/community/group_detail_page.dart` | Low | *(no stitch — use design system spec)* | 🔲 PENDING | — |
| Notifications | `lib/features/notifications/notifications_page.dart` | Low | `stitch2/.../akeli_notification_settings_editorial` | 🔲 PENDING | — |

> All stitch paths expand to `stitch{N}/stitch_modern_dashboard_akeli_victoire/{name}/`

---

### New Pages — To Be Created

These pages have stitch designs but no Flutter file yet. Create the file, then implement from the stitch.

| Page | Target File | Stitch Reference | Status | Commit |
|------|------------|-----------------|--------|--------|
| Privacy Policy | `lib/features/legal/privacy_policy_page.dart` | `stitch2/.../akeli_privacy_policy_editorial` | 🔲 PENDING | — |
| Terms of Service | `lib/features/legal/terms_of_service_page.dart` | `stitch3/.../akeli_terms_of_service_editorial` | 🔲 PENDING | — |
| Support | `lib/features/support/support_page.dart` | `stitch2/.../akeli_support_editorial` | 🔲 PENDING | — |
| Referral Management | `lib/features/referral/referral_page.dart` | `stitch2/.../akeli_referral_management_editorial` | 🔲 PENDING | — |

---

### Bottom Sheets & Components — To Be Created / Updated

| Component | Target File | Stitch Reference | Status | Commit |
|-----------|------------|-----------------|--------|--------|
| Cooking Session Sheet | `lib/shared/widgets/cooking_session_sheet.dart` | `stitch3/.../new_cooking_session_bottom_sheet` | 🔲 PENDING | — |
| Journaling Sheet | `lib/shared/widgets/journaling_sheet.dart` | `stitch4/.../journaling_bottom_sheet_no_feelings` | 🔲 PENDING | — |

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

## Page-by-Page Issues (Existing Pages)

---

### `lib/features/recipes/recipe_detail_page.dart`
**Complexity:** Medium | **Stitch:** `stitch2/.../akeli_premium_recipe_detail_editorial` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 192, 336 |
| 🟧 `textTheme` / raw `TextStyle` | 212, 257, 269, 282, 287, 298, 316, 349, 356, 430 |
| 🟨 `AkeliColors.textSecondary` | 258, 290, 301, 360, 403 |
| ⬛ Hardcoded `BorderRadius` | 195, 422 |

> Logging: dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/meal_planner/meal_planner_page.dart`
**Complexity:** Medium | **Stitch:** `stitch4/.../akeli_full_week_planner_v2` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 213, 224 |
| 🟧 `textTheme` / raw `TextStyle` | 44, 82, 91, 110, 248, 283 |
| 🟦 Comment banners | 29, 69, 122 |
| ⬛ Hardcoded `BorderRadius` | 225, 241, 268 |
| 🔷 Inline `BoxShadow` | 227–232 |
| 🔴 `Colors.black` | 229 |

> Logging: build() entry ✅ · userAction ✅ (ConsumerWidget — no dispose)

---

### `lib/features/meal_planner/meal_detail_page.dart`
**Complexity:** Low | **Stitch:** `stitch4/.../akeli_meal_detail_simplified_ingredients` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 201, 214 |
| 🟧 `textTheme` / raw `TextStyle` | 107, 279, 295, 330 |
| 🟨 `AkeliColors.textSecondary` | 280, 299 |
| 🟦 Comment banners | 89, 104, 128, 142, 169, 192 |
| ⬛ Hardcoded `BorderRadius` | 206, 269, 291, 321 |

> Logging: build() entry ✅ · userAction ✅ (ConsumerWidget — no dispose)

---

### `lib/features/meal_planner/batch_cooking_page.dart`
**Complexity:** Medium | **Stitch:** `stitch3/.../akeli_batch_cooking_tracker` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 31 |
| 🟧 `textTheme` / raw `TextStyle` | 77, 96, 119, 152, 159, 234, 241, 267 |
| 🟨 `AkeliColors.textSecondary` | 97, 162, 242, 268 |
| 🟦 Comment banners | 132, 172 |
| ⬛ Hardcoded `BorderRadius` | 63, 86, 214, 218, 250 |
| 🔷 Inline `BoxShadow` | 198–203 |
| 🔴 `Colors.black` | 200 |

> Logging: build() entry ✅ · userAction ✅ (ConsumerWidget — no dispose)

---

### `lib/features/meal_planner/shopping_list_page.dart`
**Complexity:** Medium | **Stitch:** `stitch2/.../akeli_editorial_shopping_list` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟧 `textTheme` / raw `TextStyle` | 89, 148, 150, 155, 157 |
| 🟨 `AkeliColors.textSecondary` | 159 |
| ⬛ Hardcoded `BorderRadius` | 123 |
| 🔷 Inline `BoxShadow` | 124 |

> Logging: dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/nutrition/nutrition_page.dart`
**Complexity:** High | **Stitch:** *(none — use `stitch/stitch_modern_dashboard_akeli_victoire/akeli_oasis_v2/DESIGN.md`)* | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 190, 201, 212 |
| 🟧 `textTheme` / raw `TextStyle` | 89, 110, 142, 147, 258, 292, 336, 356, 364 |
| 🟨 `AkeliColors.textSecondary` | 299, 313, 357, 468 |
| ⬛ Hardcoded `BorderRadius` | 255, 436 |

> Logging: dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/diet_plan/diet_plan_page.dart`
**Complexity:** High | **Stitch:** `stitch3/.../akeli_diet_plan_editorial` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 147, 206 |
| 🟧 `textTheme` / raw `TextStyle` | 39, 62, 95, 110, 177, 215, 219, 233, 253, 260 |
| 🟨 `AkeliColors.textSecondary` | 179, 219 |
| 🟦 Comment banners | 11, 31, 69, 101, 123, 130, 152 |
| 🟩 Missing `dispose()` | ConsumerStatefulWidget — no override yet |
| ⬛ Hardcoded `BorderRadius` | 155, 160, 195, 231 |
| 🔷 Inline `BoxShadow` | 162–167 |
| 🔴 `Colors.black` | 164 |

> Logging: build() entry ✅ · userAction ✅

---

### `lib/features/ai_assistant/ai_chat_page.dart`
**Complexity:** High | **Stitch:** `stitch3/.../akeli_editorial_chat` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 90, 172, 269, 307, 387, 438 |
| 🟧 `textTheme` / raw `TextStyle` | 312, 318, 326, 350 |
| 🟨 `AkeliColors.textSecondary` | 321, 353 |
| 🟦 Comment banners | 7, 27, 110 |
| ⬛ Hardcoded `BorderRadius` | 232, 262, 333, 339 |
| 🔷 Inline `BoxShadow` | 410–415 |
| 🔴 `Colors.black` | 412 |

> Logging: dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/profile/profile_page.dart`
**Complexity:** High | **Stitch:** `stitch2/.../akeli_profile_digital_editorial` + `stitch3/.../akeli_profile_create_edit` + `stitch3/.../akeli_edit_info_editorial` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 75, 146 |
| 🟧 `textTheme` / raw `TextStyle` | 39, 84, 102, 104, 106, 127, 135, 187, 189, 244, 246, 345 |
| 🟨 `AkeliColors.textSecondary` | 189, 247 |
| 🟦 Comment banners | 44, 119, 167, 198 |
| ⬛ Hardcoded `BorderRadius` | 94 |

> Logging: dispose ✅ · build() entry ✅ · userAction ✅

---

### `lib/features/fan_mode/fan_mode_page.dart`
**Complexity:** Medium | **Stitch:** *(none — use design system spec)* | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 172 |
| 🟧 `textTheme` / raw `TextStyle` | 54, 231, 277, 287, 343, 347, 350, 362, 373 |
| 🟨 `AkeliColors.textSecondary` | 240, 287, 350, 364, 376 |
| 🟦 Comment banners | 32, 43 |
| ⬛ Hardcoded `BorderRadius` | 221, 262 |

> Logging: build() entry ✅ · userAction ✅ (ConsumerWidget — no dispose)

---

### `lib/features/subscription/subscription_page.dart`
**Complexity:** Low | **Stitch:** `stitch2/.../akeli_subscription_management_editorial` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟥 `Colors.white` | 42, 47, 57, 90 |
| 🟧 `textTheme` / raw `TextStyle` | 46, 57, 75, 95, 109, 116, 119, 185, 194, 203 |
| 🟨 `AkeliColors.textSecondary` | 117, 122, 195, 204 |
| 🟦 Comment banners | 29 |
| ⬛ Hardcoded `BorderRadius` | 38 |

> Logging: build() entry ✅ · userAction ✅

---

### `lib/features/community/community_page.dart`
**Complexity:** Low | **Stitch:** `stitch3/.../akeli_community_groups` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟧 `textTheme` / raw `TextStyle` | 102, 108, 120, 122 |
| 🟨 `AkeliColors.textSecondary` | 117, 123 |
| 🟦 Comment banners | 37 |
| ⬛ Hardcoded `BorderRadius` | 80, 86 |
| 🔷 Inline `BoxShadow` | 87 |

> Logging: build() entry ✅ · userAction ✅

---

### `lib/features/community/group_chat_page.dart`
**Complexity:** Low | **Stitch:** `stitch3/.../akeli_community_conversations` | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| ⬛ Hardcoded `BorderRadius` | 108 |

> Logging: dispose ✅ · build() entry ✅ · userAction ✅
> Note: Cleanest file — one radius token swap.

---

### `lib/features/community/group_detail_page.dart`
**Complexity:** Low | **Stitch:** *(none — use design system spec)* | **Status:** 🔲 PENDING

| Issue | Lines |
|-------|-------|
| 🟧 `textTheme` / raw `TextStyle` | 43, 54, 75 |
| 🟨 `AkeliColors.textSecondary` | 54 |

> Logging: build() entry ✅ · userAction ✅ (StatelessWidget — no dispose)

---

### `lib/features/notifications/notifications_page.dart`
**Complexity:** Low | **Stitch:** `stitch2/.../akeli_notification_settings_editorial` | **Status:** 🔲 PENDING

> No token issues found. Only verify `import 'package:akeli/core/logger.dart'` is present.

---

## Execution Guide for Agents

### 1. Before writing code
```
1. Read stitch screen.png → understand the visual target
2. Read stitch code.html → extract layout, colors, spacing
3. Read the page-level issue table above → know exactly which lines to touch
4. Read lib/core/theme.dart → map CSS hex values to AkeliColors constants
```

### 2. Create a plan
```
Run: superpowers:writing-plans
Save to: docs/superpowers/plans/YYYY-MM-DD-wave-N-<page>.md
```

### 3. Execute
```
Run: superpowers:subagent-driven-development
```

### 4. After completion
- Run `flutter analyze <file>` — must return "No issues found."
- Update status in this file: `🔲 PENDING` → `✅ DONE`
- Add commit SHA

---

## Recommended Wave Order

| Wave | Pages | Stitch Coverage |
|------|-------|----------------|
| Wave 3 | Recipe Detail, Meal Planner, Meal Detail | All have stitch4/stitch2 refs |
| Wave 4 | Batch Cooking, Shopping List, Diet Plan | All have stitch3/stitch2 refs |
| Wave 5 | Nutrition, Profile, Fan Mode, Subscription | Mix of stitch + design-spec-only |
| Wave 6 | AI Chat, Community pages, Notifications | All have stitch3/stitch2 refs |
| Wave 7 | New pages (Privacy, ToS, Support, Referral) | All have stitch2/stitch3 refs |
| Wave 8 | Bottom sheets (Cooking Session, Journaling) | stitch3/stitch4 refs |
