# Health Profile & Goals Page — Design Spec

**Date:** 2026-06-02
**Feature:** `HealthProfilePage` — update health parameters and nutritional goals
**Branch:** fix-compliance-and-router-issues-814be

---

## Summary

A new settings page that lets users update their health biometrics and nutritional objective post-onboarding. Saving auto-recomputes the calorie and macro targets using `NutritionCalculatorService` and invalidates the nutrition plan provider.

---

## 1. Data Model

### New file: `lib/features/settings/models/health_profile_model.dart`

Immutable model combining fields from `user_health_profile` and `user_goal`:

| Field | Type | Source table |
|---|---|---|
| `sex` | `String?` | `user_health_profile` — `'male' \| 'female' \| 'other'` |
| `birthDate` | `DateTime?` | `user_health_profile` |
| `heightCm` | `double?` | `user_health_profile` |
| `weightKg` | `double?` | `user_health_profile` |
| `targetWeightKg` | `double?` | `user_health_profile` |
| `activityLevel` | `String?` | `user_health_profile` — `'sedentary' \| 'light' \| 'moderate' \| 'active' \| 'very_active'` |
| `weightGoal` | `String?` | `user_health_profile` — `'loss' \| 'maintenance' \| 'gain'` |
| `muscleGoal` | `String?` | `user_health_profile` — `'loss' \| 'maintenance' \| 'gain'` |
| `startingWeightKg` | `double?` | `user_health_profile` |
| `targetTimeWeeks` | `int?` | `user_health_profile` |
| `goalType` | `String?` | `user_goal` — `'weight_loss' \| 'muscle_gain' \| 'maintenance' \| 'health' \| 'performance'` |

`cooking_time` is deliberately excluded — it is managed by `UserPreferencesModel` / `PreferencesPage`.

The model exposes a `copyWith(...)` with a `clearBirthDate` escape hatch (following the existing `clearCuisineRegion` pattern).

---

## 2. Provider

### New file: `lib/providers/health_profile_provider.dart`

`HealthProfileNotifier extends AutoDisposeAsyncNotifier<HealthProfileModel>`

**`build()`**
- Guards on `currentUserProvider` (returns empty model if null)
- Fires two parallel Supabase queries:
  - `user_health_profile` — all columns, `.maybeSingle()`
  - `user_goal` — `goal_type`, filter `is_active = true`, `.maybeSingle()`
- Maps results to `HealthProfileModel`
- Full structured logging (BEFORE/AFTER/ERROR) per CLAUDE.md

**`save(HealthProfileModel updated)`**
1. Upsert `user_health_profile` (`onConflict: 'user_id'`) with all non-null fields
2. Compute derived targets:
   - age from `birthDate` (if available, else skip BMR computation)
   - BMR → TDEE → calorie goal via `NutritionCalculatorService`
   - Macro grams via `getDefaultMacros(goalType)` + `calculateMacroGrams`
3. Delete all `user_goal` rows for the user
4. Insert new active `user_goal` row with `goal_type`, `calorie_goal`, `protein_goal`, `fat_goal`, `is_active: true`
5. `ref.invalidate(nutritionPlanProvider)` — forces nutrition page to reload
6. `state = AsyncData(updated)`

**Activity level mapping** — `NutritionCalculatorService.calculateTDEE` uses different string keys than the DB constraint. The provider maps before computing:

| DB value | Calculator value |
|---|---|
| `'sedentary'` | `'sedentary'` |
| `'light'` | `'lightly_active'` |
| `'moderate'` | `'moderately_active'` |
| `'active'` | `'very_active'` |
| `'very_active'` | `'extremely_active'` |

If `birthDate` is null, skip BMR/TDEE step and insert `user_goal` with only `goal_type` (calorie/macro targets remain null).

Error handling: `PostgrestException` → `_logger.rls(...)` on code `42501`, else `_logger.db('ERROR | ...')`, rethrow.

---

## 3. Page

### New file: `lib/features/settings/health_profile_page.dart`

`HealthProfilePage extends ConsumerStatefulWidget`

**Local state:**
- `HealthProfileModel? _local` — initialized lazily on first `data` build (same pattern as `PreferencesPage`)
- `bool _saving`
- Text controllers for numeric fields: `_heightCtrl`, `_weightCtrl`, `_targetWeightCtrl`

**AppBar:** Frosted glass, same pattern as `PreferencesPage` — title "Santé & Objectifs", back button with `context.pop()`.

**Body — `SingleChildScrollView`:**

### Section: PARAMÈTRES DE SANTÉ

Card containing:
- **Sexe** — `_ChipSelector` with 3 options: `('male', 'Homme')`, `('female', 'Femme')`, `('other', 'Autre')`
- **Date de naissance** — `ListTile`-style row, tapping calls `showDatePicker` (range: 1920–today), displays formatted date or "Non renseignée"
- **Taille** — `TextField` with `TextInputType.number`, suffix `cm`
- **Poids actuel** — `TextField`, suffix `kg`
- **Poids cible** — `TextField`, suffix `kg`
- **Niveau d'activité** — 5 `_RadioRow` entries:
  - `('sedentary', 'Sédentaire', Icons.weekend_outlined)`
  - `('light', 'Légèrement actif', Icons.directions_walk_rounded)`
  - `('moderate', 'Modérément actif', Icons.directions_bike_outlined)`
  - `('active', 'Actif', Icons.fitness_center_rounded)`
  - `('very_active', 'Très actif', Icons.bolt_rounded)`

### Section: OBJECTIF

Card containing:
- **Type d'objectif** — `Wrap` of 5 `FilterChip`s (single-select, same style as region chips in `PreferencesPage`):
  - `('weight_loss', 'Perte de poids')`
  - `('muscle_gain', 'Prise de muscle')`
  - `('maintenance', 'Maintien')`
  - `('health', 'Santé')`
  - `('performance', 'Performance')`
- **Objectif poids** — `_ChipSelector`: `('loss', 'Perdre')`, `('maintenance', 'Maintenir')`, `('gain', 'Prendre')`
- **Objectif muscle** — `_ChipSelector`: `('loss', 'Perdre')`, `('maintenance', 'Maintenir')`, `('gain', 'Prendre')`
- **Durée cible** — `Slider` from 4 to 52 (divisions: 48), label "{n} semaines", displays value below

**Bottom:** Full-width `FilledButton` "Enregistrer" — disabled while `_saving`.

---

## 4. Shared Widgets Extraction

Private helper widgets `_SectionHeader`, `_Card`, `_Label`, `_RadioRow` are currently inlined in `preferences_page.dart`. They will be extracted to:

### New file: `lib/features/settings/widgets/settings_widgets.dart`

Exports: `SettingsSectionHeader`, `SettingsCard`, `SettingsLabel`, `SettingsRadioRow`

`preferences_page.dart` updated to import from this file (no behavioral change).

`health_profile_page.dart` adds `_ChipSelector` — a local private widget (3-option inline chip group) not worth sharing since it's simple and only used here.

---

## 5. Save Flow

```
tap "Enregistrer"
  → setState(_saving = true)
  → parse text controllers → validate (positive numbers, no hard block for blanks)
  → ref.read(healthProfileProvider.notifier).save(_local!)
      → upsert user_health_profile
      → compute BMR/TDEE/calorie/macros (if birthDate known)
      → delete+insert user_goal
      → invalidate nutritionPlanProvider
  → snackbar: "Profil mis à jour · {kcal} kcal/jour · {protein}g protéines"
     (or "Profil mis à jour" if birthDate not set)
  → context.pop()
  on error → snackbar: "Erreur: {message}", stay on page
  → setState(_saving = false)
```

---

## 6. Routing & Navigation

### `lib/core/router.dart`
- Add `static const healthProfile = '/health-profile'` to `AkeliRoutes`
- Register `GoRoute(path: AkeliRoutes.healthProfile, builder: (_, __) => const HealthProfilePage())`

### `lib/features/settings/settings_page.dart`
Add menu item in "Menu" section, after "Préférences":
```dart
_MenuItem(
  icon: Icons.monitor_heart_outlined,
  label: 'Santé & Objectifs',
  onTap: () => context.push(AkeliRoutes.healthProfile),
),
```

---

## 7. Files Created / Modified

| Action | File |
|---|---|
| Create | `lib/features/settings/health_profile_page.dart` |
| Create | `lib/features/settings/models/health_profile_model.dart` |
| Create | `lib/providers/health_profile_provider.dart` |
| Create | `lib/features/settings/widgets/settings_widgets.dart` |
| Modify | `lib/features/settings/preferences_page.dart` — import shared widgets |
| Modify | `lib/core/router.dart` — add route |
| Modify | `lib/features/settings/settings_page.dart` — add menu item |

---

## 8. Logging

All files follow CLAUDE.md mandatory logging standard:
- Provider `build()` + `onDispose()` lifecycle
- BEFORE/AFTER/ERROR on every DB operation
- `userAction` on every tap, field change, date pick
- `provider` on every `AsyncValue` state transition
- Sensitive fields (`weightKg`, `heightCm`) are not masked (not PII per spec) but no passwords/tokens logged
