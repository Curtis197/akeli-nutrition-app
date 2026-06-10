# Cooking Mode Landscape Layout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a landscape-optimised layout to `CookingModePage` that shows side-arrow navigation, media as the centrepiece when present, instruction text + ingredients in a sliding info panel, and a compact timer pill — without touching the existing portrait layout.

**Architecture:** `OrientationBuilder` gates portrait vs landscape. All new code is file-private widgets added to `cooking_mode_page.dart`. A new `bool _infoOpen` state field controls the side panel; it is reset to `false` in `_goToStep`. Portrait layout is entirely unchanged.

**Tech Stack:** Flutter widget tests (`flutter_test`), `OrientationBuilder`, `AnimatedContainer`, `Stack`, `CachedNetworkImage`, `GoogleFonts`, `AkeliColors`.

---

## File map

| Action | Path | Responsibility |
|---|---|---|
| Modify | `lib/features/cooking/cooking_mode_page.dart` | All new private widgets + `OrientationBuilder` wiring |
| Create | `test/features/cooking/cooking_mode_page_test.dart` | Widget tests for landscape behaviour |

---

### Task 1: Test scaffold + `_infoOpen` state

**Files:**
- Create: `test/features/cooking/cooking_mode_page_test.dart`
- Modify: `lib/features/cooking/cooking_mode_page.dart`

- [ ] **Step 1: Create the test file with helpers**

```dart
// test/features/cooking/cooking_mode_page_test.dart
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/cooking/cooking_mode_page.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── helpers ────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(theme: buildLightTheme(), home: child),
    );

void _setLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 400);
  tester.view.devicePixelRatio = 1.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Recipe _recipe({
  int stepCount = 3,
  bool withTimer = false,
  bool withImage = false,
  bool withIngredients = false,
}) {
  final ingredients = withIngredients
      ? [
          const RecipeIngredient(
              ingredientId: 'i1',
              name: 'Oignons',
              quantity: 2,
              unit: 'pcs',
              isOptional: false),
          const RecipeIngredient(
              ingredientId: 'i2',
              name: 'Huile',
              quantity: 2,
              unit: 'cs',
              isOptional: false),
        ]
      : <RecipeIngredient>[];

  final steps = List.generate(
    stepCount,
    (i) => RecipeStep(
      stepNumber: i + 1,
      instruction: 'Instruction étape ${i + 1}',
      durationMin: withTimer ? 3 : null,
      imageUrl: withImage ? 'https://example.com/img.jpg' : null,
      ingredientIds: withIngredients ? ['i1', 'i2'] : [],
    ),
  );

  return Recipe(
    id: 'r1',
    creatorId: 'c1',
    title: 'Test',
    imageUrls: const [],
    prepTimeMin: 5,
    cookTimeMin: 10,
    servings: 2,
    difficulty: 'easy',
    averageRating: 0,
    averageRatingTaste: 0,
    averageRatingEase: 0,
    averageRatingSatiety: 0,
    ratingCount: 0,
    commentCount: 0,
    likeCount: 0,
    saveCount: 0,
    isSaved: false,
    isLiked: false,
    isPublished: true,
    ingredients: ingredients,
    steps: steps,
    tagIds: const [],
    createdAt: DateTime(2026),
  );
}

// ── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('CookingModePage landscape', () {
    testWidgets('top bar shows step counter in landscape', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(CookingModePage(recipe: _recipe())));
      await tester.pump();

      expect(find.text('Étape 1 / 3'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test — expect FAIL** (landscape layout not yet implemented)

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

Expected: test may pass (top bar is always rendered) or overflow error. Either is fine at this point; we are establishing the scaffold.

- [ ] **Step 3: Add `_infoOpen` field to `_CookingModePageState` and reset it in `_goToStep`**

In `lib/features/cooking/cooking_mode_page.dart`, locate `_CookingModePageState` and add the field next to the existing state fields:

```dart
// after: final Set<String> _checkedIngredients = {};
bool _infoOpen = false;
```

Update `_goToStep`:

```dart
void _goToStep(int index) {
  if (index < 0 || index >= widget.recipe.steps.length) return;
  _logger.userAction('Step navigation', screen: 'CookingModePage',
      metadata: {'from': _currentStepIndex + 1, 'to': index + 1});
  setState(() {
    _currentStepIndex = index;
    _infoOpen = false;
    _resetTimer();
  });
}
```

- [ ] **Step 4: Run the test — expect PASS**

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

- [ ] **Step 5: Commit**

```
git add lib/features/cooking/cooking_mode_page.dart test/features/cooking/cooking_mode_page_test.dart
git commit -m "test: add cooking mode landscape test scaffold; add _infoOpen state"
```

---

### Task 2: `_TimerPill` widget

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`
- Modify: `test/features/cooking/cooking_mode_page_test.dart`

- [ ] **Step 1: Add a failing test for the timer pill in landscape**

Append inside `group('CookingModePage landscape', ...)`:

```dart
testWidgets('shows timer pill in landscape when step has duration', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(withTimer: true)),
  ));
  await tester.pump();

  // Timer pill displays MM:SS format
  expect(find.text('03:00'), findsOneWidget);
  // Play icon present (timer not yet running)
  expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
});

testWidgets('no timer pill in landscape when step has no duration', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(withTimer: false)),
  ));
  await tester.pump();

  expect(find.text('03:00'), findsNothing);
});
```

- [ ] **Step 2: Run — expect FAIL**

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

Expected: '03:00' not found (only portrait `_TimerWidget` is rendered, not a pill).

- [ ] **Step 3: Add `_TimerPill` private widget at the bottom of `cooking_mode_page.dart`**

```dart
class _TimerPill extends StatelessWidget {
  final int remainingSeconds;
  final bool isRunning;
  final VoidCallback onToggle;

  const _TimerPill({
    required this.remainingSeconds,
    required this.isRunning,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined,
                size: 14, color: AkeliColors.primary),
            const SizedBox(width: 4),
            Text(
              '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 14,
              color: AkeliColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
```

The timer pill is not yet wired into any landscape layout — that happens in later tasks. The test will still fail at this step; that is expected.

- [ ] **Step 4: Commit the widget (tests still failing — that's fine)**

```
git add lib/features/cooking/cooking_mode_page.dart test/features/cooking/cooking_mode_page_test.dart
git commit -m "feat: add _TimerPill widget for landscape cooking mode"
```

---

### Task 3: `_LandscapeTextCenter` widget

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`

No new tests yet — this widget is not reachable until `_LandscapeBody` is wired in Task 7. We build bottom-up so Task 7's tests cover it.

- [ ] **Step 1: Add `_LandscapeTextCenter` after `_TimerPill`**

```dart
class _LandscapeTextCenter extends StatelessWidget {
  final String instruction;
  final int? remainingSeconds;
  final bool timerRunning;
  final VoidCallback onTimerToggle;

  const _LandscapeTextCenter({
    required this.instruction,
    this.remainingSeconds,
    required this.timerRunning,
    required this.onTimerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AkeliRadius.xl),
      child: ColoredBox(
        color: AkeliColors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 1.5,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
              if (remainingSeconds != null) ...[
                const SizedBox(height: 10),
                _TimerPill(
                  remainingSeconds: remainingSeconds!,
                  isRunning: timerRunning,
                  onToggle: onTimerToggle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add lib/features/cooking/cooking_mode_page.dart
git commit -m "feat: add _LandscapeTextCenter widget"
```

---

### Task 4: `_LandscapeInfoPanel` widget

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`

- [ ] **Step 1: Add `_LandscapeInfoPanel` after `_LandscapeTextCenter`**

```dart
class _LandscapeInfoPanel extends StatelessWidget {
  final String instruction;
  final List<RecipeIngredient> ingredients;
  final Set<String> checked;
  final ValueChanged<RecipeIngredient> onTap;
  final ValueChanged<RecipeIngredient> onLongPress;

  const _LandscapeInfoPanel({
    required this.instruction,
    required this.ingredients,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AkeliRadius.xl),
          bottomLeft: Radius.circular(AkeliRadius.xl),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              instruction,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.5,
                color: AkeliColors.onSurface,
              ),
            ),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                color: AkeliColors.outline.withValues(alpha: 0.3),
                height: 1,
              ),
              const SizedBox(height: 10),
              ...ingredients.map((ing) {
                final isChecked = checked.contains(ing.ingredientId);
                return GestureDetector(
                  onTap: () => onTap(ing),
                  onLongPress: () => onLongPress(ing),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isChecked
                                ? AkeliColors.outline
                                : AkeliColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${ing.name}  ${ing.quantity.toStringAsFixed(ing.quantity == ing.quantity.truncate() ? 0 : 1)} ${ing.unit}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isChecked
                                  ? AkeliColors.onSurfaceVariant
                                  : AkeliColors.onSurface,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add lib/features/cooking/cooking_mode_page.dart
git commit -m "feat: add _LandscapeInfoPanel widget"
```

---

### Task 5: `_LandscapeMediaCenter` widget

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`

- [ ] **Step 1: Add `_LandscapeMediaCenter` after `_LandscapeInfoPanel`**

```dart
class _LandscapeMediaCenter extends StatelessWidget {
  final RecipeStep step;
  final int? remainingSeconds;
  final bool timerRunning;
  final VoidCallback onTimerToggle;

  const _LandscapeMediaCenter({
    required this.step,
    this.remainingSeconds,
    required this.timerRunning,
    required this.onTimerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AkeliRadius.xl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // media fill
          step.videoUrl != null
              ? RecipeVideoCard(
                  videoUrl: step.videoUrl!,
                  thumbnailUrl: step.imageUrl)
              : CachedNetworkImage(
                  imageUrl: step.imageUrl!,
                  fit: BoxFit.cover),
          // gradient scrim
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: null,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black87],
                ),
              ),
              padding:
                  const EdgeInsets.fromLTRB(12, 40, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      step.instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (remainingSeconds != null) ...[
                    const SizedBox(width: 8),
                    _TimerPill(
                      remainingSeconds: remainingSeconds!,
                      isRunning: timerRunning,
                      onToggle: onTimerToggle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add lib/features/cooking/cooking_mode_page.dart
git commit -m "feat: add _LandscapeMediaCenter widget"
```

---

### Task 6: `_LandscapeCenter` widget (info panel Stack)

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`

- [ ] **Step 1: Add `_LandscapeCenter` after `_LandscapeMediaCenter`**

```dart
class _LandscapeCenter extends StatelessWidget {
  final RecipeStep step;
  final List<RecipeIngredient> stepIngredients;
  final Set<String> checked;
  final int timerSeconds;
  final bool timerRunning;
  final bool infoOpen;
  final VoidCallback onTimerToggle;
  final ValueChanged<RecipeIngredient> onIngredientTap;
  final ValueChanged<RecipeIngredient> onIngredientLongPress;

  const _LandscapeCenter({
    required this.step,
    required this.stepIngredients,
    required this.checked,
    required this.timerSeconds,
    required this.timerRunning,
    required this.infoOpen,
    required this.onTimerToggle,
    required this.onIngredientTap,
    required this.onIngredientLongPress,
  });

  bool get _hasMedia => step.videoUrl != null || step.imageUrl != null;

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.38;

    final center = _hasMedia
        ? _LandscapeMediaCenter(
            step: step,
            remainingSeconds: step.durationMin != null ? timerSeconds : null,
            timerRunning: timerRunning,
            onTimerToggle: onTimerToggle,
          )
        : _LandscapeTextCenter(
            instruction: step.instruction,
            remainingSeconds: step.durationMin != null ? timerSeconds : null,
            timerRunning: timerRunning,
            onTimerToggle: onTimerToggle,
          );

    return Stack(
      children: [
        Positioned.fill(child: center),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: 0,
          bottom: 0,
          right: 0,
          width: infoOpen ? panelWidth : 0,
          child: OverflowBox(
            maxWidth: panelWidth,
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: panelWidth,
              child: _LandscapeInfoPanel(
                instruction: step.instruction,
                ingredients: stepIngredients,
                checked: checked,
                onTap: onIngredientTap,
                onLongPress: onIngredientLongPress,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add lib/features/cooking/cooking_mode_page.dart
git commit -m "feat: add _LandscapeCenter widget with animated info panel"
```

---

### Task 7: `_LandscapeBody` widget + navigation tests

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`
- Modify: `test/features/cooking/cooking_mode_page_test.dart`

- [ ] **Step 1: Add failing navigation tests**

Append inside `group('CookingModePage landscape', ...)`:

```dart
testWidgets('chevron-right icon advances to next step', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(CookingModePage(recipe: _recipe())));
  await tester.pump();

  expect(find.text('Étape 1 / 3'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
  await tester.pump();
  expect(find.text('Étape 2 / 3'), findsOneWidget);
});

testWidgets('chevron-left icon goes to previous step', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(), initialStepIndex: 1),
  ));
  await tester.pump();

  await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
  await tester.pump();
  expect(find.text('Étape 1 / 3'), findsOneWidget);
});

testWidgets('last step shows check icon instead of chevron', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(stepCount: 1)),
  ));
  await tester.pump();

  expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
});

testWidgets('info icon hidden when step has no ingredients', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(withIngredients: false)),
  ));
  await tester.pump();

  expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
});

testWidgets('tapping info icon opens and closes the panel', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(withIngredients: true)),
  ));
  await tester.pump();

  // Panel closed — ingredient names not visible
  expect(find.text('Oignons  2 pcs'), findsNothing);

  // Open
  await tester.tap(find.byIcon(Icons.info_outline_rounded));
  await tester.pumpAndSettle();
  expect(find.text('Oignons  2 pcs'), findsOneWidget);

  // Close
  await tester.tap(find.byIcon(Icons.info_outline_rounded));
  await tester.pumpAndSettle();
  expect(find.text('Oignons  2 pcs'), findsNothing);
});

testWidgets('info panel closes when navigating to next step', (tester) async {
  _setLandscape(tester);
  addTearDown(() => _resetView(tester));

  await tester.pumpWidget(_wrap(
    CookingModePage(recipe: _recipe(withIngredients: true)),
  ));
  await tester.pump();

  // Open panel
  await tester.tap(find.byIcon(Icons.info_outline_rounded));
  await tester.pumpAndSettle();
  expect(find.text('Oignons  2 pcs'), findsOneWidget);

  // Navigate
  await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
  await tester.pumpAndSettle();
  expect(find.text('Oignons  2 pcs'), findsNothing);
});
```

- [ ] **Step 2: Run — expect FAIL**

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

Expected: icons not found because `_LandscapeBody` doesn't exist yet.

- [ ] **Step 3: Add `_LandscapeBody` after `_LandscapeCenter`**

```dart
class _LandscapeBody extends StatelessWidget {
  final Recipe recipe;
  final int currentStepIndex;
  final int timerSeconds;
  final bool timerRunning;
  final bool infoOpen;
  final Set<String> checkedIngredients;
  final List<RecipeIngredient> stepIngredients;
  final VoidCallback onClose;
  final VoidCallback onTimerToggle;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onInfoToggle;
  final ValueChanged<RecipeIngredient> onIngredientTap;
  final ValueChanged<RecipeIngredient> onIngredientLongPress;

  const _LandscapeBody({
    required this.recipe,
    required this.currentStepIndex,
    required this.timerSeconds,
    required this.timerRunning,
    required this.infoOpen,
    required this.checkedIngredients,
    required this.stepIngredients,
    required this.onClose,
    required this.onTimerToggle,
    required this.onPrev,
    required this.onNext,
    required this.onInfoToggle,
    required this.onIngredientTap,
    required this.onIngredientLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = recipe.steps.length;
    final isFirst = currentStepIndex == 0;
    final isLast = currentStepIndex == totalSteps - 1;
    final step = recipe.steps[currentStepIndex];
    final hasIngredients = stepIngredients.isNotEmpty;

    return Column(
      children: [
        _TopBar(
          current: currentStepIndex + 1,
          total: totalSteps,
          onClose: onClose,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                // Left: prev icon
                _SideNavIcon(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrev,
                  filled: false,
                  enabled: !isFirst,
                ),
                const SizedBox(width: 6),
                // Center
                Expanded(
                  child: _LandscapeCenter(
                    step: step,
                    stepIngredients: stepIngredients,
                    checked: checkedIngredients,
                    timerSeconds: timerSeconds,
                    timerRunning: timerRunning,
                    infoOpen: infoOpen,
                    onTimerToggle: onTimerToggle,
                    onIngredientTap: onIngredientTap,
                    onIngredientLongPress: onIngredientLongPress,
                  ),
                ),
                const SizedBox(width: 6),
                // Right: next + info
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SideNavIcon(
                      icon: isLast
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                      onTap: onNext,
                      filled: true,
                      enabled: true,
                    ),
                    if (hasIngredients) ...[
                      const SizedBox(height: 8),
                      _SideNavIcon(
                        icon: Icons.info_outline_rounded,
                        onTap: onInfoToggle,
                        filled: infoOpen,
                        enabled: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SideNavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  const _SideNavIcon({
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AkeliColors.primary
              : AkeliColors.surfaceContainerHigh
                  .withValues(alpha: enabled ? 1.0 : 0.3),
        ),
        child: Icon(
          icon,
          color: filled
              ? AkeliColors.onPrimary
              : AkeliColors.onSurface
                  .withValues(alpha: enabled ? 1.0 : 0.3),
          size: 22,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run — expect FAIL** (landscape body still not wired into `build()`)

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

- [ ] **Step 5: Commit the widget before wiring**

```
git add lib/features/cooking/cooking_mode_page.dart test/features/cooking/cooking_mode_page_test.dart
git commit -m "feat: add _LandscapeBody and _SideNavIcon widgets; add landscape nav tests"
```

---

### Task 8: Wire `OrientationBuilder` + portrait regression test

**Files:**
- Modify: `lib/features/cooking/cooking_mode_page.dart`
- Modify: `test/features/cooking/cooking_mode_page_test.dart`

- [ ] **Step 1: Add portrait regression tests**

Append a new group after the landscape group:

```dart
group('CookingModePage portrait', () {
  testWidgets('portrait layout still shows Suivant button', (tester) async {
    // portrait is default test size — no override needed
    await tester.pumpWidget(_wrap(CookingModePage(recipe: _recipe())));
    await tester.pump();

    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Précédent'), findsOneWidget);
  });

  testWidgets('portrait last step shows Terminer button', (tester) async {
    await tester.pumpWidget(_wrap(
      CookingModePage(recipe: _recipe(stepCount: 1)),
    ));
    await tester.pump();

    expect(find.text('Terminer'), findsOneWidget);
  });
});
```

- [ ] **Step 2: Run — expect portrait tests PASS, landscape tests FAIL**

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

- [ ] **Step 3: Replace the `build()` body content with `OrientationBuilder`**

In `_CookingModePageState.build()`, the existing `return Scaffold(...)` has a `SafeArea` > `GestureDetector` > `Column`. Replace that inner `Column` content with an `OrientationBuilder`:

The current body inside `SafeArea` is:
```dart
child: GestureDetector(
  onHorizontalDragEnd: ...,
  child: Column(
    children: [
      _TopBar(...),
      Expanded(flex: 5, child: ...),
      if (step.videoUrl != null || step.imageUrl != null) Flexible(...),
      if (step.durationMin != null) _TimerWidget(...),
      if (_stepIngredients.isNotEmpty) _IngredientStrip(...),
      _NavButtons(...),
    ],
  ),
),
```

Replace it with:

```dart
child: GestureDetector(
  onHorizontalDragEnd: (details) {
    if ((details.primaryVelocity ?? 0) < -300) {
      _goToStep(_currentStepIndex + 1);
    } else if ((details.primaryVelocity ?? 0) > 300) {
      _goToStep(_currentStepIndex - 1);
    }
  },
  child: OrientationBuilder(
    builder: (context, orientation) {
      if (orientation == Orientation.landscape) {
        return _LandscapeBody(
          recipe: widget.recipe,
          currentStepIndex: _currentStepIndex,
          timerSeconds: _timerSeconds,
          timerRunning: _timerRunning,
          infoOpen: _infoOpen,
          checkedIngredients: _checkedIngredients,
          stepIngredients: _stepIngredients,
          onClose: () {
            _logger.userAction('Cooking mode closed',
                screen: 'CookingModePage',
                metadata: {'atStep': _currentStepIndex + 1});
            context.pop();
          },
          onTimerToggle: _toggleTimer,
          onPrev: () => _goToStep(_currentStepIndex - 1),
          onNext: isLast
              ? () {
                  _logger.userAction('Cooking mode completed',
                      screen: 'CookingModePage',
                      metadata: {'recipeId': widget.recipe.id});
                  context.pop();
                }
              : () => _goToStep(_currentStepIndex + 1),
          onInfoToggle: () => setState(() => _infoOpen = !_infoOpen),
          onIngredientTap: (ing) =>
              IngredientDetailSheet.show(context, ing),
          onIngredientLongPress: (ing) {
            _logger.userAction('Ingredient checked',
                screen: 'CookingModePage',
                metadata: {'ingredientId': ing.ingredientId});
            setState(() {
              if (_checkedIngredients.contains(ing.ingredientId)) {
                _checkedIngredients.remove(ing.ingredientId);
              } else {
                _checkedIngredients.add(ing.ingredientId);
              }
            });
          },
        );
      }
      // ── portrait ────────────────────────────────────────────────────────
      return Column(
        children: [
          _TopBar(
            current: _currentStepIndex + 1,
            total: totalSteps,
            onClose: () {
              _logger.userAction('Cooking mode closed',
                  screen: 'CookingModePage',
                  metadata: {'atStep': _currentStepIndex + 1});
              context.pop();
            },
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              child: Center(
                child: Text(
                  step.instruction,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    height: 1.5,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          if (step.videoUrl != null || step.imageUrl != null)
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AkeliRadius.xl),
                  child: step.videoUrl != null
                      ? RecipeVideoCard(
                          videoUrl: step.videoUrl!,
                          thumbnailUrl: step.imageUrl)
                      : CachedNetworkImage(
                          imageUrl: step.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity),
                ),
              ),
            ),
          if (step.durationMin != null)
            _TimerWidget(
              totalSeconds: step.durationMin! * 60,
              remainingSeconds: _timerSeconds,
              isRunning: _timerRunning,
              onToggle: _toggleTimer,
            ),
          if (_stepIngredients.isNotEmpty)
            _IngredientStrip(
              ingredients: _stepIngredients,
              checked: _checkedIngredients,
              onTap: (ing) =>
                  IngredientDetailSheet.show(context, ing),
              onLongPress: (ing) {
                _logger.userAction('Ingredient checked',
                    screen: 'CookingModePage',
                    metadata: {'ingredientId': ing.ingredientId});
                setState(() {
                  if (_checkedIngredients
                      .contains(ing.ingredientId)) {
                    _checkedIngredients
                        .remove(ing.ingredientId);
                  } else {
                    _checkedIngredients
                        .add(ing.ingredientId);
                  }
                });
              },
            ),
          _NavButtons(
            isFirst: _currentStepIndex == 0,
            isLast: isLast,
            onPrev: () => _goToStep(_currentStepIndex - 1),
            onNext: isLast
                ? () {
                    _logger.userAction('Cooking mode completed',
                        screen: 'CookingModePage',
                        metadata: {'recipeId': widget.recipe.id});
                    context.pop();
                  }
                : () => _goToStep(_currentStepIndex + 1),
          ),
        ],
      );
    },
  ),
),
```

Note: `step`, `totalSteps`, and `isLast` are already declared just before the `return Scaffold(...)` — they remain unchanged.

- [ ] **Step 4: Run all tests — expect all PASS**

```
flutter test test/features/cooking/cooking_mode_page_test.dart -v
```

Expected output: all tests PASS with no overflow errors.

- [ ] **Step 5: Run full test suite to check no regressions**

```
flutter test --reporter=compact
```

Expected: no new failures.

- [ ] **Step 6: Commit**

```
git add lib/features/cooking/cooking_mode_page.dart test/features/cooking/cooking_mode_page_test.dart
git commit -m "feat: landscape layout for CookingModePage with OrientationBuilder"
```

---

## Self-Review Checklist

- [x] `_infoOpen` state added and reset in `_goToStep` — Task 1
- [x] `_TimerPill` widget — Task 2
- [x] `_LandscapeTextCenter` (text + timer pill) — Task 3
- [x] `_LandscapeInfoPanel` (full text + ingredients + check) — Task 4
- [x] `_LandscapeMediaCenter` (media fill + scrim + text + timer) — Task 5
- [x] `_LandscapeCenter` (Stack + `AnimatedPositioned` panel) — Task 6
- [x] `_LandscapeBody` + `_SideNavIcon` — Task 7
- [x] `OrientationBuilder` wired in `build()` — Task 8
- [x] Portrait regression tests — Task 8
- [x] Edge cases: no ingredients (ℹ hidden), no timer (pill hidden), last step (check icon), `_infoOpen` reset on navigate — all covered in Task 7 tests
- [x] No placeholders or TODOs
- [x] Type/method names consistent across all tasks (`_LandscapeBody`, `_LandscapeCenter`, `_LandscapeMediaCenter`, `_LandscapeTextCenter`, `_LandscapeInfoPanel`, `_TimerPill`, `_SideNavIcon`)
