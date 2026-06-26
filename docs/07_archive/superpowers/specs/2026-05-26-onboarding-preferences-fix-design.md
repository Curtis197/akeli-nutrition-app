# Onboarding Preferences Fix — Design Spec
**Date:** 2026-05-26
**Branch:** fix-compliance-and-router-issues-814be
**Source:** App review #3 (preference page not accounted) + review #2 (slider UX, silent validation block)

---

## Scope

Three coordinated fixes to the onboarding flow:

1. **Add "Inspirations Régionales"** to `_StepPreferences` — the section was in the stitch design but was never implemented; `cuisinePreferences` already exists in the model and is already sent by `complete-onboarding`
2. **Replace timeline Slider with +/− stepper** in `_StepGoals` — review #2 flagged the slider as too imprecise
3. **Add validation feedback** so a blocked "Suivant" button shows an explanatory snackbar instead of silently doing nothing

Step count stays at 7. No structural changes to `OnboardingPage` or `canAdvance`.

---

## Data Layer

### Migration
New file: `supabase/migrations/20260526000001_add_occidental_food_region.sql`

```sql
INSERT INTO food_region (code, name_fr, name_en, name_es, name_pt)
VALUES ('occidental', 'Occident', 'Occidental', 'Occidental', 'Ocidental')
ON CONFLICT (code) DO NOTHING;
```

### `OnboardingNotifier` — new method
`updateCuisineRegion(String code)` in `onboarding_data.dart`:
- Sets `cuisinePreferences = [code]` (single-select enforced at the notifier level)
- If `code` is already the current selection, sets `cuisinePreferences = []` (deselect/toggle)
- No change to `canAdvance` — regional preference is optional

### Submit body
`onboarding_page.dart` `_submit()` already sends `'cuisine_preferences': d.cuisinePreferences`. No change needed.

---

## `_StepPreferences` UI — "Inspirations Régionales" section

Added as a third card below the existing allergies card.

**Header:** "Inspirations Régionales"
**Subtitle:** "Sélectionnez votre région de prédilection pour des recommandations ciblées."

**Regions (in order):**

| Code | Label (FR) |
|---|---|
| `west_africa` | Afrique de l'Ouest |
| `east_africa` | Afrique de l'Est |
| `north_africa` | Afrique du Nord |
| `central_africa` | Afrique Centrale |
| `south_africa` | Afrique Australe |
| `caribbean` | Caraïbes |
| `occidental` | Occident |

**Tile design:** `Column` of animated tiles — same selection style as the activity level tiles in `_StepProfile` (border + background highlight on selected). Each tile has `Icons.public_rounded` on the left, the label text, and a radio circle (`Icons.radio_button_checked` / `Icons.radio_button_off`) on the right.

**Interaction:** Tap selects; tap the selected tile deselects (optional field). Calls `notifier.updateCuisineRegion(code)`.

---

## `_StepGoals` — Timeline Stepper

Replace the `SliderTheme` + `Slider` block with a `Row`:

```
[ Icons.remove_circle_outline_rounded ]  "6 mois"  [ Icons.add_circle_rounded ]
```

- Minus taps call `notifier.updateGoals(timelineMonths: data.timelineMonths - 1)`, clamped to min 1
- Plus taps call `notifier.updateGoals(timelineMonths: data.timelineMonths + 1)`, clamped to max 12
- At min/max bounds, the respective button is rendered with `AkeliColors.outlineVariant` (dimmed) and `onPressed: null`
- The big month number (`56px PlusJakartaSans`) and pace chip (Intense/Modéré/Durable) above stay unchanged
- Row labels "1 mois" / "12 mois" are removed (no longer needed)

---

## Validation Feedback

In `_OnboardingPageState._next()`, after `if (!notifier.canAdvance(_currentStep)) return;`, insert a `ScaffoldMessenger.showSnackBar` before the early return:

| Step index | Message |
|---|---|
| 1 | "Veuillez accepter les deux conditions pour continuer." |
| 2 | "Veuillez entrer votre prénom pour continuer." |
| 3 | "Veuillez entrer votre poids cible pour continuer." |

Steps 0, 4, 5, 6 always advance — no message needed.

Snackbar style: default duration (4s), no action.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/migrations/20260526000001_add_occidental_food_region.sql` | NEW — adds `occidental` region |
| `lib/features/auth/onboarding_data.dart` | Add `updateCuisineRegion()` method |
| `lib/features/auth/onboarding_page.dart` | `_StepPreferences` + `_StepGoals` + `_next()` feedback |

No changes to `complete-onboarding/index.ts`, `onboarding_data.dart` model fields, or `canAdvance` logic.

---

## Out of Scope

- All other app-review issues (profile page mock data, nav back buttons, home page health parameters, meal plan generation, community groups, recipe filters) — tracked in `app-review` file, addressed separately
- Multi-region selection — deferred; data model already supports it when needed
- "Corne de l'Afrique" / "Océan Indien" as distinct regions — deferred; east_africa covers Horn of Africa for now
