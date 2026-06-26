# Onboarding Preferences Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the missing "Inspirations Régionales" section to the onboarding preferences step, replace the imprecise timeline slider with a +/− stepper, and add validation feedback when the "Suivant" button is blocked.

**Architecture:** Three self-contained changes to two Dart files plus one new SQL migration. The `OnboardingNotifier` gains a `updateCuisineRegion()` method; the two UI steps (`_StepGoals`, `_StepPreferences`) are modified in-place; `_next()` gets a validation message map. No structural changes to the page or provider.

**Tech Stack:** Flutter/Dart, Riverpod (Notifier), Supabase SQL migration, `google_fonts`, `flutter_riverpod`

---

## File Map

| File | Action |
|---|---|
| `supabase/migrations/20260526000001_add_occidental_food_region.sql` | CREATE — adds `occidental` to `food_region` |
| `lib/features/auth/onboarding_data.dart` | MODIFY — add `updateCuisineRegion()` to `OnboardingNotifier` |
| `test/features/auth/onboarding_data_test.dart` | MODIFY — add 3 tests for `updateCuisineRegion` |
| `lib/features/auth/onboarding_page.dart` | MODIFY — `_next()` snackbar + `_StepGoals` stepper + `_StepPreferences` region section + `_RegionTile` widget |

---

## Task 1: DB Migration — add `occidental` food region

**Files:**
- Create: `supabase/migrations/20260526000001_add_occidental_food_region.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- Add occidental (Europe + North America) as a food region option for onboarding
INSERT INTO food_region (code, name_fr, name_en, name_es, name_pt)
VALUES ('occidental', 'Occident', 'Occidental', 'Occidental', 'Ocidental')
ON CONFLICT (code) DO NOTHING;
```

- [ ] **Step 2: Verify the file exists and has correct content**

```powershell
Get-Content "supabase\migrations\20260526000001_add_occidental_food_region.sql"
```

Expected: the INSERT statement above.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260526000001_add_occidental_food_region.sql
git commit -m "feat: add occidental food region for onboarding"
```

---

## Task 2: `updateCuisineRegion()` in `OnboardingNotifier`

**Files:**
- Modify: `lib/features/auth/onboarding_data.dart`
- Modify: `test/features/auth/onboarding_data_test.dart`

- [ ] **Step 1: Write the failing tests**

Open `test/features/auth/onboarding_data_test.dart`. Add these three tests inside the existing `group('OnboardingNotifier', ...)` block, after the last existing test:

```dart
test('updateCuisineRegion sets single region', () {
  final c = _container();
  addTearDown(c.dispose);
  c.read(onboardingProvider.notifier).updateCuisineRegion('west_africa');
  expect(c.read(onboardingProvider).cuisinePreferences, ['west_africa']);
});

test('updateCuisineRegion replaces previous selection', () {
  final c = _container();
  addTearDown(c.dispose);
  c.read(onboardingProvider.notifier).updateCuisineRegion('west_africa');
  c.read(onboardingProvider.notifier).updateCuisineRegion('north_africa');
  expect(c.read(onboardingProvider).cuisinePreferences, ['north_africa']);
});

test('updateCuisineRegion deselects when same code tapped twice', () {
  final c = _container();
  addTearDown(c.dispose);
  c.read(onboardingProvider.notifier).updateCuisineRegion('west_africa');
  c.read(onboardingProvider.notifier).updateCuisineRegion('west_africa');
  expect(c.read(onboardingProvider).cuisinePreferences, isEmpty);
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/features/auth/onboarding_data_test.dart --reporter expanded
```

Expected: 3 new tests FAIL with `NoSuchMethodError` (method not yet defined).

- [ ] **Step 3: Add `updateCuisineRegion()` to `OnboardingNotifier`**

Open `lib/features/auth/onboarding_data.dart`. Inside `OnboardingNotifier`, after the `updatePreferences()` method (around line 123), add:

```dart
void updateCuisineRegion(String code) {
  final current = state.cuisinePreferences;
  state = state.copyWith(
    cuisinePreferences: current.length == 1 && current[0] == code ? [] : [code],
  );
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/features/auth/onboarding_data_test.dart --reporter expanded
```

Expected: all 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/onboarding_data.dart test/features/auth/onboarding_data_test.dart
git commit -m "feat: add updateCuisineRegion to OnboardingNotifier"
```

---

## Task 3: Validation snackbar in `_next()`

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart` — `_next()` method (lines ~39–49)

- [ ] **Step 1: Replace `_next()` with the snackbar version**

Find and replace the entire `_next()` method in `_OnboardingPageState`:

```dart
void _next() {
  _logger.userAction('Onboarding next tapped', screen: 'OnboardingPage', metadata: {'step': _currentStep});
  final notifier = ref.read(onboardingProvider.notifier);
  if (!notifier.canAdvance(_currentStep)) {
    const messages = {
      1: 'Veuillez accepter les deux conditions pour continuer.',
      2: 'Veuillez entrer votre prénom pour continuer.',
      3: 'Veuillez entrer votre poids cible pour continuer.',
    };
    final msg = messages[_currentStep];
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
    return;
  }
  if (_currentStep < _totalSteps - 1) {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  } else {
    _submit();
  }
}
```

- [ ] **Step 2: Verify the app compiles**

```bash
flutter analyze lib/features/auth/onboarding_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_page.dart
git commit -m "feat: show validation snackbar when onboarding step cannot advance"
```

---

## Task 4: Replace timeline Slider with +/− stepper in `_StepGoals`

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart` — `_StepGoalsState.build()` (around lines 1336–1369)

- [ ] **Step 1: Remove the Slider block and replace with stepper**

In `_StepGoalsState.build()`, find and remove this entire block (the `SliderTheme` + trailing `Row` with "1 mois"/"12 mois"):

```dart
SliderTheme(
  data: SliderThemeData(
    activeTrackColor: AkeliColors.secondaryContainer,
    inactiveTrackColor: AkeliColors.surfaceContainerHighest,
    thumbColor: AkeliColors.surfaceContainerLowest,
    overlayColor: AkeliColors.primary.withValues(alpha: 0.1),
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
    trackHeight: 10,
  ),
  child: Slider(
    value: data.timelineMonths.toDouble(),
    min: 1,
    max: 12,
    divisions: 11,
    onChanged: (v) =>
        notifier.updateGoals(timelineMonths: v.round()),
  ),
),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('1 mois',
        style: GoogleFonts.inter(
            fontSize: 10,
            color: AkeliColors.onSurfaceVariant,
            letterSpacing: 0.1)),
    Text('12 mois',
        style: GoogleFonts.inter(
            fontSize: 10,
            color: AkeliColors.onSurfaceVariant,
            letterSpacing: 0.1)),
  ],
),
```

Replace with:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    IconButton(
      icon: Icon(
        Icons.remove_circle_outline_rounded,
        color: data.timelineMonths <= 1
            ? AkeliColors.outlineVariant
            : AkeliColors.primary,
        size: 36,
      ),
      onPressed: data.timelineMonths <= 1
          ? null
          : () {
              _logger.userAction('Timeline months decreased',
                  screen: 'OnboardingPage',
                  metadata: {'months': data.timelineMonths - 1});
              notifier.updateGoals(
                  timelineMonths: data.timelineMonths - 1);
            },
    ),
    const SizedBox(width: AkeliSpacing.lg),
    RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${data.timelineMonths} ',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: AkeliColors.primary,
                height: 1),
          ),
          TextSpan(
            text: 'mois',
            style: GoogleFonts.inter(
                fontSize: 20,
                color: AkeliColors.onSurfaceVariant),
          ),
        ],
      ),
    ),
    const SizedBox(width: AkeliSpacing.lg),
    IconButton(
      icon: Icon(
        Icons.add_circle_rounded,
        color: data.timelineMonths >= 12
            ? AkeliColors.outlineVariant
            : AkeliColors.primary,
        size: 36,
      ),
      onPressed: data.timelineMonths >= 12
          ? null
          : () {
              _logger.userAction('Timeline months increased',
                  screen: 'OnboardingPage',
                  metadata: {'months': data.timelineMonths + 1});
              notifier.updateGoals(
                  timelineMonths: data.timelineMonths + 1);
            },
    ),
  ],
),
```

Note: the `RichText` with the big month number that was already above the slider stays exactly as-is — only the slider + label row is replaced.

- [ ] **Step 2: Verify the app compiles**

```bash
flutter analyze lib/features/auth/onboarding_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_page.dart
git commit -m "feat: replace timeline slider with +/- stepper in onboarding goals"
```

---

## Task 5: Add "Inspirations Régionales" to `_StepPreferences`

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart` — `_StepPreferencesState` + new `_RegionTile` widget

- [ ] **Step 1: Add `_kRegions` constant to `_StepPreferencesState`**

Inside `class _StepPreferencesState`, after the `_allergyCtrl` field declaration, add:

```dart
static const _kRegions = [
  ('west_africa',    'Afrique de l\'Ouest'),
  ('east_africa',    'Afrique de l\'Est'),
  ('north_africa',   'Afrique du Nord'),
  ('central_africa', 'Afrique Centrale'),
  ('south_africa',   'Afrique Australe'),
  ('caribbean',      'Caraïbes'),
  ('occidental',     'Occident'),
];
```

- [ ] **Step 2: Add the region card to `_StepPreferencesState.build()`**

In `_StepPreferencesState.build()`, find the closing of the allergies `_StepCard` — after the `if (data.allergies.isNotEmpty)` block that ends with `],` and the card closing `),`. Add the following immediately after (before the final `],` that closes the outer `Column`):

```dart
const SizedBox(height: AkeliSpacing.xl),
_StepCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Inspirations Régionales',
        style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface),
      ),
      const SizedBox(height: AkeliSpacing.xs),
      Text(
        'Sélectionnez votre région de prédilection pour des recommandations ciblées.',
        style: GoogleFonts.inter(
            fontSize: 13, color: AkeliColors.onSurfaceVariant),
      ),
      const SizedBox(height: AkeliSpacing.md),
      ..._kRegions.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: AkeliSpacing.xs),
            child: _RegionTile(
              label: r.$2,
              selected: data.cuisinePreferences.isNotEmpty &&
                  data.cuisinePreferences[0] == r.$1,
              onTap: () {
                _logger.userAction('Region selected',
                    screen: 'OnboardingPage',
                    metadata: {'region': r.$1});
                notifier.updateCuisineRegion(r.$1);
              },
            ),
          )),
    ],
  ),
),
```

- [ ] **Step 3: Add `_RegionTile` widget class**

At the bottom of `onboarding_page.dart`, after the last widget class (`_SummaryCard`), add:

```dart
// ── Region tile ──────────────────────────────────────────────────────────────

class _RegionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AkeliColors.secondaryContainer.withValues(alpha: 0.4)
              : AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border: Border.all(
            color: selected
                ? AkeliColors.secondaryContainer
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.public_rounded,
              color: selected
                  ? AkeliColors.primary
                  : AkeliColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AkeliColors.onSurface,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AkeliColors.primary
                  : AkeliColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify the app compiles with no errors**

```bash
flutter analyze lib/features/auth/onboarding_page.dart
```

Expected: no errors, no warnings on the new code.

- [ ] **Step 5: Run the full test suite**

```bash
flutter test --reporter expanded
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/onboarding_page.dart
git commit -m "feat: add Inspirations Régionales section to onboarding preferences"
```

---

## Self-Review Checklist

- [x] **Migration** — `occidental` inserted with all 4 language columns ✓
- [x] **`updateCuisineRegion`** — select, replace, deselect all covered by tests ✓
- [x] **Validation snackbar** — messages defined for steps 1, 2, 3; steps 0/4/5/6 always pass so no message needed ✓
- [x] **Stepper** — clamped at 1 and 12, buttons dim at bounds, logging preserved ✓
- [x] **Region tiles** — `_kRegions` const matches seed data + `occidental`, `updateCuisineRegion` wired correctly, `_RegionTile` added at file bottom ✓
- [x] **No placeholders** — all code is complete and exact ✓
- [x] **Type consistency** — `updateCuisineRegion(String)` defined in Task 2, used in Task 5 ✓
