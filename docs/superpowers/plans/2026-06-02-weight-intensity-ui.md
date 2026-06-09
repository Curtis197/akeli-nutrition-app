# Weight Loss Intensity UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the weight loss intensity badge (Intense / Modéré / Durable) in both the onboarding goals step and the settings health profile page.

**Architecture:** Extract a shared `IntensityBadge` widget that computes intensity from kg/month. Restore it in onboarding `_StepGoals` (convert to stateful, add target-weight field + slider + motivations). Wire it into the existing "Durée cible" block in `HealthProfilePage`.

**Tech Stack:** Flutter / Dart, Riverpod, `AkeliColors` design tokens

---

## File Map

| File | Change |
|------|--------|
| `lib/features/settings/widgets/intensity_badge.dart` | **Create** — shared stateless widget |
| `lib/features/auth/onboarding_page.dart` | **Modify** — convert `_StepGoals` to stateful, add new `_StepCard` |
| `lib/features/settings/health_profile_page.dart` | **Modify** — add intensity badge after "Durée cible" label |

No DB changes. No migration. `OnboardingData.targetWeight`, `timelineMonths`, `motivations` already exist in the model.

---

## Task 1: Create `IntensityBadge` widget

**Files:**
- Create: `lib/features/settings/widgets/intensity_badge.dart`

### Background

`AkeliColors` tokens used:
- Intense (≥ 2 kg/month): background `AkeliColors.error.withValues(alpha: 0.12)`, text `AkeliColors.error`
- Modéré (1–2 kg/month): background `AkeliColors.tertiaryFixed`, text `AkeliColors.onTertiaryFixed`
- Durable (< 1 kg/month): background `AkeliColors.secondaryContainer`, text `AkeliColors.onSecondaryContainer`

Returns `SizedBox.shrink()` when any input is null, zero, or the weight delta is ≤ 0 (no loss/gain goal).

- [ ] **Step 1: Create the widget file**

```dart
// lib/features/settings/widgets/intensity_badge.dart

import 'package:akeli/core/logger.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

// ignore: unused_element
final _logger = appLogger;

/// Pill badge showing weight-loss pace: Intense / Modéré / Durable.
///
/// Returns SizedBox.shrink() when inputs are insufficient to compute.
class IntensityBadge extends StatelessWidget {
  final double? currentKg;
  final double? targetKg;
  /// Timeline in months (use weeks / 4.33 to convert from weeks).
  final double? months;

  const IntensityBadge({
    super.key,
    required this.currentKg,
    required this.targetKg,
    required this.months,
  });

  static (String label, Color bg, Color fg) _compute(double kgPerMonth) {
    if (kgPerMonth >= 2) {
      return (
        'Intense',
        AkeliColors.error.withValues(alpha: 0.12),
        AkeliColors.error,
      );
    } else if (kgPerMonth >= 1) {
      return (
        'Modéré',
        AkeliColors.tertiaryFixed,
        AkeliColors.onTertiaryFixed,
      );
    } else {
      return (
        'Durable',
        AkeliColors.secondaryContainer,
        AkeliColors.onSecondaryContainer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentKg == null ||
        targetKg == null ||
        months == null ||
        months! <= 0) {
      return const SizedBox.shrink();
    }
    final delta = (targetKg! - currentKg!).abs();
    if (delta <= 0) return const SizedBox.shrink();

    final kgPerMonth = delta / months!;
    final (label, bg, fg) = _compute(kgPerMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify the file compiles (no import errors)**

```powershell
dart analyze lib/features/settings/widgets/intensity_badge.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```powershell
git add lib/features/settings/widgets/intensity_badge.dart
git commit -m "feat(ui): add shared IntensityBadge widget (Intense/Modéré/Durable)"
```

---

## Task 2: Restore intensity UI in onboarding `_StepGoals`

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart`

### Background

`_StepGoals` is currently a `ConsumerWidget` (stateless). We need a `ConsumerStatefulWidget` to own a `TextEditingController` for the motivations field. Target weight reuses the existing `_MetricField` widget (which manages its own controller internally).

The new `_StepCard` to insert goes **between** the muscle goal card (ends ~line 1340) and the cooking time card (starts ~line 1344). Order: target weight + intensity row + timeline slider + motivations.

`OnboardingData.timelineMonths` default is `6`. `OnboardingData.targetWeight` is `double?`. `OnboardingData.motivations` is `String` defaulting to `''`.

- [ ] **Step 1: Add import for `IntensityBadge` at top of `onboarding_page.dart`**

Find the block of imports at the top of `lib/features/auth/onboarding_page.dart`. Add one line after the last local import:

```dart
import '../settings/widgets/intensity_badge.dart';
```

- [ ] **Step 2: Convert `_StepGoals` class declaration from `ConsumerWidget` to `ConsumerStatefulWidget`**

Replace (around line 1215):

```dart
class _StepGoals extends ConsumerWidget {
  final int step;
  const _StepGoals({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_StepGoals build()');
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
```

With:

```dart
class _StepGoals extends ConsumerStatefulWidget {
  final int step;
  const _StepGoals({required this.step});

  @override
  ConsumerState<_StepGoals> createState() => _StepGoalsState();
}

class _StepGoalsState extends ConsumerState<_StepGoals> {
  late final TextEditingController _motivationsCtrl;

  @override
  void initState() {
    super.initState();
    _motivationsCtrl = TextEditingController(
      text: ref.read(onboardingProvider).motivations,
    );
  }

  @override
  void dispose() {
    _motivationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    appLogger.provider('_StepGoals build()');
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
```

- [ ] **Step 3: Add the new `_StepCard` (target weight + intensity + timeline + motivations)**

Locate the `const SizedBox(height: AkeliSpacing.lg),` that sits between the muscle goal card and the cooking time card (around line 1342). Insert the new card **after** that spacer, before the cooking time card:

```dart
          const SizedBox(height: AkeliSpacing.lg),

          // ── Target weight + timeline ──────────────────────────────────────
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('POIDS CIBLE',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                _MetricField(
                  value: data.targetWeight?.toString() ?? '',
                  suffix: 'kg',
                  onChanged: (v) {
                    appLogger.userAction('Target weight changed',
                        screen: 'OnboardingPage',
                        metadata: {'value': v});
                    notifier.updateGoals(targetWeight: double.tryParse(v));
                  },
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DÉLAI ESTIMÉ',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    IntensityBadge(
                      currentKg: data.weight,
                      targetKg: data.targetWeight,
                      months: data.timelineMonths.toDouble(),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.md),
                Center(
                  child: RichText(
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
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AkeliColors.secondaryContainer,
                    inactiveTrackColor: AkeliColors.surfaceContainerHighest,
                    thumbColor: AkeliColors.surfaceContainerLowest,
                    overlayColor:
                        AkeliColors.primary.withValues(alpha: 0.1),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 14),
                    trackHeight: 10,
                  ),
                  child: Slider(
                    value: data.timelineMonths.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    onChanged: (v) {
                      appLogger.userAction('Timeline months changed',
                          screen: 'OnboardingPage',
                          metadata: {'months': v.round()});
                      notifier.updateGoals(timelineMonths: v.round());
                    },
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
                const SizedBox(height: AkeliSpacing.xl),
                Text('VOS MOTIVATIONS',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AkeliRadius.sm),
                  ),
                  child: TextField(
                    controller: _motivationsCtrl,
                    maxLines: 3,
                    onChanged: (v) {
                      appLogger.userAction('Motivations changed',
                          screen: 'OnboardingPage');
                      notifier.updateGoals(motivations: v);
                    },
                    style: GoogleFonts.inter(
                        fontSize: 15, color: AkeliColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Qu\'est-ce qui vous motive ?',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: AkeliColors.onSurfaceVariant),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.all(AkeliSpacing.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
```

- [ ] **Step 4: Run `dart analyze` to verify no errors**

```powershell
dart analyze lib/features/auth/onboarding_page.dart
```

Expected: no errors (warnings about unused imports are fine).

- [ ] **Step 5: Commit**

```powershell
git add lib/features/auth/onboarding_page.dart
git commit -m "feat(onboarding): restore target weight, timeline slider, intensity badge, motivations"
```

---

## Task 3: Add intensity badge to `HealthProfilePage`

**Files:**
- Modify: `lib/features/settings/health_profile_page.dart`

### Background

The "OBJECTIF" card already has:
1. Type d'objectif chips
2. Objectif poids chips
3. Objectif muscle chips
4. Durée cible label + slider (uses `local.targetTimeWeeks`, range 4–52 weeks)

We add the intensity badge on the **same row as the "Durée cible" label** — label on the left, badge on the right. Convert weeks to months: `(local.targetTimeWeeks ?? 12) / 4.33`.

The badge uses `local.weightKg` (current) and `local.targetWeightKg` (target). Both can be null; the badge returns `SizedBox.shrink()` in that case.

- [ ] **Step 1: Add import for `IntensityBadge` to `health_profile_page.dart`**

At the top of `lib/features/settings/health_profile_page.dart`, after the existing local imports, add:

```dart
import 'widgets/intensity_badge.dart';
```

- [ ] **Step 2: Replace the plain "Durée cible" label with a Row that includes the badge**

Find (around line 419):

```dart
                      // Durée cible
                      const SettingsLabel('Durée cible'),
                      const SizedBox(height: 8),
```

Replace with:

```dart
                      // Durée cible
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SettingsLabel('Durée cible'),
                          IntensityBadge(
                            currentKg: local.weightKg,
                            targetKg: local.targetWeightKg,
                            months: (local.targetTimeWeeks ?? 12) / 4.33,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
```

- [ ] **Step 3: Run `dart analyze` to verify no errors**

```powershell
dart analyze lib/features/settings/health_profile_page.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```powershell
git add lib/features/settings/health_profile_page.dart
git commit -m "feat(settings): add intensity badge to health profile durée cible row"
```

---

## Self-Review

**Spec coverage:**
- ✅ `IntensityBadge` widget with Intense/Modéré/Durable thresholds — Task 1
- ✅ Returns `SizedBox.shrink()` on null/zero inputs — Task 1 Step 1
- ✅ Onboarding: target weight field — Task 2 Step 3
- ✅ Onboarding: "DÉLAI ESTIMÉ" label + badge row — Task 2 Step 3
- ✅ Onboarding: timeline slider 1–12 months with big "N mois" display — Task 2 Step 3
- ✅ Onboarding: motivations text field — Task 2 Step 3
- ✅ Onboarding: `_StepGoals` converted to stateful for controller lifecycle — Task 2 Step 2
- ✅ Settings: IntensityBadge on "Durée cible" row — Task 3 Step 2
- ✅ Settings: weeks-to-months conversion `/ 4.33` — Task 3 Step 2
- ✅ Logging standard: logger imported in new file, `appLogger.userAction` on all interactions — Tasks 1–3
- ✅ No DB/migration changes needed

**Type consistency check:**
- `IntensityBadge` params: `currentKg: double?`, `targetKg: double?`, `months: double?` — matches all call sites
- `data.weight` (onboarding) is `double?` → passed as `currentKg` ✅
- `data.targetWeight` (onboarding) is `double?` → passed as `targetKg` ✅
- `data.timelineMonths` is `int` → `.toDouble()` cast ✅
- `local.weightKg` (settings) is `double?` ✅
- `local.targetWeightKg` (settings) is `double?` ✅
- `(local.targetTimeWeeks ?? 12) / 4.33` is `double` ✅
