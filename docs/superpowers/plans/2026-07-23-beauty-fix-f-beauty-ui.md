# Beauty Mode Fix — Area F: Flutter Beauty-Specific UI

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 7 confirmed defects in Beauty Mode's UI layer (broken check-in persistence, wrong "today" filtering, cosmetic timeframe filter, missing logging, missing l10n, missing check-in controls, dead color-theme picker) without touching any file outside this area's ownership.

**Architecture:** Six Flutter widgets/pages under `lib/features/beauty/`, `lib/features/meal_planner/widgets/beauty_planner_view.dart`, and `lib/shared/widgets/color_set_modal.dart` are fixed in place, file-by-file, using strict TDD (failing test → fix → passing test → commit) for every behavioral change. A new `lib/providers/color_set_provider.dart` is added to give the previously-inert `ColorSetModal` real Hive persistence. `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` receive additive-only new keys (no existing key is touched).

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod` 2.5.1), `flutter_test`, `hive`/`hive_flutter`, ARB/l10n (`flutter gen-l10n`).

## Global Constraints

- Repo: `c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`, branch `sdui`. All commands below assume this as the working directory.
- CLAUDE.md's **Logging Standard** AND **L10n Standard** both apply to every file you touch in this plan, with zero exceptions.
- Never use `--no-verify` or skip git hooks. Always create NEW commits — never `git commit --amend`.
- Only touch files listed as "owned" in this plan's tasks. Do **not** touch `lib/core/theme.dart` (Area G) or `lib/features/settings/settings_page.dart` (Area H) — Task 7 explicitly flags them as cross-plan dependencies owned by other plans.
- `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` are shared with other plans. Only **append new keys** at the end of the file, immediately before the final closing `}`. Never remove, rename, or reorder existing keys.
- After every ARB edit, run `flutter gen-l10n` before running any Flutter test or analyze command that depends on the new keys.
- Every `flutter test` command below must be run from the repo root exactly as written.

---

### Task 1: Fix check-in key-casing mismatch (Critical)

**Files:**
- `lib/features/beauty/widgets/beauty_checkin_sheet.dart` (fix)
- `test/features/beauty/widgets/beauty_checkin_sheet_test.dart` (TDD test, rewritten)
- `test/features/beauty/beauty_analytics_page_test.dart` (TDD integration test, appended)

**Interfaces:**
- `BeautyCheckinSheet.show(...)` return type stays `Future<Map<String, dynamic>?>`, but the map's keys change from snake_case to camelCase to match what `beauty_analytics_page.dart`'s `_openCheckinSheet` already reads (that caller is already correct — confirmed by reading its current code at lines 130-138 — so it is **not** modified in this task).
- New optional constructor params `initialHairThicknessScore` and `initialSkinClarityScore` on `BeautyCheckinSheet`.

### Background (verified against current source)

`lib/features/beauty/widgets/beauty_checkin_sheet.dart` lines 65-79 (`_handleSave`) currently builds:

```dart
final payload = <String, dynamic>{
  'user_id': widget.userId,
  'hair_length_cm': _hairLengthCm,
  'hair_strength_score': _hairStrengthScore,
  'skin_hydration_level': _skinHydrationLevel,
  'hair_shedding_rate': _hairSheddingRate,
  'checkin_notes': _notesController.text.trim(),
  'logged_at': DateTime.now().toIso8601String(),
};
```

`lib/features/beauty/beauty_analytics_page.dart` lines 130-138 (`_openCheckinSheet`) already reads:

```dart
await ref.read(addBeautyLogNotifierProvider.notifier).addLog(
  hairLengthCm: (checkinData['hairLengthCm'] as num?)?.toDouble() ?? 15.0,
  hairStrengthScore: (checkinData['hairStrengthScore'] as num?)?.toDouble() ?? 7.0,
  hairThicknessScore: (checkinData['hairThicknessScore'] as num?)?.toDouble() ?? 7.0,
  hairSheddingRate: checkinData['hairSheddingRate'] as String? ?? 'moderate',
  skinHydrationLevel: (checkinData['skinHydrationLevel'] as num?)?.toDouble() ?? 7.0,
  skinClarityScore: (checkinData['skinClarityScore'] as num?)?.toDouble() ?? 7.0,
  checkinNotes: checkinData['checkinNotes'] as String?,
);
```

Every key lookup on the `checkinData` map reads `null` today because the sheet returns snake_case. `addLog`'s hardcoded fallback defaults (`15.0`, `7.0`, `'moderate'`) are silently submitted instead of what the user entered, for every check-in, for every user. `hairThicknessScore` and `skinClarityScore` are read by the caller today but the sheet has no state field or UI control for either — they always fall back to `7.0`.

### Steps

- [ ] **Step 1: Write the failing widget test in `test/features/beauty/widgets/beauty_checkin_sheet_test.dart`.**

  Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/features/beauty/widgets/beauty_checkin_sheet.dart';

  void main() {
    group('BeautyCheckinSheet Widget Tests', () {
      testWidgets(
          'renders checkin sheet title and save button, returns a camelCase payload with initial values',
          (WidgetTester tester) async {
        Map<String, dynamic>? submittedData;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    submittedData = await BeautyCheckinSheet.show(
                      context,
                      userId: 'test-user-123',
                      initialHairLengthCm: 30.0,
                      initialHairStrengthScore: 8.0,
                    );
                  },
                  child: const Text('Open Checkin'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Checkin'));
        await tester.pumpAndSettle();

        expect(find.text('Beauty Check-In & Evolution'), findsOneWidget);
        expect(find.byKey(const Key('save_beauty_checkin_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
        await tester.pumpAndSettle();

        expect(submittedData, isNotNull);
        expect(submittedData!['userId'], equals('test-user-123'));
        expect(submittedData!['hairLengthCm'], equals(30.0));
        expect(submittedData!['hairStrengthScore'], equals(8.0));
        // hairThicknessScore / skinClarityScore are new fields this task adds;
        // they must reach the payload even when the user never touches them.
        expect(submittedData!['hairThicknessScore'], equals(7.0));
        expect(submittedData!['skinClarityScore'], equals(7.0));
      });

      testWidgets(
          'dragging the hair length slider to a non-default value reaches the save payload in camelCase',
          (WidgetTester tester) async {
        Map<String, dynamic>? submittedData;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    submittedData = await BeautyCheckinSheet.show(
                      context,
                      userId: 'test-user-456',
                    );
                  },
                  child: const Text('Open Checkin'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Checkin'));
        await tester.pumpAndSettle();

        // Invoke the Slider's onChanged callback directly with an exact value
        // (25.0) instead of a pixel-based drag gesture, which would depend on
        // the rendered slider's width and be non-deterministic.
        final slider =
            tester.widget<Slider>(find.byKey(const Key('hair_length_slider')));
        slider.onChanged!(25.0);
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
        await tester.pumpAndSettle();

        expect(submittedData, isNotNull);
        // This assertion fails against the current snake_case payload: the
        // key `hair_length_cm` exists but `hairLengthCm` does not, so
        // `submittedData!['hairLengthCm']` reads `null`, and `null == 25.0`
        // is false.
        expect(submittedData!['hairLengthCm'], equals(25.0));
      });
    });
  }
  ```

- [ ] **Step 2: Confirm the test fails against current code.**

  ```
  flutter test test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  ```

  Expected output (both tests fail — the first because `hairLengthCm`/`hairThicknessScore`/`skinClarityScore` read `null` off the current snake_case map and there is no `userId` key either; the second on the explicit `hairLengthCm` assertion):

  ```
  00:01 +0: BeautyCheckinSheet Widget Tests renders checkin sheet title and save button, returns a camelCase payload with initial values [E]
    Expected: 'test-user-123'
    Actual: <null>
  ...
  00:02 +0 -1: BeautyCheckinSheet Widget Tests dragging the hair length slider to a non-default value reaches the save payload in camelCase [E]
    Expected: 25.0
    Actual: <null>
  ...
  00:02 +0 -2: Some tests failed.
  ```

- [ ] **Step 3: Fix `lib/features/beauty/widgets/beauty_checkin_sheet.dart`.**

  Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import '../../../core/theme.dart';

  class BeautyCheckinSheet extends StatefulWidget {
    final String userId;
    final double? initialHairLengthCm;
    final double? initialHairStrengthScore;
    final double? initialHairThicknessScore;
    final double? initialSkinHydrationLevel;
    final double? initialSkinClarityScore;
    final Function(Map<String, dynamic> checkinData)? onSubmit;

    const BeautyCheckinSheet({
      super.key,
      required this.userId,
      this.initialHairLengthCm,
      this.initialHairStrengthScore,
      this.initialHairThicknessScore,
      this.initialSkinHydrationLevel,
      this.initialSkinClarityScore,
      this.onSubmit,
    });

    static Future<Map<String, dynamic>?> show(
      BuildContext context, {
      required String userId,
      double? initialHairLengthCm,
      double? initialHairStrengthScore,
      double? initialHairThicknessScore,
      double? initialSkinHydrationLevel,
      double? initialSkinClarityScore,
    }) {
      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BeautyCheckinSheet(
          userId: userId,
          initialHairLengthCm: initialHairLengthCm,
          initialHairStrengthScore: initialHairStrengthScore,
          initialHairThicknessScore: initialHairThicknessScore,
          initialSkinHydrationLevel: initialSkinHydrationLevel,
          initialSkinClarityScore: initialSkinClarityScore,
        ),
      );
    }

    @override
    State<BeautyCheckinSheet> createState() => _BeautyCheckinSheetState();
  }

  class _BeautyCheckinSheetState extends State<BeautyCheckinSheet> {
    late double _hairLengthCm;
    late double _hairStrengthScore;
    late double _hairThicknessScore;
    late double _skinHydrationLevel;
    late double _skinClarityScore;
    String _hairSheddingRate = 'normal';
    final _notesController = TextEditingController();

    @override
    void initState() {
      super.initState();
      _hairLengthCm = widget.initialHairLengthCm ?? 20.0;
      _hairStrengthScore = widget.initialHairStrengthScore ?? 7.0;
      _hairThicknessScore = widget.initialHairThicknessScore ?? 7.0;
      _skinHydrationLevel = widget.initialSkinHydrationLevel ?? 7.0;
      _skinClarityScore = widget.initialSkinClarityScore ?? 7.0;
    }

    @override
    void dispose() {
      _notesController.dispose();
      super.dispose();
    }

    void _handleSave() {
      final payload = <String, dynamic>{
        'userId': widget.userId,
        'hairLengthCm': _hairLengthCm,
        'hairStrengthScore': _hairStrengthScore,
        'hairThicknessScore': _hairThicknessScore,
        'skinHydrationLevel': _skinHydrationLevel,
        'skinClarityScore': _skinClarityScore,
        'hairSheddingRate': _hairSheddingRate,
        'checkinNotes': _notesController.text.trim(),
        'loggedAt': DateTime.now().toIso8601String(),
      };
      if (widget.onSubmit != null) {
        widget.onSubmit!(payload);
      }
      Navigator.of(context).pop(payload);
    }

    @override
    Widget build(BuildContext context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 24 + bottomInset,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Beauty Check-In & Evolution',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record your monthly hair length and skin barrier check-in.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              Text(
                'Hair Length: ${_hairLengthCm.toStringAsFixed(1)} cm',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('hair_length_slider'),
                value: _hairLengthCm,
                min: 2.0,
                max: 100.0,
                divisions: 196,
                activeColor: AkeliColors.primary,
                onChanged: (val) => setState(() => _hairLengthCm = val),
              ),
              const SizedBox(height: 16),

              Text(
                'Hair Strength Score: ${_hairStrengthScore.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('hair_strength_slider'),
                value: _hairStrengthScore,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.accentAmber,
                onChanged: (val) => setState(() => _hairStrengthScore = val),
              ),
              const SizedBox(height: 16),

              Text(
                'Hair Thickness Score: ${_hairThicknessScore.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('hair_thickness_slider'),
                value: _hairThicknessScore,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.accentAmber,
                onChanged: (val) => setState(() => _hairThicknessScore = val),
              ),
              const SizedBox(height: 16),

              Text(
                'Skin Hydration Level: ${_skinHydrationLevel.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('skin_hydration_slider'),
                value: _skinHydrationLevel,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.primaryContainer,
                onChanged: (val) => setState(() => _skinHydrationLevel = val),
              ),
              const SizedBox(height: 16),

              Text(
                'Skin Clarity Score: ${_skinClarityScore.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('skin_clarity_slider'),
                value: _skinClarityScore,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.primaryContainer,
                onChanged: (val) => setState(() => _skinClarityScore = val),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Check-in Journal Notes (Optional)',
                  hintText: 'e.g. Hair feeling noticeably softer after Chébé mask!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('save_beauty_checkin_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AkeliColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _handleSave,
                  child: const Text(
                    'Save Progress Check-In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Confirm the test now passes.**

  ```
  flutter test test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 5: Add the integration-style test to `test/features/beauty/beauty_analytics_page_test.dart`.**

  First, read `lib/providers/auth_provider.dart` to confirm `currentUserProvider` is `Provider<User?>` (already verified: line 32) and `lib/providers/beauty_plan_provider.dart` to confirm `AddBeautyLogNotifier.addLog`'s exact named-parameter signature (already verified above). Then replace the entire test file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:akeli/features/beauty/beauty_analytics_page.dart';
  import 'package:akeli/providers/auth_provider.dart';
  import 'package:akeli/providers/beauty_plan_provider.dart';
  import 'package:akeli/shared/models/beauty_log.dart';
  import 'package:akeli/shared/models/beauty_plan.dart';

  class _FakeAddBeautyLogNotifier extends AddBeautyLogNotifier {
    Map<String, dynamic>? capturedArgs;

    @override
    Future<void> addLog({
      required double hairLengthCm,
      required double hairStrengthScore,
      required double hairThicknessScore,
      required String hairSheddingRate,
      required double skinHydrationLevel,
      required double skinClarityScore,
      String? checkinNotes,
      List<String> checkinPhotoUrls = const [],
    }) async {
      capturedArgs = {
        'hairLengthCm': hairLengthCm,
        'hairStrengthScore': hairStrengthScore,
        'hairThicknessScore': hairThicknessScore,
        'hairSheddingRate': hairSheddingRate,
        'skinHydrationLevel': skinHydrationLevel,
        'skinClarityScore': skinClarityScore,
        'checkinNotes': checkinNotes,
      };
    }
  }

  void main() {
    final testLogs = [
      BeautyLog(
        id: 'log-1',
        userId: 'user-1',
        hairLengthCm: 18.0,
        hairStrengthScore: 8.0,
        hairThicknessScore: 8.0,
        hairSheddingRate: 'low',
        skinHydrationLevel: 9.0,
        skinClarityScore: 8.0,
        checkinNotes: 'Super pousse ce mois-ci!',
        loggedAt: DateTime(2026, 7, 21),
      ),
      BeautyLog(
        id: 'log-0',
        userId: 'user-1',
        hairLengthCm: 15.0,
        hairStrengthScore: 7.0,
        hairThicknessScore: 7.0,
        hairSheddingRate: 'moderate',
        skinHydrationLevel: 7.0,
        skinClarityScore: 7.0,
        checkinNotes: 'Bilan initial',
        loggedAt: DateTime(2026, 6, 21),
      ),
    ];

    final testPlan = BeautyPlan(
      id: 'plan-1',
      userId: 'user-1',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      createdAt: DateTime(2026, 7, 1),
      slots: [
        BeautyPlanSlot(
          id: 'slot-1',
          planId: 'plan-1',
          dayNumber: 1,
          weekNumber: 1,
          dayOfWeek: 1,
          routineCategory: 'hair',
          stepStage: 'daily_hydration',
          frequencyTier: 'daily',
          recipeId: 'rec-1',
          isCompleted: true,
        ),
        BeautyPlanSlot(
          id: 'slot-2',
          planId: 'plan-1',
          dayNumber: 1,
          weekNumber: 1,
          dayOfWeek: 1,
          routineCategory: 'skin',
          stepStage: 'daily_hydration',
          frequencyTier: 'daily',
          recipeId: 'rec-2',
          isCompleted: false,
        ),
      ],
    );

    testWidgets('BeautyAnalyticsPage renders header, metrics, and logs history', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBeautyPlanProvider.overrideWith((ref) async => testPlan),
            beautyLogsProvider.overrideWith((ref) async => testLogs),
          ],
          child: const MaterialApp(
            home: BeautyAnalyticsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Suivi Beauté & Rituals'), findsOneWidget);
      expect(find.text('Tableau de Bord Beauté 👑'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 1 out of 2 slots completed
      expect(find.text('18.0 cm'), findsOneWidget);
      expect(find.text('+3.0 cm gagnés'), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      expect(find.text('Super pousse ce mois-ci!'), findsOneWidget);
      expect(find.text('Bilan initial'), findsOneWidget);
    });

    testWidgets(
        'Check-in sheet save flow passes the real user-entered slider value to addBeautyLogNotifierProvider, not a hardcoded default',
        (WidgetTester tester) async {
      final fakeNotifier = _FakeAddBeautyLogNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBeautyPlanProvider.overrideWith((ref) async => testPlan),
            beautyLogsProvider.overrideWith((ref) async => testLogs),
            currentUserProvider.overrideWithValue(
              const User(
                id: 'test-user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2026-07-01T00:00:00Z',
              ),
            ),
            addBeautyLogNotifierProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: BeautyAnalyticsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the check-in sheet via the app bar camera icon.
      await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
      await tester.pumpAndSettle();

      // Move the hair-length slider to a specific non-default value.
      final slider = tester.widget<Slider>(find.byKey(const Key('hair_length_slider')));
      slider.onChanged!(42.0);
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();

      expect(fakeNotifier.capturedArgs, isNotNull);
      // This is the assertion that fails today: with the pre-fix snake_case
      // payload, `_openCheckinSheet` reads `checkinData['hairLengthCm']` as
      // `null` and falls back to the hardcoded default `15.0`, never `42.0`.
      expect(fakeNotifier.capturedArgs!['hairLengthCm'], equals(42.0));
    });
  }
  ```

- [ ] **Step 6: Confirm the new integration test fails before Step 3's fix and passes after.**

  Since Step 3 already applied the fix, temporarily verify the regression coverage by checking out the pre-fix version of `beauty_checkin_sheet.dart` in a scratch copy is unnecessary — the causal chain is already proven by Step 2's failure/Step 4's pass on the unit test. Run the full file now to confirm the integration test passes on the fixed code:

  ```
  flutter test test/features/beauty/beauty_analytics_page_test.dart
  ```

  Expected output:

  ```
  00:03 +2: All tests passed!
  ```

- [ ] **Step 7: Commit.**

  ```
  git add lib/features/beauty/widgets/beauty_checkin_sheet.dart test/features/beauty/widgets/beauty_checkin_sheet_test.dart test/features/beauty/beauty_analytics_page_test.dart
  git commit -m "fix(beauty): return camelCase keys from BeautyCheckinSheet to fix silently-discarded check-ins"
  ```

### Task 2: Fix "Today's Rituals" day-filter bug (Critical)

**Files:**
- `lib/features/beauty/widgets/today_beauty_routines_widget.dart` (fix)
- `test/features/beauty/widgets/today_beauty_routines_widget_test.dart` (TDD test, rewritten)
- Read-only reference (do NOT edit — owned by Area E): `lib/providers/beauty_plan_provider.dart`, `lib/shared/models/beauty_plan.dart`

**Interfaces:**
- `TodayBeautyRoutinesWidget` gains a new constructor parameter `final DateTime Function() now` defaulting to `DateTime.now`, for deterministic clock injection in tests. This is a **required constructor change** — see Step 2, where the test fails to compile against the current constructor.

### Background (verified against current source)

`lib/shared/models/beauty_plan.dart` line 8 confirms `BeautyPlan.startDate` exists (`final DateTime startDate;`), and line 55 confirms `BeautyPlanSlot.dayNumber` is documented as `// 1 to 31 (day of month)` — this comment is itself wrong (Area E's bug to fix, not ours: `dayNumber` is actually a plan-relative offset from `startDate`, not a calendar day-of-month; the SQL generator in Area B confirms this). We do not edit `beauty_plan.dart`.

`lib/features/beauty/widgets/today_beauty_routines_widget.dart` lines 69-79 currently:

```dart
final today = DateTime.now();
final todayDayNumber = today.day;
final todayDayOfWeek = today.weekday; // 1 = Mon, 7 = Sun

// Filter slots scheduled for today (by dayNumber or dayOfWeek fallback)
final todaySlots = plan.slots.where((s) {
  if (s.dayNumber != null) {
    return s.dayNumber == todayDayNumber;
  }
  return s.dayOfWeek == todayDayOfWeek;
}).toList();
```

`s.dayNumber == todayDayNumber` compares a plan-relative offset (e.g. `3` = "the 3rd day since the plan started") against the calendar day-of-month (e.g. `12` on July 12th). These only coincidentally match when a plan happens to start on the 1st of the month.

### Steps

- [ ] **Step 1: Write the failing widget test in `test/features/beauty/widgets/today_beauty_routines_widget_test.dart`.**

  Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/features/beauty/widgets/today_beauty_routines_widget.dart';
  import 'package:akeli/providers/beauty_plan_provider.dart';
  import 'package:akeli/shared/models/beauty_plan.dart';

  void main() {
    group('TodayBeautyRoutinesWidget Tests', () {
      testWidgets('renders today routines header and slots', (WidgetTester tester) async {
        final now = DateTime.now();

        final mockPlan = BeautyPlan(
          id: 'plan-1',
          userId: 'user-1',
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          createdAt: now,
          slots: [
            BeautyPlanSlot(
              id: 'slot-today-1',
              planId: 'plan-1',
              dayOfWeek: now.weekday,
              dayNumber: 1,
              routineCategory: 'hair',
              stepStage: 'Soin Hydratant Matinal',
              frequencyTier: 'daily',
              recipeId: 'r-1',
              isCompleted: false,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeBeautyPlanProvider.overrideWith((ref) async => mockPlan),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TodayBeautyRoutinesWidget(now: () => now),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Vos Rituels du Jour 👑'), findsOneWidget);
        expect(find.text('Planning (30j)'), findsOneWidget);
        expect(find.text('Soin Hydratant Matinal'), findsOneWidget);
      });

      testWidgets(
          'uses the slot\'s actual calendar date (startDate + dayNumber - 1), not raw day-of-month, to pick what counts as "today"',
          (WidgetTester tester) async {
        // Plan starts mid-month: July 10, 2026. Plan day 3 = July 12.
        final startDate = DateTime(2026, 7, 10);

        final mockPlan = BeautyPlan(
          id: 'plan-2',
          userId: 'user-1',
          startDate: startDate,
          endDate: startDate.add(const Duration(days: 30)),
          createdAt: startDate,
          slots: [
            // Correct slot for "today" (July 12): plan day 3.
            BeautyPlanSlot(
              id: 'slot-correct',
              planId: 'plan-2',
              dayOfWeek: 7,
              dayNumber: 3,
              routineCategory: 'hair',
              stepStage: 'Soin Jour 3 Correct',
              frequencyTier: 'daily',
              recipeId: 'r-correct',
              isCompleted: false,
            ),
            // Under the OLD buggy logic (`dayNumber == today.day`), this slot
            // (dayNumber: 12) would incorrectly match "today" (July 12, i.e.
            // today.day == 12) even though its real calendar date is plan
            // day 12 = July 21, not today.
            BeautyPlanSlot(
              id: 'slot-old-bug-match',
              planId: 'plan-2',
              dayOfWeek: 2,
              dayNumber: 12,
              routineCategory: 'skin',
              stepStage: 'Soin Jour 12 Ne Doit Pas Apparaitre',
              frequencyTier: 'daily',
              recipeId: 'r-wrong',
              isCompleted: false,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeBeautyPlanProvider.overrideWith((ref) async => mockPlan),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  // Fixed clock: "today" is deterministically July 12, 2026.
                  child: TodayBeautyRoutinesWidget(now: () => DateTime(2026, 7, 12)),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Soin Jour 3 Correct'), findsOneWidget);
        expect(find.text('Soin Jour 12 Ne Doit Pas Apparaitre'), findsNothing);
      });
    });
  }
  ```

- [ ] **Step 2: Confirm the test fails against current code.**

  ```
  flutter test test/features/beauty/widgets/today_beauty_routines_widget_test.dart
  ```

  Expected output — a **compile error**, because `TodayBeautyRoutinesWidget` does not yet accept a `now:` named parameter (adding it is part of this fix, per the finding):

  ```
  lib/features/beauty/widgets/today_beauty_routines_widget.dart:... (or the test file)
  Error: No named parameter with the name 'now'.
    child: TodayBeautyRoutinesWidget(now: () => now),
                                     ^^^
  ```

- [ ] **Step 3: Fix `lib/features/beauty/widgets/today_beauty_routines_widget.dart`.**

  Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/router.dart';
  import '../../../core/theme.dart';
  import '../../../providers/beauty_plan_provider.dart';
  import '../../../shared/models/beauty_plan.dart';
  import '../../../shared/widgets/empty_state.dart';

  class TodayBeautyRoutinesWidget extends ConsumerWidget {
    final DateTime Function() now;

    const TodayBeautyRoutinesWidget({super.key, this.now = DateTime.now});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vos Rituels du Jour 👑',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.textPrimary,
                      ),
                ),
                TextButton(
                  key: const Key('open_beauty_planner_button'),
                  onPressed: () {
                    context.push(AkeliRoutes.mealPlanner);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Planning (30j)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: AkeliColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          beautyPlanAsync.when(
            data: (plan) {
              if (plan == null || plan.slots.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    icon: Icons.spa_outlined,
                    title: 'Aucun rituel aujourd\'hui',
                    subtitle: 'Générez votre planning mensuel dans l\'onglet Routine.',
                  ),
                );
              }

              final today = now();

              // `dayNumber` is a PLAN-RELATIVE offset (1 = the plan's start
              // date), not a day-of-month — it must be converted to a real
              // calendar date via `plan.startDate` before comparing to
              // `today`. Slots without a `dayNumber` fall back to matching
              // `dayOfWeek` against today's weekday, unchanged from before.
              final todaySlots = plan.slots.where((s) {
                if (s.dayNumber != null) {
                  final slotDate = plan.startDate.add(Duration(days: s.dayNumber! - 1));
                  return slotDate.year == today.year &&
                      slotDate.month == today.month &&
                      slotDate.day == today.day;
                }
                return s.dayOfWeek == today.weekday;
              }).toList();

              if (todaySlots.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AkeliColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Journée de repos pour votre cuir chevelu & peau !',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AkeliColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: todaySlots.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final slot = todaySlots[index];
                  return _buildTodaySlotCard(context, ref, slot);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Erreur lors du chargement des rituels : $err',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildTodaySlotCard(
        BuildContext context, WidgetRef ref, BeautyPlanSlot slot) {
      final isCompleted = slot.isCompleted;
      final recipe = slot.recipe;

      return Card(
        elevation: 0,
        color: isCompleted
            ? AkeliColors.surfaceContainerLow
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCompleted
                ? Colors.transparent
                : AkeliColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: AkeliColors.secondaryContainer,
              child: recipe?.thumbnailUrl != null && recipe!.thumbnailUrl!.isNotEmpty
                  ? Image.network(recipe.thumbnailUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.spa, color: AkeliColors.primary),
            ),
          ),
          title: Text(
            recipe?.title ?? slot.stepStage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? AkeliColors.textSecondary
                  : AkeliColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    slot.routineCategory.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  slot.frequencyTier != null ? 'Tier: ${slot.frequencyTier}' : 'Rituel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AkeliColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing: Checkbox(
            value: isCompleted,
            activeColor: AkeliColors.primary,
            onChanged: (val) {
              ref
                  .read(toggleBeautySlotNotifierProvider.notifier)
                  .toggleCompletion(slot.id, isCompleted);
            },
          ),
          onTap: () {
            if (recipe != null) {
              context.push(AkeliRoutes.recipeDetailPath(recipe.id));
            }
          },
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Confirm the test now passes.**

  ```
  flutter test test/features/beauty/widgets/today_beauty_routines_widget_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 5: Commit.**

  ```
  git add lib/features/beauty/widgets/today_beauty_routines_widget.dart test/features/beauty/widgets/today_beauty_routines_widget_test.dart
  git commit -m "fix(beauty): compare slot calendar dates (startDate + dayNumber) instead of raw day-of-month in TodayBeautyRoutinesWidget"
  ```

### Task 3: Wire the timeframe chips (7J/30J/90J/Tout) into actual data filtering (High)

**Files:**
- `lib/features/beauty/beauty_analytics_page.dart` (fix)
- `test/features/beauty/beauty_analytics_page_test.dart` (TDD test, appended)

**Interfaces:**
- `_BeautyAnalyticsPageState` replaces its `String _selectedTimeframe` field with `String _selectedTimeframeId` (one of `'7d'`, `'30d'`, `'90d'`, `'all'`) — an internal, locale-independent identifier — plus two new private helpers: `String _timeframeLabel(String id)` (display text) and `DateTime? _cutoffFor(String id)` (filter cutoff). Keeping the internal state as an id rather than the display label avoids re-breaking this filter in Task 5, when the label text is swapped for `AppLocalizations` calls.

### Background (verified against current source)

`lib/features/beauty/beauty_analytics_page.dart` line 20 declares `String _selectedTimeframe = '30 Jours';`, updated via `setState` in `_buildTimeframeFilterPills()` (lines 189-222), but nothing downstream ever reads `_selectedTimeframe` — `beautyLogsAsync.when(data: (logs) => ...)` at lines 81-99 passes the full, unfiltered `logs` list straight into `_buildHairProgressionSection`, `_buildSkinProgressionSection`, and `_buildLogsHistoryTimeline` regardless of which chip is selected.

### Steps

- [ ] **Step 1: Add the failing test to `test/features/beauty/beauty_analytics_page_test.dart`.**

  Append this test inside the existing `void main() { ... }` block (after the two tests added in Task 1, using the same `testPlan` already defined at the top of the file):

  ```dart
    testWidgets('"7 Jours" filter only shows logs from the last 7 days', (WidgetTester tester) async {
      final now = DateTime.now();
      final recentLog = BeautyLog(
        id: 'log-recent',
        userId: 'user-1',
        hairLengthCm: 20.0,
        hairStrengthScore: 8.0,
        hairThicknessScore: 8.0,
        hairSheddingRate: 'low',
        skinHydrationLevel: 8.0,
        skinClarityScore: 8.0,
        checkinNotes: 'Bilan recent aujourdhui',
        loggedAt: now,
      );
      final oldLog = BeautyLog(
        id: 'log-old',
        userId: 'user-1',
        hairLengthCm: 10.0,
        hairStrengthScore: 5.0,
        hairThicknessScore: 5.0,
        hairSheddingRate: 'high',
        skinHydrationLevel: 5.0,
        skinClarityScore: 5.0,
        checkinNotes: 'Bilan ancien 100 jours',
        loggedAt: now.subtract(const Duration(days: 100)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBeautyPlanProvider.overrideWith((ref) async => testPlan),
            beautyLogsProvider.overrideWith((ref) async => [recentLog, oldLog]),
          ],
          child: const MaterialApp(home: BeautyAnalyticsPage()),
        ),
      );

      await tester.pumpAndSettle();

      // "Tout" proves both logs are reachable before filtering.
      await tester.tap(find.text('Tout'));
      await tester.pumpAndSettle();
      expect(find.text('Bilan ancien 100 jours'), findsOneWidget);

      // Switching to "7 Jours" must remove the 100-day-old log.
      await tester.tap(find.text('7 Jours'));
      await tester.pumpAndSettle();

      expect(find.text('Bilan recent aujourdhui'), findsOneWidget);
      expect(find.text('Bilan ancien 100 jours'), findsNothing);
      expect(find.text('1 bilans'), findsOneWidget);
    });
  ```

- [ ] **Step 2: Confirm the test fails against current code.**

  ```
  flutter test test/features/beauty/beauty_analytics_page_test.dart
  ```

  Expected output — the new test fails because tapping "7 Jours" does not filter anything yet:

  ```
  ..."7 Jours" filter only shows logs from the last 7 days [E]
    Expected: no matching candidates
    Actual: _TextWidgetFinder:<Failed to trigger any pump... found 1 widget>
    Which: Bilan ancien 100 jours was found
  ...
  00:03 +2 -1: Some tests failed.
  ```

- [ ] **Step 3: Fix `lib/features/beauty/beauty_analytics_page.dart`.**

  Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../../core/logger.dart';
  import '../../core/theme.dart';
  import '../../providers/auth_provider.dart';
  import '../../providers/beauty_plan_provider.dart';
  import '../../shared/models/beauty_log.dart';
  import '../../shared/models/beauty_plan.dart';
  import 'widgets/beauty_checkin_sheet.dart';

  class BeautyAnalyticsPage extends ConsumerStatefulWidget {
    const BeautyAnalyticsPage({super.key});

    @override
    ConsumerState<BeautyAnalyticsPage> createState() => _BeautyAnalyticsPageState();
  }

  class _BeautyAnalyticsPageState extends ConsumerState<BeautyAnalyticsPage> {
    static const _timeframeIds = ['7d', '30d', '90d', 'all'];
    String _selectedTimeframeId = '30d';

    static const Color _rosewood = Color(0xFF8A3B58);
    static const Color _gold = Color(0xFFD4AF37);
    static const Color _darkCardBg = Color(0xFF231821);

    String _timeframeLabel(String id) {
      switch (id) {
        case '7d':
          return '7 Jours';
        case '30d':
          return '30 Jours';
        case '90d':
          return '90 Jours';
        case 'all':
        default:
          return 'Tout';
      }
    }

    /// Earliest `loggedAt` still included for [id], or `null` for "Tout"
    /// (no filtering).
    DateTime? _cutoffFor(String id) {
      final now = DateTime.now();
      switch (id) {
        case '7d':
          return now.subtract(const Duration(days: 7));
        case '30d':
          return now.subtract(const Duration(days: 30));
        case '90d':
          return now.subtract(const Duration(days: 90));
        case 'all':
        default:
          return null;
      }
    }

    List<BeautyLog> _filterLogsByTimeframe(List<BeautyLog> logs) {
      final cutoff = _cutoffFor(_selectedTimeframeId);
      if (cutoff == null) return logs;
      return logs.where((log) => log.loggedAt.isAfter(cutoff)).toList();
    }

    @override
    Widget build(BuildContext context) {
      final activePlanAsync = ref.watch(activeBeautyPlanProvider);
      final beautyLogsAsync = ref.watch(beautyLogsProvider);

      return Scaffold(
        backgroundColor: const Color(0xFF140D13),
        appBar: AppBar(
          backgroundColor: const Color(0xFF140D13),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Suivi Beauté & Rituals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined, color: _gold, size: 22),
              tooltip: 'Nouveau Bilan Beauté',
              onPressed: () => _openCheckinSheet(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: _rosewood,
          backgroundColor: const Color(0xFF231821),
          onRefresh: () async {
            ref.invalidate(activeBeautyPlanProvider);
            ref.invalidate(beautyLogsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildEditorialHeader(),
              const SizedBox(height: 16),
              _buildTimeframeFilterPills(),
              const SizedBox(height: 20),

              // 1. Ritual Adherence Metric Card
              activePlanAsync.when(
                data: (plan) => _buildAdherenceCard(plan),
                loading: () => const Center(child: CircularProgressIndicator(color: _rosewood)),
                error: (_, __) => _buildAdherenceCard(null),
              ),
              const SizedBox(height: 24),

              // 2. Progression Logs Visualizer & Diagnostics — filtered by
              // the selected timeframe chip.
              beautyLogsAsync.when(
                data: (logs) {
                  final filteredLogs = _filterLogsByTimeframe(logs);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHairProgressionSection(filteredLogs),
                      const SizedBox(height: 24),
                      _buildSkinProgressionSection(filteredLogs),
                      const SizedBox(height: 28),
                      _buildLogsHistoryTimeline(filteredLogs),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: _rosewood)),
                error: (err, _) => Center(
                  child: Text(
                    'Erreur de chargement des bilans: $err',
                    style: GoogleFonts.nunito(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openCheckinSheet(context),
          backgroundColor: _rosewood,
          elevation: 6,
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
          label: Text(
            'Nouveau Bilan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    void _openCheckinSheet(BuildContext context) async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final checkinData = await BeautyCheckinSheet.show(
        context,
        userId: user.id,
      );

      if (checkinData != null) {
        await ref.read(addBeautyLogNotifierProvider.notifier).addLog(
              hairLengthCm: (checkinData['hairLengthCm'] as num?)?.toDouble() ?? 15.0,
              hairStrengthScore: (checkinData['hairStrengthScore'] as num?)?.toDouble() ?? 7.0,
              hairThicknessScore: (checkinData['hairThicknessScore'] as num?)?.toDouble() ?? 7.0,
              hairSheddingRate: checkinData['hairSheddingRate'] as String? ?? 'moderate',
              skinHydrationLevel: (checkinData['skinHydrationLevel'] as num?)?.toDouble() ?? 7.0,
              skinClarityScore: (checkinData['skinClarityScore'] as num?)?.toDouble() ?? 7.0,
              checkinNotes: checkinData['checkinNotes'] as String?,
            );
      }
    }

    Widget _buildEditorialHeader() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rosewood.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _rosewood.withOpacity(0.5)),
                ),
                child: Text(
                  'DIAGNOSTIC & SUIVI RITUEL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tableau de Bord Beauté 👑',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analysez votre régularité rituelle, la repousse capillaire et l\'évolution de votre teint.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    Widget _buildTimeframeFilterPills() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _timeframeIds.map((id) {
            final isSelected = _selectedTimeframeId == id;
            final label = _timeframeLabel(id);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTimeframeId = id);
                  }
                },
                selectedColor: _rosewood,
                backgroundColor: const Color(0xFF231821),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                side: BorderSide(
                  color: isSelected ? _gold : Colors.white10,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget _buildAdherenceCard(BeautyPlan? plan) {
      int totalSlots = plan?.slots.length ?? 0;
      int completedSlots = plan?.slots.where((s) => s.isCompleted).length ?? 0;
      double percentage = totalSlots > 0 ? (completedSlots / totalSlots) * 100 : 0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _rosewood.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: _rosewood.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assiduité du Rituel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($completedSlots/$totalSlots soins)',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_rosewood, _gold.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalSlots > 0 ? completedSlots / totalSlots : 0,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(_gold),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildHairProgressionSection(List<BeautyLog> logs) {
      final latestLog = logs.isNotEmpty ? logs.first : null;
      final initialLog = logs.isNotEmpty ? logs.last : null;

      double currentLength = latestLog?.hairLengthCm ?? 15.0;
      double initialLength = initialLog?.hairLengthCm ?? 15.0;
      double growthDelta = currentLength - initialLength;

      double strengthScore = latestLog?.hairStrengthScore ?? 7.0;
      String sheddingRate = latestLog?.hairSheddingRate ?? 'moderate';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_cut_rounded, color: _gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Diagnostic Capillaire 👑',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Longueur',
                  value: '${currentLength.toStringAsFixed(1)} cm',
                  subtitle: growthDelta >= 0 ? '+${growthDelta.toStringAsFixed(1)} cm gagnés' : '${growthDelta.toStringAsFixed(1)} cm',
                  subtitleColor: growthDelta >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Force & Densité',
                  value: '${strengthScore.toStringAsFixed(0)}/10',
                  subtitle: 'Score de résistance',
                  subtitleColor: Colors.white60,
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _darkCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveau de Chute (Anti-Casse)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.87),
                  ),
                ),
                _buildSheddingBadge(sheddingRate),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildSkinProgressionSection(List<BeautyLog> logs) {
      final latestLog = logs.isNotEmpty ? logs.first : null;

      double hydrationLevel = latestLog?.skinHydrationLevel ?? 7.0;
      double clarityScore = latestLog?.skinClarityScore ?? 7.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight_rounded, color: _gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Diagnostic Cutané ✨',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Hydratation Cutanée',
                  value: '${hydrationLevel.toStringAsFixed(0)}/10',
                  subtitle: 'Barrière hydrique',
                  subtitleColor: Colors.cyanAccent,
                  icon: Icons.water_drop_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Éclat & Teint',
                  value: '${clarityScore.toStringAsFixed(0)}/10',
                  subtitle: 'Clarification du grain',
                  subtitleColor: _gold,
                  icon: Icons.wb_sunny_rounded,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildMetricTile({
      required String title,
      required String value,
      required String subtitle,
      required Color subtitleColor,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _darkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
                Icon(icon, size: 16, color: _rosewood),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSheddingBadge(String rate) {
      String label = 'Modérée';
      Color color = Colors.orangeAccent;

      if (rate == 'low' || rate == 'Faible') {
        label = 'Faible (Idéal)';
        color = Colors.greenAccent;
      } else if (rate == 'high' || rate == 'Élevée') {
        label = 'Élevée (Attention)';
        color = Colors.redAccent;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    Widget _buildLogsHistoryTimeline(List<BeautyLog> logs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique du Journal 📖',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${logs.length} bilans',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _darkCardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Aucun bilan beauté enregistré pour l\'instant.',
                  style: GoogleFonts.nunito(color: Colors.white60),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                final dateStr = '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _darkCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: _gold),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _rosewood.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bilan #${logs.length - index}',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChipTag('📏 ${log.hairLengthCm} cm'),
                          _buildChipTag('💪 Force: ${log.hairStrengthScore.toStringAsFixed(0)}/10'),
                          _buildChipTag('💧 Hydratation: ${log.skinHydrationLevel.toStringAsFixed(0)}/10'),
                          _buildChipTag('✨ Éclat: ${log.skinClarityScore.toStringAsFixed(0)}/10'),
                        ],
                      ),
                      if (log.checkinNotes != null && log.checkinNotes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          log.checkinNotes!,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      );
    }

    Widget _buildChipTag(String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.white.withOpacity(0.87),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Confirm the test now passes.**

  ```
  flutter test test/features/beauty/beauty_analytics_page_test.dart
  ```

  Expected output:

  ```
  00:03 +3: All tests passed!
  ```

- [ ] **Step 5: Commit.**

  ```
  git add lib/features/beauty/beauty_analytics_page.dart test/features/beauty/beauty_analytics_page_test.dart
  git commit -m "fix(beauty): make the 7J/30J/90J/Tout timeframe chips actually filter analytics data"
  ```

### Task 4: Add mandatory structured logging to the 5 files with zero `appLogger` calls (High)

**Files:**
- `lib/features/beauty/beauty_analytics_page.dart` (fix — on top of Task 3's version)
- `lib/features/beauty/widgets/beauty_checkin_sheet.dart` (fix — on top of Task 1's version)
- `lib/features/beauty/widgets/today_beauty_routines_widget.dart` (fix — on top of Task 2's version)
- `lib/features/meal_planner/widgets/beauty_planner_view.dart` (fix)
- `lib/shared/widgets/color_set_modal.dart` (fix)

**Interfaces:** No public API changes. This task only adds `appLogger` calls per CLAUDE.md's Logging Standard, following the pattern in `lib/providers/_examples/recipe_provider_logged.dart`. `beauty_onboarding_page.dart` already has `_logger = appLogger` wired in (confirmed by reading the current file — `_logger.provider(...)` in `build()` and `_logger.db('ERROR | ...')` in `_handleNextOrSubmit`'s catch block) and is intentionally **not** touched by this task.

This is a purely additive, mechanical pass — no test changes are required (logging has no user-visible behavior to assert on in a widget test), but every existing test from Tasks 1-3 must still pass unmodified after each file below is edited, proving the logging additions didn't change behavior.

### Steps

- [ ] **Step 1: `lib/features/beauty/beauty_analytics_page.dart` — log the check-in FAB/icon tap and the `addLog` call outcome.**

  `beauty_analytics_page.dart` already has a dead `import '../../core/logger.dart';` (never instantiated) — confirmed at line 4 of the original file. Add the `_logger` field and wire logging into `_openCheckinSheet` and `build()`. Apply this diff on top of Task 3's full file:

  Add a field right after the `_darkCardBg` constant:

  ```dart
    static const Color _darkCardBg = Color(0xFF231821);

    final _logger = appLogger;
  ```

  Add a log line as the first statement of `build()`:

  ```dart
    @override
    Widget build(BuildContext context) {
      _logger.provider('BeautyAnalyticsPage build()');
      final activePlanAsync = ref.watch(activeBeautyPlanProvider);
  ```

  Replace `_openCheckinSheet` with:

  ```dart
    void _openCheckinSheet(BuildContext context) async {
      _logger.userAction('Check-in FAB tapped', screen: 'BeautyAnalyticsPage');
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _logger.auth('Check-in aborted | no authenticated user');
        return;
      }

      final checkinData = await BeautyCheckinSheet.show(
        context,
        userId: user.id,
      );

      if (checkinData != null) {
        _logger.db('BEFORE | table: beauty_log | op: INSERT via addLog | userId: ${LogHelper.maskUuid(user.id)}');
        try {
          await ref.read(addBeautyLogNotifierProvider.notifier).addLog(
                hairLengthCm: (checkinData['hairLengthCm'] as num?)?.toDouble() ?? 15.0,
                hairStrengthScore: (checkinData['hairStrengthScore'] as num?)?.toDouble() ?? 7.0,
                hairThicknessScore: (checkinData['hairThicknessScore'] as num?)?.toDouble() ?? 7.0,
                hairSheddingRate: checkinData['hairSheddingRate'] as String? ?? 'moderate',
                skinHydrationLevel: (checkinData['skinHydrationLevel'] as num?)?.toDouble() ?? 7.0,
                skinClarityScore: (checkinData['skinClarityScore'] as num?)?.toDouble() ?? 7.0,
                checkinNotes: checkinData['checkinNotes'] as String?,
              );
          _logger.db('AFTER | table: beauty_log | op: INSERT via addLog | success');
        } catch (e, st) {
          _logger.db('ERROR | addLog via BeautyAnalyticsPage | $e', error: e, stackTrace: st);
        }
      } else {
        _logger.userAction('Check-in sheet dismissed without save', screen: 'BeautyAnalyticsPage');
      }
    }
  ```

  `LogHelper` is exported from `core/logger.dart` (already imported), so no new import is needed.

  Run:

  ```
  flutter test test/features/beauty/beauty_analytics_page_test.dart
  ```

  Expected output (unchanged behavior, all 3 tests from Tasks 1 and 3 still pass):

  ```
  00:03 +3: All tests passed!
  ```

- [ ] **Step 2: `lib/features/beauty/widgets/beauty_checkin_sheet.dart` — log the Save button tap.**

  Apply this diff on top of Task 1's full file. Add the import at the top:

  ```dart
  import 'package:flutter/material.dart';
  import '../../../core/logger.dart';
  import '../../../core/theme.dart';
  ```

  Add the logger field and update `_handleSave` in `_BeautyCheckinSheetState`:

  ```dart
  class _BeautyCheckinSheetState extends State<BeautyCheckinSheet> {
    final _logger = appLogger;
    late double _hairLengthCm;
  ```

  ```dart
    void _handleSave() {
      _logger.userAction('Save Progress Check-In tapped', screen: 'BeautyCheckinSheet', metadata: {
        'hairLengthCm': _hairLengthCm,
        'hairStrengthScore': _hairStrengthScore,
        'hairThicknessScore': _hairThicknessScore,
        'skinHydrationLevel': _skinHydrationLevel,
        'skinClarityScore': _skinClarityScore,
        'hairSheddingRate': _hairSheddingRate,
      });
      final payload = <String, dynamic>{
        'userId': widget.userId,
        'hairLengthCm': _hairLengthCm,
        'hairStrengthScore': _hairStrengthScore,
        'hairThicknessScore': _hairThicknessScore,
        'skinHydrationLevel': _skinHydrationLevel,
        'skinClarityScore': _skinClarityScore,
        'hairSheddingRate': _hairSheddingRate,
        'checkinNotes': _notesController.text.trim(),
        'loggedAt': DateTime.now().toIso8601String(),
      };
      _logger.provider('BeautyCheckinSheet payload built | keys: ${payload.keys.join(', ')}');
      if (widget.onSubmit != null) {
        widget.onSubmit!(payload);
      }
      Navigator.of(context).pop(payload);
    }
  ```

  Run:

  ```
  flutter test test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 3: `lib/features/beauty/widgets/today_beauty_routines_widget.dart` — log before/after `toggleCompletion`.**

  Apply this diff on top of Task 2's full file. Add the import and a `static final` logger (must be `static` so the `const` constructor is preserved — `home_page.dart` calls `const TodayBeautyRoutinesWidget()`):

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/logger.dart';
  import '../../../core/router.dart';
  import '../../../core/theme.dart';
  import '../../../providers/beauty_plan_provider.dart';
  import '../../../shared/models/beauty_plan.dart';
  import '../../../shared/widgets/empty_state.dart';

  class TodayBeautyRoutinesWidget extends ConsumerWidget {
    final DateTime Function() now;
    static final _logger = appLogger;

    const TodayBeautyRoutinesWidget({super.key, this.now = DateTime.now});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      _logger.provider('TodayBeautyRoutinesWidget build()');
      final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);
  ```

  Update the `Checkbox.onChanged` inside `_buildTodaySlotCard`:

  ```dart
          trailing: Checkbox(
            value: isCompleted,
            activeColor: AkeliColors.primary,
            onChanged: (val) {
              _logger.userAction(
                'Beauty routine checkbox toggled',
                screen: 'TodayBeautyRoutinesWidget',
                metadata: {'slotId': slot.id, 'from': isCompleted, 'to': !isCompleted},
              );
              _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              ref
                  .read(toggleBeautySlotNotifierProvider.notifier)
                  .toggleCompletion(slot.id, isCompleted)
                  .then((_) {
                _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              }).catchError((e, st) {
                _logger.db('ERROR | toggleCompletion via TodayBeautyRoutinesWidget | $e', error: e, stackTrace: st);
              });
            },
          ),
  ```

  Run:

  ```
  flutter test test/features/beauty/widgets/today_beauty_routines_widget_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 4: `lib/features/meal_planner/widgets/beauty_planner_view.dart` — log the checkbox toggle and the "Générer Mon Plan Beauté" button.**

  Add the import and a `static final` logger (same const-constructor reasoning as Step 3 — `meal_planner_page.dart:48` calls `const BeautyPlannerView()`):

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/logger.dart';
  import '../../../core/router.dart';
  import '../../../core/theme.dart';
  import '../../../providers/beauty_plan_provider.dart';
  import '../../../shared/models/beauty_plan.dart';
  import '../../../shared/widgets/empty_state.dart';

  class BeautyPlannerView extends ConsumerWidget {
    static final _logger = appLogger;

    const BeautyPlannerView({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      _logger.provider('BeautyPlannerView build()');
      final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);
  ```

  Update the `Checkbox.onChanged` inside `_buildBeautySlotCard` (mirrors Step 3's pattern exactly):

  ```dart
          trailing: Checkbox(
            value: isCompleted,
            activeColor: AkeliColors.primary,
            onChanged: (val) {
              _logger.userAction(
                'Beauty routine checkbox toggled',
                screen: 'BeautyPlannerView',
                metadata: {'slotId': slot.id, 'from': isCompleted, 'to': !isCompleted},
              );
              _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              ref
                  .read(toggleBeautySlotNotifierProvider.notifier)
                  .toggleCompletion(slot.id, isCompleted)
                  .then((_) {
                _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              }).catchError((e, st) {
                _logger.db('ERROR | toggleCompletion via BeautyPlannerView | $e', error: e, stackTrace: st);
              });
            },
          ),
  ```

  Update the "Générer Mon Plan Beauté" button inside `_buildEmptyBeautyState`:

  ```dart
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AkeliColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: const Text(
                'Générer Mon Plan Beauté',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _logger.userAction('Générer Mon Plan Beauté tapped', screen: 'BeautyPlannerView');
                _logger.db('BEFORE rpc | fn: generate_beauty_plan');
                ref.read(generateBeautyPlanNotifierProvider.notifier).generatePlan().then((_) {
                  _logger.db('AFTER rpc | fn: generate_beauty_plan | success');
                }).catchError((e, st) {
                  _logger.db('ERROR rpc | fn: generate_beauty_plan | $e', error: e, stackTrace: st);
                });
              },
            ),
  ```

  Run:

  ```
  flutter test test/features/meal_planner/widgets/beauty_planner_view_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 5: `lib/shared/widgets/color_set_modal.dart` — log preset selection and Apply button taps.**

  Add the import and logger field to `_ColorSetModalState` (a `State` class — not const, no constructor concerns):

  ```dart
  import 'package:flutter/material.dart';
  import '../../core/logger.dart';
  import '../../core/theme.dart';
  ```

  ```dart
  class _ColorSetModalState extends State<ColorSetModal> {
    final _logger = appLogger;
    late ColorSetPreset _selectedPreset;
  ```

  Update the preset `ListTile.onTap`:

  ```dart
                onTap: () {
                  _logger.userAction('Color preset selected', screen: 'ColorSetModal', metadata: {'preset': preset.name});
                  setState(() => _selectedPreset = preset);
                },
  ```

  Update the Apply button's `onPressed`:

  ```dart
              onPressed: () {
                _logger.userAction('Apply color palette tapped', screen: 'ColorSetModal', metadata: {'preset': _selectedPreset.name});
                if (widget.onSelect != null) {
                  widget.onSelect!(_selectedPreset.primary, _selectedPreset.secondary);
                }
                Navigator.of(context).pop(_selectedPreset);
              },
  ```

  Run:

  ```
  flutter test test/shared/widgets/color_set_modal_test.dart
  ```

  Expected output:

  ```
  00:02 +1: All tests passed!
  ```

- [ ] **Step 6: Run the whole area's test suite once to confirm no regressions, then commit.**

  ```
  flutter test test/features/beauty/ test/features/meal_planner/widgets/beauty_planner_view_test.dart test/shared/widgets/color_set_modal_test.dart
  ```

  Expected output:

  ```
  00:06 +11: All tests passed!
  ```

  ```
  git add lib/features/beauty/beauty_analytics_page.dart lib/features/beauty/widgets/beauty_checkin_sheet.dart lib/features/beauty/widgets/today_beauty_routines_widget.dart lib/features/meal_planner/widgets/beauty_planner_view.dart lib/shared/widgets/color_set_modal.dart
  git commit -m "feat(beauty): add mandatory structured logging to the 5 Beauty UI files with zero appLogger calls"
  ```

### Task 5: Replace ~188 hardcoded strings with `AppLocalizations` across all 6 files (High)

**Files:**
- `lib/l10n/app_en.arb` (add new keys only)
- `lib/l10n/app_fr.arb` (add new keys only)
- `lib/features/beauty/beauty_analytics_page.dart` (fix — on top of Task 4's version)
- `lib/features/beauty/beauty_onboarding_page.dart` (fix)
- `lib/features/beauty/widgets/beauty_checkin_sheet.dart` (fix — on top of Task 4's version)
- `lib/features/beauty/widgets/today_beauty_routines_widget.dart` (fix — on top of Task 4's version)
- `lib/features/meal_planner/widgets/beauty_planner_view.dart` (fix — on top of Task 4's version)
- `lib/shared/widgets/color_set_modal.dart` (fix — on top of Task 4's version)
- `test/features/beauty/beauty_analytics_page_test.dart`, `test/features/beauty/beauty_onboarding_page_test.dart`, `test/features/beauty/widgets/beauty_checkin_sheet_test.dart`, `test/features/beauty/widgets/today_beauty_routines_widget_test.dart`, `test/features/meal_planner/widgets/beauty_planner_view_test.dart`, `test/shared/widgets/color_set_modal_test.dart` (add `localizationsDelegates`/`supportedLocales`/`locale` wrapping)

**Interfaces:** No public API changes beyond `ColorSetPreset` gaining a new `id` field (see Step 7 — required so preset *identity* does not depend on a now-localized display `name`). Every private `_build*` helper method keeps its existing signature; each simply calls `AppLocalizations.of(context)` at its own top (all owning classes are `State`/`ConsumerState`/`ConsumerWidget` types where `context` is already in scope).

This is a mechanical, additive-only l10n pass: every ARB key added here is new (nothing existing is edited), so this task cannot conflict with any other plan's ARB edits. `beauty_onboarding_page.dart`'s ~109 keys make it by far the largest sub-step — do it last so the smaller files establish the pattern first.

### Steps

- [ ] **Step 1: Append ALL new keys to `lib/l10n/app_en.arb`.**

  Open `lib/l10n/app_en.arb`. The file currently ends with:

  ```json
    "onboardingValidationAgeMax": "Age must be at most 100",
    "@onboardingValidationAgeMax": {}
  }
  ```

  Change the line `"@onboardingValidationAgeMax": {}` to end with a comma, then insert the entire block below immediately before the final `}`:

  ```json
    "onboardingValidationAgeMax": "Age must be at most 100",
    "@onboardingValidationAgeMax": {},

    "beautyAnalyticsTitle": "Beauty & Rituals Tracking",
    "@beautyAnalyticsTitle": {},
    "beautyAnalyticsNewCheckinTooltip": "New Beauty Check-In",
    "@beautyAnalyticsNewCheckinTooltip": {},
    "beautyAnalyticsHeaderBadge": "DIAGNOSTIC & RITUAL TRACKING",
    "@beautyAnalyticsHeaderBadge": {},
    "beautyAnalyticsHeaderTitle": "Beauty Dashboard 👑",
    "@beautyAnalyticsHeaderTitle": {},
    "beautyAnalyticsHeaderSubtitle": "Analyze your ritual consistency, hair growth and complexion evolution.",
    "@beautyAnalyticsHeaderSubtitle": {},
    "beautyAnalyticsTimeframe7d": "7 Days",
    "@beautyAnalyticsTimeframe7d": {},
    "beautyAnalyticsTimeframe30d": "30 Days",
    "@beautyAnalyticsTimeframe30d": {},
    "beautyAnalyticsTimeframe90d": "90 Days",
    "@beautyAnalyticsTimeframe90d": {},
    "beautyAnalyticsTimeframeAll": "All",
    "@beautyAnalyticsTimeframeAll": {},
    "beautyAnalyticsNewCheckinFab": "New Check-In",
    "@beautyAnalyticsNewCheckinFab": {},
    "beautyAnalyticsAdherenceLabel": "Ritual Adherence",
    "@beautyAnalyticsAdherenceLabel": {},
    "beautyAnalyticsAdherenceFraction": "({completed}/{total} treatments)",
    "@beautyAnalyticsAdherenceFraction": {
      "placeholders": { "completed": { "type": "String" }, "total": { "type": "String" } }
    },
    "beautyAnalyticsLoadError": "Error loading check-ins: {error}",
    "@beautyAnalyticsLoadError": {
      "placeholders": { "error": { "type": "String" } }
    },
    "beautyAnalyticsHairSectionTitle": "Hair Diagnostic 👑",
    "@beautyAnalyticsHairSectionTitle": {},
    "beautyAnalyticsHairLengthLabel": "Length",
    "@beautyAnalyticsHairLengthLabel": {},
    "beautyAnalyticsValueCm": "{value} cm",
    "@beautyAnalyticsValueCm": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsValueOutOfTen": "{value}/10",
    "@beautyAnalyticsValueOutOfTen": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsHairLengthGrowthPositive": "+{value} cm gained",
    "@beautyAnalyticsHairLengthGrowthPositive": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsHairLengthGrowthNegative": "{value} cm",
    "@beautyAnalyticsHairLengthGrowthNegative": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsHairStrengthLabel": "Strength & Density",
    "@beautyAnalyticsHairStrengthLabel": {},
    "beautyAnalyticsHairStrengthSubtitle": "Resistance score",
    "@beautyAnalyticsHairStrengthSubtitle": {},
    "beautyAnalyticsSheddingLabel": "Shedding Level (Anti-Breakage)",
    "@beautyAnalyticsSheddingLabel": {},
    "beautyAnalyticsSheddingModerate": "Moderate",
    "@beautyAnalyticsSheddingModerate": {},
    "beautyAnalyticsSheddingLow": "Low (Ideal)",
    "@beautyAnalyticsSheddingLow": {},
    "beautyAnalyticsSheddingHigh": "High (Attention)",
    "@beautyAnalyticsSheddingHigh": {},
    "beautyAnalyticsSkinSectionTitle": "Skin Diagnostic ✨",
    "@beautyAnalyticsSkinSectionTitle": {},
    "beautyAnalyticsSkinHydrationLabel": "Skin Hydration",
    "@beautyAnalyticsSkinHydrationLabel": {},
    "beautyAnalyticsSkinHydrationSubtitle": "Moisture barrier",
    "@beautyAnalyticsSkinHydrationSubtitle": {},
    "beautyAnalyticsSkinClarityLabel": "Radiance & Complexion",
    "@beautyAnalyticsSkinClarityLabel": {},
    "beautyAnalyticsSkinClaritySubtitle": "Skin clarity",
    "@beautyAnalyticsSkinClaritySubtitle": {},
    "beautyAnalyticsHistoryTitle": "Log History 📖",
    "@beautyAnalyticsHistoryTitle": {},
    "beautyAnalyticsHistoryCount": "{count, plural, one{{count} log} other{{count} logs}}",
    "@beautyAnalyticsHistoryCount": {
      "placeholders": { "count": { "type": "int" } }
    },
    "beautyAnalyticsHistoryEmpty": "No beauty check-ins recorded yet.",
    "@beautyAnalyticsHistoryEmpty": {},
    "beautyAnalyticsHistoryEntryNumber": "Check-In #{number}",
    "@beautyAnalyticsHistoryEntryNumber": {
      "placeholders": { "number": { "type": "String" } }
    },
    "beautyAnalyticsChipLength": "📏 {value} cm",
    "@beautyAnalyticsChipLength": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsChipStrength": "💪 Strength: {value}/10",
    "@beautyAnalyticsChipStrength": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsChipHydration": "💧 Hydration: {value}/10",
    "@beautyAnalyticsChipHydration": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsChipClarity": "✨ Radiance: {value}/10",
    "@beautyAnalyticsChipClarity": {
      "placeholders": { "value": { "type": "String" } }
    },

    "beautyOnboardingTitle": "Botanical Beauty Profile",
    "@beautyOnboardingTitle": {},
    "beautyOnboardingBackButton": "Back",
    "@beautyOnboardingBackButton": {},
    "beautyOnboardingNextButton": "Next Step ➔",
    "@beautyOnboardingNextButton": {},
    "beautyOnboardingSubmitButton": "Confirm & Generate My 30-Day Plan ✨",
    "@beautyOnboardingSubmitButton": {},
    "beautyOnboardingStep1Title": "👑 Hair Fingerprint",
    "@beautyOnboardingStep1Title": {},
    "beautyOnboardingStep1Subtitle": "Define the precise composition and porosity of your hair to personalize your botanical care.",
    "@beautyOnboardingStep1Subtitle": {},
    "beautyOnboardingHairCompositionLabel": "Hair Composition & Texture",
    "@beautyOnboardingHairCompositionLabel": {},
    "beautyOnboardingHairType4c": "4C — Very Tight Coily (Z-Pattern, Strong Shrinkage)",
    "@beautyOnboardingHairType4c": {},
    "beautyOnboardingHairType4b": "4B — Zigzag Coily (Defined Z-Shaped Curls)",
    "@beautyOnboardingHairType4b": {},
    "beautyOnboardingHairType4a": "4A — S-Pattern Coily (Dense Spirals)",
    "@beautyOnboardingHairType4a": {},
    "beautyOnboardingHairType3c": "3C — Dense Curly (Tight Spirals)",
    "@beautyOnboardingHairType3c": {},
    "beautyOnboardingHairType3b": "3B — Tight Corkscrew Curls",
    "@beautyOnboardingHairType3b": {},
    "beautyOnboardingHairType3a": "3A — Loose, Soft Curls",
    "@beautyOnboardingHairType3a": {},
    "beautyOnboardingHairType2c": "2C — Thick Waves",
    "@beautyOnboardingHairType2c": {},
    "beautyOnboardingHairType2b": "2B — Defined Waves",
    "@beautyOnboardingHairType2b": {},
    "beautyOnboardingHairType2a": "2A — Light Waves",
    "@beautyOnboardingHairType2a": {},
    "beautyOnboardingHairType1c": "1C — Thick Straight Hair",
    "@beautyOnboardingHairType1c": {},
    "beautyOnboardingHairType1b": "1B — Medium Straight Hair",
    "@beautyOnboardingHairType1b": {},
    "beautyOnboardingHairType1a": "1A — Very Fine Straight Hair",
    "@beautyOnboardingHairType1a": {},
    "beautyOnboardingHairTypeLocks": "Locks / Dreadlocks (Locked)",
    "@beautyOnboardingHairTypeLocks": {},
    "beautyOnboardingHairTypeTransition": "Transitioning Hair (Post-Relaxer)",
    "@beautyOnboardingHairTypeTransition": {},
    "beautyOnboardingHairTypeProtective": "Care Under Braids / Wig",
    "@beautyOnboardingHairTypeProtective": {},
    "beautyOnboardingPorosityLabel": "Hair Porosity",
    "@beautyOnboardingPorosityLabel": {},
    "beautyOnboardingPorosityLow": "Low (Closed cuticles)",
    "@beautyOnboardingPorosityLow": {},
    "beautyOnboardingPorosityMedium": "Medium (Perfect balance)",
    "@beautyOnboardingPorosityMedium": {},
    "beautyOnboardingPorosityHigh": "Highly Porous (Open cuticles)",
    "@beautyOnboardingPorosityHigh": {},
    "beautyOnboardingScalpLabel": "Scalp Condition",
    "@beautyOnboardingScalpLabel": {},
    "beautyOnboardingScalpNormal": "Normal / Balanced",
    "@beautyOnboardingScalpNormal": {},
    "beautyOnboardingScalpDry": "Dry & Itchy",
    "@beautyOnboardingScalpDry": {},
    "beautyOnboardingScalpOily": "Oily / Dandruff",
    "@beautyOnboardingScalpOily": {},
    "beautyOnboardingScalpSensitive": "Sensitive / Irritated",
    "@beautyOnboardingScalpSensitive": {},
    "beautyOnboardingStep2Title": "✨ Deep Skin Diagnostic",
    "@beautyOnboardingStep2Title": {},
    "beautyOnboardingStep2Subtitle": "Analyze the overall typology and specific challenges of your skin (face & body).",
    "@beautyOnboardingStep2Subtitle": {},
    "beautyOnboardingSkinTypeLabel": "Skin Composition & Typology",
    "@beautyOnboardingSkinTypeLabel": {},
    "beautyOnboardingSkinTypeMixte": "Combination Skin (Shiny T-Zone, normal/dry cheeks)",
    "@beautyOnboardingSkinTypeMixte": {},
    "beautyOnboardingSkinTypeSeche": "Dry & Dehydrated Skin (Tightness & flaking)",
    "@beautyOnboardingSkinTypeSeche": {},
    "beautyOnboardingSkinTypeGrasse": "Oily & Acne-Prone Skin (Excess sebum, enlarged pores)",
    "@beautyOnboardingSkinTypeGrasse": {},
    "beautyOnboardingSkinTypeSensible": "Sensitive & Reactive Skin (Redness, rosacea)",
    "@beautyOnboardingSkinTypeSensible": {},
    "beautyOnboardingSkinTypeHyperpigmentation": "Hyperpigmentation-Prone Skin (Dark spots, melasma)",
    "@beautyOnboardingSkinTypeHyperpigmentation": {},
    "beautyOnboardingSkinTypeMature": "Mature Skin (Loss of firmness & expression lines)",
    "@beautyOnboardingSkinTypeMature": {},
    "beautyOnboardingSkinTypeNormale": "Normal / Balanced Skin",
    "@beautyOnboardingSkinTypeNormale": {},
    "beautyOnboardingSkinConcernsLabel": "Skin Concerns (Face & Neckline)",
    "@beautyOnboardingSkinConcernsLabel": {},
    "beautyOnboardingConcernHyperpigmentation": "🌖 Dark Spots & Uneven Tone",
    "@beautyOnboardingConcernHyperpigmentation": {},
    "beautyOnboardingConcernAcne": "🌋 Blemishes & Imperfections",
    "@beautyOnboardingConcernAcne": {},
    "beautyOnboardingConcernDehydration": "💧 Deep Dehydration & Loss of Radiance",
    "@beautyOnboardingConcernDehydration": {},
    "beautyOnboardingConcernBarrier": "🛡️ Weakened Skin Barrier & Sensitivity",
    "@beautyOnboardingConcernBarrier": {},
    "beautyOnboardingConcernSebum": "✨ Excess Shine & Enlarged Pores",
    "@beautyOnboardingConcernSebum": {},
    "beautyOnboardingConcernAging": "🌿 Loss of Elasticity & Expression Lines",
    "@beautyOnboardingConcernAging": {},
    "beautyOnboardingBodyProfileLabel": "Body Specifics",
    "@beautyOnboardingBodyProfileLabel": {},
    "beautyOnboardingBodyNormal": "Normal / No Issues",
    "@beautyOnboardingBodyNormal": {},
    "beautyOnboardingBodyKeratose": "Keratosis Pilaris (Goosebumps)",
    "@beautyOnboardingBodyKeratose": {},
    "beautyOnboardingBodyEczema": "Eczema / Prone to Flare-ups",
    "@beautyOnboardingBodyEczema": {},
    "beautyOnboardingBodyVergetures": "Stretch Mark Prevention",
    "@beautyOnboardingBodyVergetures": {},
    "beautyOnboardingBodyDrySkin": "Very Dry Body Skin (Crocodile)",
    "@beautyOnboardingBodyDrySkin": {},
    "beautyOnboardingStep3Title": "🌱 Beauty Goals & Priorities",
    "@beautyOnboardingStep3Title": {},
    "beautyOnboardingStep3Subtitle": "Select your hair and skin priorities to calibrate your 30-day routine.",
    "@beautyOnboardingStep3Subtitle": {},
    "beautyOnboardingHairGoalsLabel": "Hair Goals 👑",
    "@beautyOnboardingHairGoalsLabel": {},
    "beautyOnboardingGoalHairGrowth": "🌱 Growth, Density & Length",
    "@beautyOnboardingGoalHairGrowth": {},
    "beautyOnboardingGoalAntiBreakage": "🛡️ Strength, Retention & Anti-Breakage",
    "@beautyOnboardingGoalAntiBreakage": {},
    "beautyOnboardingGoalHairMoisture": "💧 Deep Hydration & Definition",
    "@beautyOnboardingGoalHairMoisture": {},
    "beautyOnboardingGoalScalpSoothing": "💆 Scalp Balance & Soothing",
    "@beautyOnboardingGoalScalpSoothing": {},
    "beautyOnboardingSkinGoalsLabel": "Skin & Complexion Goals ✨",
    "@beautyOnboardingSkinGoalsLabel": {},
    "beautyOnboardingGoalSkinGlow": "✨ Radiance & Even Complexion",
    "@beautyOnboardingGoalSkinGlow": {},
    "beautyOnboardingGoalAntiSpot": "🌖 Reducing Spots & Hyperpigmentation",
    "@beautyOnboardingGoalAntiSpot": {},
    "beautyOnboardingGoalSkinMoisture": "💧 Hydration & Skin Suppleness",
    "@beautyOnboardingGoalSkinMoisture": {},
    "beautyOnboardingGoalAntiImperfection": "🌋 Clarifying & Anti-Blemish",
    "@beautyOnboardingGoalAntiImperfection": {},
    "beautyOnboardingGoalSkinBarrier": "🛡️ Strengthening the Skin Barrier",
    "@beautyOnboardingGoalSkinBarrier": {},
    "beautyOnboardingStep4Title": "📊 First Baseline Check-In (First Beauty Log)",
    "@beautyOnboardingStep4Title": {},
    "beautyOnboardingStep4Subtitle": "Enter your starting measurements and observations. This first log will serve as your baseline to measure your progress over 30 days.",
    "@beautyOnboardingStep4Subtitle": {},
    "beautyOnboardingHairLengthLabel": "📏 Current Hair Length",
    "@beautyOnboardingHairLengthLabel": {},
    "beautyOnboardingValueCm": "{value} cm",
    "@beautyOnboardingValueCm": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyOnboardingHairStrengthLabel": "💪 Hair Strength & Resistance",
    "@beautyOnboardingHairStrengthLabel": {},
    "beautyOnboardingValueOutOfTen": "{value}/10",
    "@beautyOnboardingValueOutOfTen": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyOnboardingSheddingRateLabel": "📊 Current Shedding Rate",
    "@beautyOnboardingSheddingRateLabel": {},
    "beautyOnboardingSheddingLow": "Low",
    "@beautyOnboardingSheddingLow": {},
    "beautyOnboardingSheddingModerate": "Moderate",
    "@beautyOnboardingSheddingModerate": {},
    "beautyOnboardingSheddingHigh": "High",
    "@beautyOnboardingSheddingHigh": {},
    "beautyOnboardingSkinHydrationLabel": "💧 Skin Hydration Level",
    "@beautyOnboardingSkinHydrationLabel": {},
    "beautyOnboardingSkinClarityLabel": "✨ Complexion Radiance & Clarity",
    "@beautyOnboardingSkinClarityLabel": {},
    "beautyOnboardingNotesLabel": "📝 Initial Notes & Observations",
    "@beautyOnboardingNotesLabel": {},
    "beautyOnboardingNotesHint": "Notes on the condition of your hair and skin...",
    "@beautyOnboardingNotesHint": {},
    "beautyOnboardingDefaultNotes": "Initial beauty profile check-in",
    "@beautyOnboardingDefaultNotes": {},
    "beautyOnboardingSummaryTitle": "📋 Summary & Confirmation",
    "@beautyOnboardingSummaryTitle": {},
    "beautyOnboardingSummarySubtitle": "Review your beauty profile summary before activating your personalized 30-day program.",
    "@beautyOnboardingSummarySubtitle": {},
    "beautyOnboardingSummaryHairCardTitle": "👑 Hair Profile",
    "@beautyOnboardingSummaryHairCardTitle": {},
    "beautyOnboardingSummaryHairTypeRow": "Texture / Type:",
    "@beautyOnboardingSummaryHairTypeRow": {},
    "beautyOnboardingSummaryPorosityRow": "Porosity:",
    "@beautyOnboardingSummaryPorosityRow": {},
    "beautyOnboardingSummaryPorosityLowValue": "Low",
    "@beautyOnboardingSummaryPorosityLowValue": {},
    "beautyOnboardingSummaryPorosityHighValue": "Porous",
    "@beautyOnboardingSummaryPorosityHighValue": {},
    "beautyOnboardingSummaryPorosityMediumValue": "Medium",
    "@beautyOnboardingSummaryPorosityMediumValue": {},
    "beautyOnboardingSummaryScalpRow": "Scalp:",
    "@beautyOnboardingSummaryScalpRow": {},
    "beautyOnboardingSummaryScalpDryValue": "Dry",
    "@beautyOnboardingSummaryScalpDryValue": {},
    "beautyOnboardingSummaryScalpOilyValue": "Oily",
    "@beautyOnboardingSummaryScalpOilyValue": {},
    "beautyOnboardingSummaryScalpSensitiveValue": "Sensitive",
    "@beautyOnboardingSummaryScalpSensitiveValue": {},
    "beautyOnboardingSummaryScalpNormalValue": "Normal",
    "@beautyOnboardingSummaryScalpNormalValue": {},
    "beautyOnboardingSummarySkinCardTitle": "✨ Skin Diagnostic",
    "@beautyOnboardingSummarySkinCardTitle": {},
    "beautyOnboardingSummarySkinTypeRow": "Typology:",
    "@beautyOnboardingSummarySkinTypeRow": {},
    "beautyOnboardingSummaryConcernsRow": "Concerns:",
    "@beautyOnboardingSummaryConcernsRow": {},
    "beautyOnboardingSummaryConcernsNone": "None",
    "@beautyOnboardingSummaryConcernsNone": {},
    "beautyOnboardingSummaryBodyProfileRow": "Body Specifics:",
    "@beautyOnboardingSummaryBodyProfileRow": {},
    "beautyOnboardingSummaryGoalsCardTitle": "🌱 Selected Goals",
    "@beautyOnboardingSummaryGoalsCardTitle": {},
    "beautyOnboardingSummaryFirstLogCardTitle": "📊 First Check-In Measurements",
    "@beautyOnboardingSummaryFirstLogCardTitle": {},
    "beautyOnboardingSummaryHairLengthRow": "Hair Length:",
    "@beautyOnboardingSummaryHairLengthRow": {},
    "beautyOnboardingSummaryHairStrengthRow": "Hair Strength:",
    "@beautyOnboardingSummaryHairStrengthRow": {},
    "beautyOnboardingSummarySheddingRow": "Shedding Rate:",
    "@beautyOnboardingSummarySheddingRow": {},
    "beautyOnboardingSummarySkinHydrationRow": "Skin Hydration:",
    "@beautyOnboardingSummarySkinHydrationRow": {},
    "beautyOnboardingSummaryClarityRow": "Complexion Radiance:",
    "@beautyOnboardingSummaryClarityRow": {},
    "beautyOnboardingSummaryNotesRow": "Notes:",
    "@beautyOnboardingSummaryNotesRow": {},
    "beautyOnboardingSummaryEditTooltip": "Edit",
    "@beautyOnboardingSummaryEditTooltip": {},
    "beautyOnboardingSaveErrorSnackbar": "Error saving: {error}",
    "@beautyOnboardingSaveErrorSnackbar": {
      "placeholders": { "error": { "type": "String" } }
    },

    "beautyCheckinTitle": "Beauty Check-In & Evolution",
    "@beautyCheckinTitle": {},
    "beautyCheckinSubtitle": "Record your monthly hair length and skin barrier check-in.",
    "@beautyCheckinSubtitle": {},
    "beautyCheckinHairLengthLabel": "Hair Length: {value} cm",
    "@beautyCheckinHairLengthLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinHairStrengthLabel": "Hair Strength Score: {value} / 10",
    "@beautyCheckinHairStrengthLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinHairThicknessLabel": "Hair Thickness Score: {value} / 10",
    "@beautyCheckinHairThicknessLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinSkinHydrationLabel": "Skin Hydration Level: {value} / 10",
    "@beautyCheckinSkinHydrationLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinSkinClarityLabel": "Skin Clarity Score: {value} / 10",
    "@beautyCheckinSkinClarityLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinNotesLabel": "Check-in Journal Notes (Optional)",
    "@beautyCheckinNotesLabel": {},
    "beautyCheckinNotesHint": "e.g. Hair feeling noticeably softer after Chébé mask!",
    "@beautyCheckinNotesHint": {},
    "beautyCheckinSaveButton": "Save Progress Check-In",
    "@beautyCheckinSaveButton": {},
    "beautyCheckinSheddingLabel": "Hair Shedding Rate",
    "@beautyCheckinSheddingLabel": {},
    "beautyCheckinSheddingLow": "Low",
    "@beautyCheckinSheddingLow": {},
    "beautyCheckinSheddingModerate": "Moderate",
    "@beautyCheckinSheddingModerate": {},
    "beautyCheckinSheddingHigh": "High",
    "@beautyCheckinSheddingHigh": {},

    "todayBeautyRoutinesTitle": "Today's Rituals 👑",
    "@todayBeautyRoutinesTitle": {},
    "todayBeautyRoutinesPlanningLink": "Plan (30d)",
    "@todayBeautyRoutinesPlanningLink": {},
    "todayBeautyRoutinesEmptyTitle": "No rituals today",
    "@todayBeautyRoutinesEmptyTitle": {},
    "todayBeautyRoutinesEmptySubtitle": "Generate your monthly plan in the Routine tab.",
    "@todayBeautyRoutinesEmptySubtitle": {},
    "todayBeautyRoutinesRestDay": "Rest day for your scalp & skin!",
    "@todayBeautyRoutinesRestDay": {},
    "todayBeautyRoutinesLoadError": "Error loading rituals: {error}",
    "@todayBeautyRoutinesLoadError": {
      "placeholders": { "error": { "type": "String" } }
    },
    "todayBeautyRoutinesTierLabel": "Tier: {tier}",
    "@todayBeautyRoutinesTierLabel": {
      "placeholders": { "tier": { "type": "String" } }
    },
    "todayBeautyRoutinesDefaultLabel": "Ritual",
    "@todayBeautyRoutinesDefaultLabel": {},

    "beautyPlannerLoadError": "Error loading care plan: {error}",
    "@beautyPlannerLoadError": {
      "placeholders": { "error": { "type": "String" } }
    },
    "beautyPlannerHeaderTitle": "My Monthly Care Plan",
    "@beautyPlannerHeaderTitle": {},
    "beautyPlannerHeaderSubtitle": "Personalized hair & skin care routines (30 days).",
    "@beautyPlannerHeaderSubtitle": {},
    "beautyPlannerDailySectionTitle": "💧 Daily Care (Hydration)",
    "@beautyPlannerDailySectionTitle": {},
    "beautyPlannerWeeklySectionTitle": "🌿 Weekly Care (Masks & Baths)",
    "@beautyPlannerWeeklySectionTitle": {},
    "beautyPlannerMonthlySectionTitle": "✨ Monthly & Protein Care",
    "@beautyPlannerMonthlySectionTitle": {},
    "beautyPlannerSectionCount": "{count, plural, one{{count} treatment} other{{count} treatments}}",
    "@beautyPlannerSectionCount": {
      "placeholders": { "count": { "type": "int" } }
    },
    "beautyPlannerDayLabel": "Day {day}",
    "@beautyPlannerDayLabel": {
      "placeholders": { "day": { "type": "String" } }
    },
    "beautyPlannerEmptyTitle": "No Active Care Plan",
    "@beautyPlannerEmptyTitle": {},
    "beautyPlannerEmptySubtitle": "Generate your monthly hair and skin care routine tailored to your profile.",
    "@beautyPlannerEmptySubtitle": {},
    "beautyPlannerGenerateButton": "Generate My Beauty Plan",
    "@beautyPlannerGenerateButton": {},

    "colorSetModalTitle": "Customize Color Theme",
    "@colorSetModalTitle": {},
    "colorSetModalSubtitle": "Select a Primary & Secondary color palette.",
    "@colorSetModalSubtitle": {},
    "colorSetModalPresetTealName": "Teal & Amber (Nutrition)",
    "@colorSetModalPresetTealName": {},
    "colorSetModalPresetTealDesc": "Balanced, healthy and energizing.",
    "@colorSetModalPresetTealDesc": {},
    "colorSetModalPresetRoseName": "Rose & Gold (Beauty)",
    "@colorSetModalPresetRoseName": {},
    "colorSetModalPresetRoseDesc": "Editorial luxury, organic care & radiance.",
    "@colorSetModalPresetRoseDesc": {},
    "colorSetModalPresetSageName": "Sage & Bronze (Botanical)",
    "@colorSetModalPresetSageName": {},
    "colorSetModalPresetSageDesc": "Ancestral plants & nature.",
    "@colorSetModalPresetSageDesc": {},
    "colorSetModalPresetTerracottaName": "Terracotta & Clay (Sun)",
    "@colorSetModalPresetTerracottaName": {},
    "colorSetModalPresetTerracottaDesc": "Earthy African tones & warmth.",
    "@colorSetModalPresetTerracottaDesc": {},
    "colorSetModalApplyButton": "Apply This Palette",
    "@colorSetModalApplyButton": {}
  }
  ```

  Total new keys added: 188 (38 `beautyAnalytics*` + 110 `beautyOnboarding*` + 10 `beautyCheckin*` + 8 `todayBeautyRoutines*` + 11 `beautyPlanner*` + 11 `colorSetModal*`). `beautyCheckin*` gains 4 more keys in Task 6, for a final area total of 192.

- [ ] **Step 2: Append the mirrored French keys to `lib/l10n/app_fr.arb`.**

  Same mechanic: change the final `"@onboardingValidationAgeMax": {}` to end with a comma and insert this block (same keys, same order, French values — for `beautyCheckin*` this is a **translation** of the English text added in Step 1, per the finding, since this file was originally hardcoded in English while every sibling Beauty screen was hardcoded in French):

  ```json
    "onboardingValidationAgeMax": "L'âge doit être d'au plus 100 ans",
    "@onboardingValidationAgeMax": {},

    "beautyAnalyticsTitle": "Suivi Beauté & Rituals",
    "@beautyAnalyticsTitle": {},
    "beautyAnalyticsNewCheckinTooltip": "Nouveau Bilan Beauté",
    "@beautyAnalyticsNewCheckinTooltip": {},
    "beautyAnalyticsHeaderBadge": "DIAGNOSTIC & SUIVI RITUEL",
    "@beautyAnalyticsHeaderBadge": {},
    "beautyAnalyticsHeaderTitle": "Tableau de Bord Beauté 👑",
    "@beautyAnalyticsHeaderTitle": {},
    "beautyAnalyticsHeaderSubtitle": "Analysez votre régularité rituelle, la repousse capillaire et l'évolution de votre teint.",
    "@beautyAnalyticsHeaderSubtitle": {},
    "beautyAnalyticsTimeframe7d": "7 Jours",
    "@beautyAnalyticsTimeframe7d": {},
    "beautyAnalyticsTimeframe30d": "30 Jours",
    "@beautyAnalyticsTimeframe30d": {},
    "beautyAnalyticsTimeframe90d": "90 Jours",
    "@beautyAnalyticsTimeframe90d": {},
    "beautyAnalyticsTimeframeAll": "Tout",
    "@beautyAnalyticsTimeframeAll": {},
    "beautyAnalyticsNewCheckinFab": "Nouveau Bilan",
    "@beautyAnalyticsNewCheckinFab": {},
    "beautyAnalyticsAdherenceLabel": "Assiduité du Rituel",
    "@beautyAnalyticsAdherenceLabel": {},
    "beautyAnalyticsAdherenceFraction": "({completed}/{total} soins)",
    "@beautyAnalyticsAdherenceFraction": {
      "placeholders": { "completed": { "type": "String" }, "total": { "type": "String" } }
    },
    "beautyAnalyticsLoadError": "Erreur de chargement des bilans: {error}",
    "@beautyAnalyticsLoadError": {
      "placeholders": { "error": { "type": "String" } }
    },
    "beautyAnalyticsHairSectionTitle": "Diagnostic Capillaire 👑",
    "@beautyAnalyticsHairSectionTitle": {},
    "beautyAnalyticsHairLengthLabel": "Longueur",
    "@beautyAnalyticsHairLengthLabel": {},
    "beautyAnalyticsValueCm": "{value} cm",
    "@beautyAnalyticsValueCm": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsValueOutOfTen": "{value}/10",
    "@beautyAnalyticsValueOutOfTen": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsHairLengthGrowthPositive": "+{value} cm gagnés",
    "@beautyAnalyticsHairLengthGrowthPositive": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsHairLengthGrowthNegative": "{value} cm",
    "@beautyAnalyticsHairLengthGrowthNegative": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsHairStrengthLabel": "Force & Densité",
    "@beautyAnalyticsHairStrengthLabel": {},
    "beautyAnalyticsHairStrengthSubtitle": "Score de résistance",
    "@beautyAnalyticsHairStrengthSubtitle": {},
    "beautyAnalyticsSheddingLabel": "Niveau de Chute (Anti-Casse)",
    "@beautyAnalyticsSheddingLabel": {},
    "beautyAnalyticsSheddingModerate": "Modérée",
    "@beautyAnalyticsSheddingModerate": {},
    "beautyAnalyticsSheddingLow": "Faible (Idéal)",
    "@beautyAnalyticsSheddingLow": {},
    "beautyAnalyticsSheddingHigh": "Élevée (Attention)",
    "@beautyAnalyticsSheddingHigh": {},
    "beautyAnalyticsSkinSectionTitle": "Diagnostic Cutané ✨",
    "@beautyAnalyticsSkinSectionTitle": {},
    "beautyAnalyticsSkinHydrationLabel": "Hydratation Cutanée",
    "@beautyAnalyticsSkinHydrationLabel": {},
    "beautyAnalyticsSkinHydrationSubtitle": "Barrière hydrique",
    "@beautyAnalyticsSkinHydrationSubtitle": {},
    "beautyAnalyticsSkinClarityLabel": "Éclat & Teint",
    "@beautyAnalyticsSkinClarityLabel": {},
    "beautyAnalyticsSkinClaritySubtitle": "Clarification du grain",
    "@beautyAnalyticsSkinClaritySubtitle": {},
    "beautyAnalyticsHistoryTitle": "Historique du Journal 📖",
    "@beautyAnalyticsHistoryTitle": {},
    "beautyAnalyticsHistoryCount": "{count, plural, one{{count} bilan} other{{count} bilans}}",
    "@beautyAnalyticsHistoryCount": {
      "placeholders": { "count": { "type": "int" } }
    },
    "beautyAnalyticsHistoryEmpty": "Aucun bilan beauté enregistré pour l'instant.",
    "@beautyAnalyticsHistoryEmpty": {},
    "beautyAnalyticsHistoryEntryNumber": "Bilan #{number}",
    "@beautyAnalyticsHistoryEntryNumber": {
      "placeholders": { "number": { "type": "String" } }
    },
    "beautyAnalyticsChipLength": "📏 {value} cm",
    "@beautyAnalyticsChipLength": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsChipStrength": "💪 Force: {value}/10",
    "@beautyAnalyticsChipStrength": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsChipHydration": "💧 Hydratation: {value}/10",
    "@beautyAnalyticsChipHydration": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyAnalyticsChipClarity": "✨ Éclat: {value}/10",
    "@beautyAnalyticsChipClarity": {
      "placeholders": { "value": { "type": "String" } }
    },

    "beautyOnboardingTitle": "Profil Beauté Botanique",
    "@beautyOnboardingTitle": {},
    "beautyOnboardingBackButton": "Retour",
    "@beautyOnboardingBackButton": {},
    "beautyOnboardingNextButton": "Étape Suivante ➔",
    "@beautyOnboardingNextButton": {},
    "beautyOnboardingSubmitButton": "Confirmer & Générer Mon Plan 30 Jours ✨",
    "@beautyOnboardingSubmitButton": {},
    "beautyOnboardingStep1Title": "👑 Empreinte Capillaire",
    "@beautyOnboardingStep1Title": {},
    "beautyOnboardingStep1Subtitle": "Définissez la composition précise et la porosité de vos cheveux pour personnaliser vos soins botaniques.",
    "@beautyOnboardingStep1Subtitle": {},
    "beautyOnboardingHairCompositionLabel": "Composition & Texture Capillaire",
    "@beautyOnboardingHairCompositionLabel": {},
    "beautyOnboardingHairType4c": "4C — Crépu Très Serré (Trame en Z, Shrinkage fort)",
    "@beautyOnboardingHairType4c": {},
    "beautyOnboardingHairType4b": "4B — Crépu Zigzag en Z (Boucles en Z définies)",
    "@beautyOnboardingHairType4b": {},
    "beautyOnboardingHairType4a": "4A — Crépu Spirales en S (Spirales denses)",
    "@beautyOnboardingHairType4a": {},
    "beautyOnboardingHairType3c": "3C — Boucles Frisées Denses (Spirales serrées)",
    "@beautyOnboardingHairType3c": {},
    "beautyOnboardingHairType3b": "3B — Boucles Serrées en Tire-bouchon",
    "@beautyOnboardingHairType3b": {},
    "beautyOnboardingHairType3a": "3A — Boucles Amples Souples",
    "@beautyOnboardingHairType3a": {},
    "beautyOnboardingHairType2c": "2C — Ondulations Épaisses",
    "@beautyOnboardingHairType2c": {},
    "beautyOnboardingHairType2b": "2B — Ondulations Définies",
    "@beautyOnboardingHairType2b": {},
    "beautyOnboardingHairType2a": "2A — Ondulations Légères",
    "@beautyOnboardingHairType2a": {},
    "beautyOnboardingHairType1c": "1C — Cheveux Lisses Épais",
    "@beautyOnboardingHairType1c": {},
    "beautyOnboardingHairType1b": "1B — Cheveux Lisses Moyens",
    "@beautyOnboardingHairType1b": {},
    "beautyOnboardingHairType1a": "1A — Cheveux Lisses Très Fins",
    "@beautyOnboardingHairType1a": {},
    "beautyOnboardingHairTypeLocks": "Locks / Dreadlocks (Verrouillés)",
    "@beautyOnboardingHairTypeLocks": {},
    "beautyOnboardingHairTypeTransition": "Cheveux en Transition (Post-Défrisage)",
    "@beautyOnboardingHairTypeTransition": {},
    "beautyOnboardingHairTypeProtective": "Soin Sous Tresses / Perruque",
    "@beautyOnboardingHairTypeProtective": {},
    "beautyOnboardingPorosityLabel": "Porosité des Cheveux",
    "@beautyOnboardingPorosityLabel": {},
    "beautyOnboardingPorosityLow": "Faible (Écailles fermées)",
    "@beautyOnboardingPorosityLow": {},
    "beautyOnboardingPorosityMedium": "Moyenne (Équilibre parfait)",
    "@beautyOnboardingPorosityMedium": {},
    "beautyOnboardingPorosityHigh": "Fortement Poreuse (Écailles ouvertes)",
    "@beautyOnboardingPorosityHigh": {},
    "beautyOnboardingScalpLabel": "État du Cuir Chevelu",
    "@beautyOnboardingScalpLabel": {},
    "beautyOnboardingScalpNormal": "Normal / Équilibré",
    "@beautyOnboardingScalpNormal": {},
    "beautyOnboardingScalpDry": "Sec & Démangeaisons",
    "@beautyOnboardingScalpDry": {},
    "beautyOnboardingScalpOily": "Gras / Pellicules",
    "@beautyOnboardingScalpOily": {},
    "beautyOnboardingScalpSensitive": "Sensible / Irrité",
    "@beautyOnboardingScalpSensitive": {},
    "beautyOnboardingStep2Title": "✨ Diagnostic Cutané Profond",
    "@beautyOnboardingStep2Title": {},
    "beautyOnboardingStep2Subtitle": "Analysez la typologie globale et les défis spécifiques de votre peau (visage & corps).",
    "@beautyOnboardingStep2Subtitle": {},
    "beautyOnboardingSkinTypeLabel": "Composition & Typologie Cutanée",
    "@beautyOnboardingSkinTypeLabel": {},
    "beautyOnboardingSkinTypeMixte": "Peau Mixte (Zone T brillante, joues normales/sèches)",
    "@beautyOnboardingSkinTypeMixte": {},
    "beautyOnboardingSkinTypeSeche": "Peau Sèche & Déshydratée (Tiraillements & desquamation)",
    "@beautyOnboardingSkinTypeSeche": {},
    "beautyOnboardingSkinTypeGrasse": "Peau Grasse & Acnéique (Excès de sébum, pores dilatés)",
    "@beautyOnboardingSkinTypeGrasse": {},
    "beautyOnboardingSkinTypeSensible": "Peau Sensible & Réactive (Rougeurs, rosacée)",
    "@beautyOnboardingSkinTypeSensible": {},
    "beautyOnboardingSkinTypeHyperpigmentation": "Peau Sujette à l'Hyperpigmentation (Taches sombres, mélasma)",
    "@beautyOnboardingSkinTypeHyperpigmentation": {},
    "beautyOnboardingSkinTypeMature": "Peau Mature (Perte de fermeté & rides d'expression)",
    "@beautyOnboardingSkinTypeMature": {},
    "beautyOnboardingSkinTypeNormale": "Peau Normale / Équilibrée",
    "@beautyOnboardingSkinTypeNormale": {},
    "beautyOnboardingSkinConcernsLabel": "Préoccupations Cutanées (Visage & Décolleté)",
    "@beautyOnboardingSkinConcernsLabel": {},
    "beautyOnboardingConcernHyperpigmentation": "🌖 Taches Sombres & Teint Irrégulier",
    "@beautyOnboardingConcernHyperpigmentation": {},
    "beautyOnboardingConcernAcne": "🌋 Boutons & Imperfections",
    "@beautyOnboardingConcernAcne": {},
    "beautyOnboardingConcernDehydration": "💧 Déshydratation Profonde & Perte d'Éclat",
    "@beautyOnboardingConcernDehydration": {},
    "beautyOnboardingConcernBarrier": "🛡️ Barrière Cutanée Fragilisée & Sensibilité",
    "@beautyOnboardingConcernBarrier": {},
    "beautyOnboardingConcernSebum": "✨ Brillance Excessive & Pores Dilatés",
    "@beautyOnboardingConcernSebum": {},
    "beautyOnboardingConcernAging": "🌿 Perte d'Élasticité & Rides d'Expression",
    "@beautyOnboardingConcernAging": {},
    "beautyOnboardingBodyProfileLabel": "Particularités du Corps",
    "@beautyOnboardingBodyProfileLabel": {},
    "beautyOnboardingBodyNormal": "Normal / Sans Problème",
    "@beautyOnboardingBodyNormal": {},
    "beautyOnboardingBodyKeratose": "Kératose Pilaire (Peau de poule)",
    "@beautyOnboardingBodyKeratose": {},
    "beautyOnboardingBodyEczema": "Eczéma / Sujet aux Poussées",
    "@beautyOnboardingBodyEczema": {},
    "beautyOnboardingBodyVergetures": "Prévention Vergetures",
    "@beautyOnboardingBodyVergetures": {},
    "beautyOnboardingBodyDrySkin": "Peau du Corps Très Sèche (Crocodile)",
    "@beautyOnboardingBodyDrySkin": {},
    "beautyOnboardingStep3Title": "🌱 Objectifs Beauté & Priorités",
    "@beautyOnboardingStep3Title": {},
    "beautyOnboardingStep3Subtitle": "Sélectionnez vos priorités capillaires et cutanées pour calibrer votre routine sur 30 jours.",
    "@beautyOnboardingStep3Subtitle": {},
    "beautyOnboardingHairGoalsLabel": "Objectifs Capillaires 👑",
    "@beautyOnboardingHairGoalsLabel": {},
    "beautyOnboardingGoalHairGrowth": "🌱 Pousse, Densité & Longueur",
    "@beautyOnboardingGoalHairGrowth": {},
    "beautyOnboardingGoalAntiBreakage": "🛡️ Force, Retention & Anti-Casse",
    "@beautyOnboardingGoalAntiBreakage": {},
    "beautyOnboardingGoalHairMoisture": "💧 Hydratation Profonde & Définition",
    "@beautyOnboardingGoalHairMoisture": {},
    "beautyOnboardingGoalScalpSoothing": "💆 Équilibre & Apaisement du Cuir Chevelu",
    "@beautyOnboardingGoalScalpSoothing": {},
    "beautyOnboardingSkinGoalsLabel": "Objectifs Cutanés & Teint ✨",
    "@beautyOnboardingSkinGoalsLabel": {},
    "beautyOnboardingGoalSkinGlow": "✨ Éclat du Teint & Teint Uniforme",
    "@beautyOnboardingGoalSkinGlow": {},
    "beautyOnboardingGoalAntiSpot": "🌖 Atténuation des Taches & Hyperpigmentation",
    "@beautyOnboardingGoalAntiSpot": {},
    "beautyOnboardingGoalSkinMoisture": "💧 Hydratation & Souplesse Cutanée",
    "@beautyOnboardingGoalSkinMoisture": {},
    "beautyOnboardingGoalAntiImperfection": "🌋 Clarification & Anti-Imperfections",
    "@beautyOnboardingGoalAntiImperfection": {},
    "beautyOnboardingGoalSkinBarrier": "🛡️ Renforcement de la Barrière Cutanée",
    "@beautyOnboardingGoalSkinBarrier": {},
    "beautyOnboardingStep4Title": "📊 Premier Bilan Initial (First Beauty Log)",
    "@beautyOnboardingStep4Title": {},
    "beautyOnboardingStep4Subtitle": "Saisissez vos mesures et observations de départ. Ce premier journal servira de point de référence pour mesurer vos progrès au fil des 30 jours.",
    "@beautyOnboardingStep4Subtitle": {},
    "beautyOnboardingHairLengthLabel": "📏 Longueur Actuelle des Cheveux",
    "@beautyOnboardingHairLengthLabel": {},
    "beautyOnboardingValueCm": "{value} cm",
    "@beautyOnboardingValueCm": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyOnboardingHairStrengthLabel": "💪 Force & Résistance Capillaire",
    "@beautyOnboardingHairStrengthLabel": {},
    "beautyOnboardingValueOutOfTen": "{value}/10",
    "@beautyOnboardingValueOutOfTen": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyOnboardingSheddingRateLabel": "📊 Taux de Chute Actuel",
    "@beautyOnboardingSheddingRateLabel": {},
    "beautyOnboardingSheddingLow": "Faible",
    "@beautyOnboardingSheddingLow": {},
    "beautyOnboardingSheddingModerate": "Modéré",
    "@beautyOnboardingSheddingModerate": {},
    "beautyOnboardingSheddingHigh": "Élevé",
    "@beautyOnboardingSheddingHigh": {},
    "beautyOnboardingSkinHydrationLabel": "💧 Niveau d'Hydratation de la Peau",
    "@beautyOnboardingSkinHydrationLabel": {},
    "beautyOnboardingSkinClarityLabel": "✨ Éclat & Clarté du Teint",
    "@beautyOnboardingSkinClarityLabel": {},
    "beautyOnboardingNotesLabel": "📝 Notes Initiales & Observations",
    "@beautyOnboardingNotesLabel": {},
    "beautyOnboardingNotesHint": "Notes sur l'état de vos cheveux et de votre peau...",
    "@beautyOnboardingNotesHint": {},
    "beautyOnboardingDefaultNotes": "Bilan initial du profil beauté",
    "@beautyOnboardingDefaultNotes": {},
    "beautyOnboardingSummaryTitle": "📋 Résumé & Confirmation",
    "@beautyOnboardingSummaryTitle": {},
    "beautyOnboardingSummarySubtitle": "Vérifiez la synthèse de votre profil beauté avant d'activer votre programme personnalisé 30 jours.",
    "@beautyOnboardingSummarySubtitle": {},
    "beautyOnboardingSummaryHairCardTitle": "👑 Profil Capillaire",
    "@beautyOnboardingSummaryHairCardTitle": {},
    "beautyOnboardingSummaryHairTypeRow": "Texture / Type:",
    "@beautyOnboardingSummaryHairTypeRow": {},
    "beautyOnboardingSummaryPorosityRow": "Porosité:",
    "@beautyOnboardingSummaryPorosityRow": {},
    "beautyOnboardingSummaryPorosityLowValue": "Faible",
    "@beautyOnboardingSummaryPorosityLowValue": {},
    "beautyOnboardingSummaryPorosityHighValue": "Poreuse",
    "@beautyOnboardingSummaryPorosityHighValue": {},
    "beautyOnboardingSummaryPorosityMediumValue": "Moyenne",
    "@beautyOnboardingSummaryPorosityMediumValue": {},
    "beautyOnboardingSummaryScalpRow": "Cuir Chevelu:",
    "@beautyOnboardingSummaryScalpRow": {},
    "beautyOnboardingSummaryScalpDryValue": "Sec",
    "@beautyOnboardingSummaryScalpDryValue": {},
    "beautyOnboardingSummaryScalpOilyValue": "Gras",
    "@beautyOnboardingSummaryScalpOilyValue": {},
    "beautyOnboardingSummaryScalpSensitiveValue": "Sensible",
    "@beautyOnboardingSummaryScalpSensitiveValue": {},
    "beautyOnboardingSummaryScalpNormalValue": "Normal",
    "@beautyOnboardingSummaryScalpNormalValue": {},
    "beautyOnboardingSummarySkinCardTitle": "✨ Diagnostic Cutané",
    "@beautyOnboardingSummarySkinCardTitle": {},
    "beautyOnboardingSummarySkinTypeRow": "Typologie:",
    "@beautyOnboardingSummarySkinTypeRow": {},
    "beautyOnboardingSummaryConcernsRow": "Préoccupations:",
    "@beautyOnboardingSummaryConcernsRow": {},
    "beautyOnboardingSummaryConcernsNone": "Aucune",
    "@beautyOnboardingSummaryConcernsNone": {},
    "beautyOnboardingSummaryBodyProfileRow": "Particularité Corps:",
    "@beautyOnboardingSummaryBodyProfileRow": {},
    "beautyOnboardingSummaryGoalsCardTitle": "🌱 Objectifs Sélectionnés",
    "@beautyOnboardingSummaryGoalsCardTitle": {},
    "beautyOnboardingSummaryFirstLogCardTitle": "📊 Mesures du Premier Bilan",
    "@beautyOnboardingSummaryFirstLogCardTitle": {},
    "beautyOnboardingSummaryHairLengthRow": "Longueur Cheveux:",
    "@beautyOnboardingSummaryHairLengthRow": {},
    "beautyOnboardingSummaryHairStrengthRow": "Force Capillaire:",
    "@beautyOnboardingSummaryHairStrengthRow": {},
    "beautyOnboardingSummarySheddingRow": "Taux de Chute:",
    "@beautyOnboardingSummarySheddingRow": {},
    "beautyOnboardingSummarySkinHydrationRow": "Hydratation Peau:",
    "@beautyOnboardingSummarySkinHydrationRow": {},
    "beautyOnboardingSummaryClarityRow": "Éclat Teint:",
    "@beautyOnboardingSummaryClarityRow": {},
    "beautyOnboardingSummaryNotesRow": "Notes:",
    "@beautyOnboardingSummaryNotesRow": {},
    "beautyOnboardingSummaryEditTooltip": "Modifier",
    "@beautyOnboardingSummaryEditTooltip": {},
    "beautyOnboardingSaveErrorSnackbar": "Erreur lors de la sauvegarde: {error}",
    "@beautyOnboardingSaveErrorSnackbar": {
      "placeholders": { "error": { "type": "String" } }
    },

    "beautyCheckinTitle": "Bilan Beauté & Évolution",
    "@beautyCheckinTitle": {},
    "beautyCheckinSubtitle": "Enregistrez votre bilan mensuel de longueur de cheveux et de barrière cutanée.",
    "@beautyCheckinSubtitle": {},
    "beautyCheckinHairLengthLabel": "Longueur des Cheveux : {value} cm",
    "@beautyCheckinHairLengthLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinHairStrengthLabel": "Score de Force Capillaire : {value} / 10",
    "@beautyCheckinHairStrengthLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinHairThicknessLabel": "Score d'Épaisseur Capillaire : {value} / 10",
    "@beautyCheckinHairThicknessLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinSkinHydrationLabel": "Niveau d'Hydratation de la Peau : {value} / 10",
    "@beautyCheckinSkinHydrationLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinSkinClarityLabel": "Score de Clarté de la Peau : {value} / 10",
    "@beautyCheckinSkinClarityLabel": {
      "placeholders": { "value": { "type": "String" } }
    },
    "beautyCheckinNotesLabel": "Notes du Journal de Bilan (Optionnel)",
    "@beautyCheckinNotesLabel": {},
    "beautyCheckinNotesHint": "ex. Cheveux nettement plus doux après un masque au Chébé !",
    "@beautyCheckinNotesHint": {},
    "beautyCheckinSaveButton": "Enregistrer le Bilan",
    "@beautyCheckinSaveButton": {},
    "beautyCheckinSheddingLabel": "Taux de Chute des Cheveux",
    "@beautyCheckinSheddingLabel": {},
    "beautyCheckinSheddingLow": "Faible",
    "@beautyCheckinSheddingLow": {},
    "beautyCheckinSheddingModerate": "Modéré",
    "@beautyCheckinSheddingModerate": {},
    "beautyCheckinSheddingHigh": "Élevé",
    "@beautyCheckinSheddingHigh": {},

    "todayBeautyRoutinesTitle": "Vos Rituels du Jour 👑",
    "@todayBeautyRoutinesTitle": {},
    "todayBeautyRoutinesPlanningLink": "Planning (30j)",
    "@todayBeautyRoutinesPlanningLink": {},
    "todayBeautyRoutinesEmptyTitle": "Aucun rituel aujourd'hui",
    "@todayBeautyRoutinesEmptyTitle": {},
    "todayBeautyRoutinesEmptySubtitle": "Générez votre planning mensuel dans l'onglet Routine.",
    "@todayBeautyRoutinesEmptySubtitle": {},
    "todayBeautyRoutinesRestDay": "Journée de repos pour votre cuir chevelu & peau !",
    "@todayBeautyRoutinesRestDay": {},
    "todayBeautyRoutinesLoadError": "Erreur lors du chargement des rituels : {error}",
    "@todayBeautyRoutinesLoadError": {
      "placeholders": { "error": { "type": "String" } }
    },
    "todayBeautyRoutinesTierLabel": "Tier: {tier}",
    "@todayBeautyRoutinesTierLabel": {
      "placeholders": { "tier": { "type": "String" } }
    },
    "todayBeautyRoutinesDefaultLabel": "Rituel",
    "@todayBeautyRoutinesDefaultLabel": {},

    "beautyPlannerLoadError": "Erreur lors du chargement du plan de soin: {error}",
    "@beautyPlannerLoadError": {
      "placeholders": { "error": { "type": "String" } }
    },
    "beautyPlannerHeaderTitle": "Mon Plan de Soins Mensuel",
    "@beautyPlannerHeaderTitle": {},
    "beautyPlannerHeaderSubtitle": "Routines personnalisées de soins capillaires & cutanés (30 jours).",
    "@beautyPlannerHeaderSubtitle": {},
    "beautyPlannerDailySectionTitle": "💧 Soins Quotidiens (Hydratation)",
    "@beautyPlannerDailySectionTitle": {},
    "beautyPlannerWeeklySectionTitle": "🌿 Soins Hebdomadaires (Masques & Bains)",
    "@beautyPlannerWeeklySectionTitle": {},
    "beautyPlannerMonthlySectionTitle": "✨ Soins Mensuels & Proteine",
    "@beautyPlannerMonthlySectionTitle": {},
    "beautyPlannerSectionCount": "{count, plural, one{{count} soin} other{{count} soins}}",
    "@beautyPlannerSectionCount": {
      "placeholders": { "count": { "type": "int" } }
    },
    "beautyPlannerDayLabel": "Jour {day}",
    "@beautyPlannerDayLabel": {
      "placeholders": { "day": { "type": "String" } }
    },
    "beautyPlannerEmptyTitle": "Aucun Plan de Soin Actif",
    "@beautyPlannerEmptyTitle": {},
    "beautyPlannerEmptySubtitle": "Générez votre routine mensuelle de soins capillaires et cutanés adaptée à votre profil.",
    "@beautyPlannerEmptySubtitle": {},
    "beautyPlannerGenerateButton": "Générer Mon Plan Beauté",
    "@beautyPlannerGenerateButton": {},

    "colorSetModalTitle": "Personnaliser le Thème de Couleurs",
    "@colorSetModalTitle": {},
    "colorSetModalSubtitle": "Sélectionnez une palette de couleurs Primaire & Secondaire.",
    "@colorSetModalSubtitle": {},
    "colorSetModalPresetTealName": "Teal & Amber (Nutrition)",
    "@colorSetModalPresetTealName": {},
    "colorSetModalPresetTealDesc": "Équilibré, sain et énergisant.",
    "@colorSetModalPresetTealDesc": {},
    "colorSetModalPresetRoseName": "Rose & Gold (Beauty)",
    "@colorSetModalPresetRoseName": {},
    "colorSetModalPresetRoseDesc": "Luxe éditorial, soin bio & éclat.",
    "@colorSetModalPresetRoseDesc": {},
    "colorSetModalPresetSageName": "Sage & Bronze (Botanique)",
    "@colorSetModalPresetSageName": {},
    "colorSetModalPresetSageDesc": "Plantes ancestrales & nature.",
    "@colorSetModalPresetSageDesc": {},
    "colorSetModalPresetTerracottaName": "Terracotta & Clay (Soleil)",
    "@colorSetModalPresetTerracottaName": {},
    "colorSetModalPresetTerracottaDesc": "Tonalité terre d'Afrique & chaleur.",
    "@colorSetModalPresetTerracottaDesc": {},
    "colorSetModalApplyButton": "Appliquer cette Palette",
    "@colorSetModalApplyButton": {}
  }
  ```

  **Important:** the FR block above repeats `"onboardingValidationAgeMax"` only to show where to splice — do not duplicate that key; it already exists earlier in the file. Only the lines below it (`"beautyAnalyticsTitle"` onward) are new insertions.

- [ ] **Step 3: Regenerate localizations.**

  ```
  flutter gen-l10n
  ```

  Expected output: no errors, silent success (exit code 0). If a duplicate-key or malformed-JSON error appears, re-check that Steps 1-2 only added new keys and did not touch or duplicate any existing key.

- [ ] **Step 4: Replace hardcoded strings in `lib/features/beauty/beauty_analytics_page.dart`.**

  Replace the entire file with (on top of Task 4's version — adds the `AppLocalizations` import, `final l10n = AppLocalizations.of(context);` at the top of `build()`, and threads `l10n` into every private builder via the `context` each already has access to as a `State` member):

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../../core/logger.dart';
  import '../../core/theme.dart';
  import '../../l10n/app_localizations.dart';
  import '../../providers/auth_provider.dart';
  import '../../providers/beauty_plan_provider.dart';
  import '../../shared/models/beauty_log.dart';
  import '../../shared/models/beauty_plan.dart';
  import 'widgets/beauty_checkin_sheet.dart';

  class BeautyAnalyticsPage extends ConsumerStatefulWidget {
    const BeautyAnalyticsPage({super.key});

    @override
    ConsumerState<BeautyAnalyticsPage> createState() => _BeautyAnalyticsPageState();
  }

  class _BeautyAnalyticsPageState extends ConsumerState<BeautyAnalyticsPage> {
    static const _timeframeIds = ['7d', '30d', '90d', 'all'];
    String _selectedTimeframeId = '30d';

    static const Color _rosewood = Color(0xFF8A3B58);
    static const Color _gold = Color(0xFFD4AF37);
    static const Color _darkCardBg = Color(0xFF231821);

    final _logger = appLogger;

    String _timeframeLabel(AppLocalizations l10n, String id) {
      switch (id) {
        case '7d':
          return l10n.beautyAnalyticsTimeframe7d;
        case '30d':
          return l10n.beautyAnalyticsTimeframe30d;
        case '90d':
          return l10n.beautyAnalyticsTimeframe90d;
        case 'all':
        default:
          return l10n.beautyAnalyticsTimeframeAll;
      }
    }

    /// Earliest `loggedAt` still included for [id], or `null` for "Tout"
    /// (no filtering).
    DateTime? _cutoffFor(String id) {
      final now = DateTime.now();
      switch (id) {
        case '7d':
          return now.subtract(const Duration(days: 7));
        case '30d':
          return now.subtract(const Duration(days: 30));
        case '90d':
          return now.subtract(const Duration(days: 90));
        case 'all':
        default:
          return null;
      }
    }

    List<BeautyLog> _filterLogsByTimeframe(List<BeautyLog> logs) {
      final cutoff = _cutoffFor(_selectedTimeframeId);
      if (cutoff == null) return logs;
      return logs.where((log) => log.loggedAt.isAfter(cutoff)).toList();
    }

    @override
    Widget build(BuildContext context) {
      _logger.provider('BeautyAnalyticsPage build()');
      final l10n = AppLocalizations.of(context);
      final activePlanAsync = ref.watch(activeBeautyPlanProvider);
      final beautyLogsAsync = ref.watch(beautyLogsProvider);

      return Scaffold(
        backgroundColor: const Color(0xFF140D13),
        appBar: AppBar(
          backgroundColor: const Color(0xFF140D13),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            l10n.beautyAnalyticsTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined, color: _gold, size: 22),
              tooltip: l10n.beautyAnalyticsNewCheckinTooltip,
              onPressed: () => _openCheckinSheet(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: _rosewood,
          backgroundColor: const Color(0xFF231821),
          onRefresh: () async {
            ref.invalidate(activeBeautyPlanProvider);
            ref.invalidate(beautyLogsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildEditorialHeader(l10n),
              const SizedBox(height: 16),
              _buildTimeframeFilterPills(l10n),
              const SizedBox(height: 20),

              activePlanAsync.when(
                data: (plan) => _buildAdherenceCard(l10n, plan),
                loading: () => const Center(child: CircularProgressIndicator(color: _rosewood)),
                error: (_, __) => _buildAdherenceCard(l10n, null),
              ),
              const SizedBox(height: 24),

              beautyLogsAsync.when(
                data: (logs) {
                  final filteredLogs = _filterLogsByTimeframe(logs);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHairProgressionSection(l10n, filteredLogs),
                      const SizedBox(height: 24),
                      _buildSkinProgressionSection(l10n, filteredLogs),
                      const SizedBox(height: 28),
                      _buildLogsHistoryTimeline(l10n, filteredLogs),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: _rosewood)),
                error: (err, _) => Center(
                  child: Text(
                    l10n.beautyAnalyticsLoadError(err.toString()),
                    style: GoogleFonts.nunito(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openCheckinSheet(context),
          backgroundColor: _rosewood,
          elevation: 6,
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
          label: Text(
            l10n.beautyAnalyticsNewCheckinFab,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    void _openCheckinSheet(BuildContext context) async {
      _logger.userAction('Check-in FAB tapped', screen: 'BeautyAnalyticsPage');
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _logger.auth('Check-in aborted | no authenticated user');
        return;
      }

      final checkinData = await BeautyCheckinSheet.show(
        context,
        userId: user.id,
      );

      if (checkinData != null) {
        _logger.db('BEFORE | table: beauty_log | op: INSERT via addLog | userId: ${LogHelper.maskUuid(user.id)}');
        try {
          await ref.read(addBeautyLogNotifierProvider.notifier).addLog(
                hairLengthCm: (checkinData['hairLengthCm'] as num?)?.toDouble() ?? 15.0,
                hairStrengthScore: (checkinData['hairStrengthScore'] as num?)?.toDouble() ?? 7.0,
                hairThicknessScore: (checkinData['hairThicknessScore'] as num?)?.toDouble() ?? 7.0,
                hairSheddingRate: checkinData['hairSheddingRate'] as String? ?? 'moderate',
                skinHydrationLevel: (checkinData['skinHydrationLevel'] as num?)?.toDouble() ?? 7.0,
                skinClarityScore: (checkinData['skinClarityScore'] as num?)?.toDouble() ?? 7.0,
                checkinNotes: checkinData['checkinNotes'] as String?,
              );
          _logger.db('AFTER | table: beauty_log | op: INSERT via addLog | success');
        } catch (e, st) {
          _logger.db('ERROR | addLog via BeautyAnalyticsPage | $e', error: e, stackTrace: st);
        }
      } else {
        _logger.userAction('Check-in sheet dismissed without save', screen: 'BeautyAnalyticsPage');
      }
    }

    Widget _buildEditorialHeader(AppLocalizations l10n) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rosewood.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _rosewood.withOpacity(0.5)),
                ),
                child: Text(
                  l10n.beautyAnalyticsHeaderBadge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beautyAnalyticsHeaderTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.beautyAnalyticsHeaderSubtitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    Widget _buildTimeframeFilterPills(AppLocalizations l10n) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _timeframeIds.map((id) {
            final isSelected = _selectedTimeframeId == id;
            final label = _timeframeLabel(l10n, id);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTimeframeId = id);
                  }
                },
                selectedColor: _rosewood,
                backgroundColor: const Color(0xFF231821),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                side: BorderSide(
                  color: isSelected ? _gold : Colors.white10,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget _buildAdherenceCard(AppLocalizations l10n, BeautyPlan? plan) {
      int totalSlots = plan?.slots.length ?? 0;
      int completedSlots = plan?.slots.where((s) => s.isCompleted).length ?? 0;
      double percentage = totalSlots > 0 ? (completedSlots / totalSlots) * 100 : 0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _rosewood.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: _rosewood.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.beautyAnalyticsAdherenceLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.beautyAnalyticsAdherenceFraction(completedSlots.toString(), totalSlots.toString()),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_rosewood, _gold.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalSlots > 0 ? completedSlots / totalSlots : 0,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(_gold),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildHairProgressionSection(AppLocalizations l10n, List<BeautyLog> logs) {
      final latestLog = logs.isNotEmpty ? logs.first : null;
      final initialLog = logs.isNotEmpty ? logs.last : null;

      double currentLength = latestLog?.hairLengthCm ?? 15.0;
      double initialLength = initialLog?.hairLengthCm ?? 15.0;
      double growthDelta = currentLength - initialLength;

      double strengthScore = latestLog?.hairStrengthScore ?? 7.0;
      String sheddingRate = latestLog?.hairSheddingRate ?? 'moderate';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_cut_rounded, color: _gold, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.beautyAnalyticsHairSectionTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: l10n.beautyAnalyticsHairLengthLabel,
                  value: l10n.beautyAnalyticsValueCm(currentLength.toStringAsFixed(1)),
                  subtitle: growthDelta >= 0
                      ? l10n.beautyAnalyticsHairLengthGrowthPositive(growthDelta.toStringAsFixed(1))
                      : l10n.beautyAnalyticsHairLengthGrowthNegative(growthDelta.toStringAsFixed(1)),
                  subtitleColor: growthDelta >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: l10n.beautyAnalyticsHairStrengthLabel,
                  value: l10n.beautyAnalyticsValueOutOfTen(strengthScore.toStringAsFixed(0)),
                  subtitle: l10n.beautyAnalyticsHairStrengthSubtitle,
                  subtitleColor: Colors.white60,
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _darkCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.beautyAnalyticsSheddingLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.87),
                  ),
                ),
                _buildSheddingBadge(l10n, sheddingRate),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildSkinProgressionSection(AppLocalizations l10n, List<BeautyLog> logs) {
      final latestLog = logs.isNotEmpty ? logs.first : null;

      double hydrationLevel = latestLog?.skinHydrationLevel ?? 7.0;
      double clarityScore = latestLog?.skinClarityScore ?? 7.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight_rounded, color: _gold, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.beautyAnalyticsSkinSectionTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: l10n.beautyAnalyticsSkinHydrationLabel,
                  value: l10n.beautyAnalyticsValueOutOfTen(hydrationLevel.toStringAsFixed(0)),
                  subtitle: l10n.beautyAnalyticsSkinHydrationSubtitle,
                  subtitleColor: Colors.cyanAccent,
                  icon: Icons.water_drop_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: l10n.beautyAnalyticsSkinClarityLabel,
                  value: l10n.beautyAnalyticsValueOutOfTen(clarityScore.toStringAsFixed(0)),
                  subtitle: l10n.beautyAnalyticsSkinClaritySubtitle,
                  subtitleColor: _gold,
                  icon: Icons.wb_sunny_rounded,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildMetricTile({
      required String title,
      required String value,
      required String subtitle,
      required Color subtitleColor,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _darkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
                Icon(icon, size: 16, color: _rosewood),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSheddingBadge(AppLocalizations l10n, String rate) {
      String label = l10n.beautyAnalyticsSheddingModerate;
      Color color = Colors.orangeAccent;

      if (rate == 'low' || rate == 'Faible') {
        label = l10n.beautyAnalyticsSheddingLow;
        color = Colors.greenAccent;
      } else if (rate == 'high' || rate == 'Élevée') {
        label = l10n.beautyAnalyticsSheddingHigh;
        color = Colors.redAccent;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    Widget _buildLogsHistoryTimeline(AppLocalizations l10n, List<BeautyLog> logs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.beautyAnalyticsHistoryTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                l10n.beautyAnalyticsHistoryCount(logs.length),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _darkCardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  l10n.beautyAnalyticsHistoryEmpty,
                  style: GoogleFonts.nunito(color: Colors.white60),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                final dateStr = '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _darkCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: _gold),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _rosewood.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.beautyAnalyticsHistoryEntryNumber((logs.length - index).toString()),
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChipTag(l10n.beautyAnalyticsChipLength(log.hairLengthCm.toString())),
                          _buildChipTag(l10n.beautyAnalyticsChipStrength(log.hairStrengthScore.toStringAsFixed(0))),
                          _buildChipTag(l10n.beautyAnalyticsChipHydration(log.skinHydrationLevel.toStringAsFixed(0))),
                          _buildChipTag(l10n.beautyAnalyticsChipClarity(log.skinClarityScore.toStringAsFixed(0))),
                        ],
                      ),
                      if (log.checkinNotes != null && log.checkinNotes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          log.checkinNotes!,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      );
    }

    Widget _buildChipTag(String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.white.withOpacity(0.87),
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 5: Update `test/features/beauty/beauty_analytics_page_test.dart` to wrap `MaterialApp` with l10n delegates.**

  Add the import `import 'package:akeli/l10n/app_localizations.dart';` at the top, and change each of the 3 tests' `MaterialApp(...)` from:

  ```dart
          child: const MaterialApp(
            home: BeautyAnalyticsPage(),
          ),
  ```

  to:

  ```dart
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: BeautyAnalyticsPage(),
          ),
  ```

  (all string assertions in this test file stay unchanged — they match the French ARB values exactly, which are identical to the original hardcoded French text).

  Run:

  ```
  flutter test test/features/beauty/beauty_analytics_page_test.dart
  ```

  Expected output:

  ```
  00:03 +3: All tests passed!
  ```

- [ ] **Step 6: Replace hardcoded strings in `lib/features/beauty/beauty_onboarding_page.dart`.**

  This file already has `_logger = appLogger` wired in (Task 4 does not touch it). Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../core/logger.dart';
  import '../../core/router.dart';
  import '../../core/theme.dart';
  import '../../l10n/app_localizations.dart';
  import '../../providers/user_profile_provider.dart';

  class BeautyOnboardingPage extends ConsumerStatefulWidget {
    const BeautyOnboardingPage({super.key});

    // Beauty Mode Color Set (Rosewood Rose Gold Editorial — matches ColorSetModal)
    static const beautyPrimary = Color(0xFF8A3B58);
    static const beautySecondary = Color(0xFFD4AF37);
    static const beautyBackground = Color(0xFFFAF6F0);
    static const beautySurfaceHigh = Color(0xFFF3EAE1);

    @override
    ConsumerState<BeautyOnboardingPage> createState() => _BeautyOnboardingPageState();
  }

  class _BeautyOnboardingPageState extends ConsumerState<BeautyOnboardingPage> {
    final _logger = appLogger;
    int _currentStep = 0;
    bool _submitting = false;

    // Step 1: Hair & Scalp
    String _hairType = '4C';
    String _porosity = 'medium';
    String _scalpType = 'normal';

    // Step 2: Deep Skin Profile
    String _skinType = 'mixte_t';
    final Set<String> _skinConcerns = {'hyperpigmentation', 'dehydration'};
    String _bodySkinProfile = 'normal';

    // Step 3: Balanced Hair & Skin Goals
    final Set<String> _beautyGoals = {'hair_growth', 'hair_moisture', 'skin_glow', 'skin_moisture'};

    // Step 4: First Beauty Log Check-in Baseline
    double _hairLengthCm = 15.0;
    double _hairStrengthScore = 7.0;
    double _hairThicknessScore = 7.0;
    String _hairSheddingRate = 'moderate';
    double _skinHydrationLevel = 7.0;
    double _skinClarityScore = 7.0;
    late final TextEditingController _notesCtrl;

    @override
    void initState() {
      super.initState();
      // Default notes text is set in didChangeDependencies once l10n is
      // available (AppLocalizations.of(context) cannot be called from
      // initState).
      _notesCtrl = TextEditingController();
    }

    bool _defaultNotesApplied = false;

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      if (!_defaultNotesApplied) {
        _notesCtrl.text = AppLocalizations.of(context).beautyOnboardingDefaultNotes;
        _defaultNotesApplied = true;
      }
    }

    @override
    void dispose() {
      _notesCtrl.dispose();
      super.dispose();
    }

    String _porositySummaryValue(AppLocalizations l10n) {
      switch (_porosity) {
        case 'low':
          return l10n.beautyOnboardingSummaryPorosityLowValue;
        case 'high':
          return l10n.beautyOnboardingSummaryPorosityHighValue;
        default:
          return l10n.beautyOnboardingSummaryPorosityMediumValue;
      }
    }

    String _scalpSummaryValue(AppLocalizations l10n) {
      switch (_scalpType) {
        case 'dry':
          return l10n.beautyOnboardingSummaryScalpDryValue;
        case 'oily':
          return l10n.beautyOnboardingSummaryScalpOilyValue;
        case 'sensitive':
          return l10n.beautyOnboardingSummaryScalpSensitiveValue;
        default:
          return l10n.beautyOnboardingSummaryScalpNormalValue;
      }
    }

    String _sheddingRateLabel(AppLocalizations l10n, String rate) {
      switch (rate) {
        case 'low':
          return l10n.beautyOnboardingSheddingLow;
        case 'high':
          return l10n.beautyOnboardingSheddingHigh;
        default:
          return l10n.beautyOnboardingSheddingModerate;
      }
    }

    @override
    Widget build(BuildContext context) {
      _logger.provider('BeautyOnboardingPage build() | step: $_currentStep');
      final l10n = AppLocalizations.of(context);

      return Scaffold(
        backgroundColor: BeautyOnboardingPage.beautyBackground,
        appBar: AppBar(
          title: Text(
            l10n.beautyOnboardingTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Plus Jakarta Sans',
              color: BeautyOnboardingPage.beautyPrimary,
            ),
          ),
          backgroundColor: BeautyOnboardingPage.beautyBackground,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: BeautyOnboardingPage.beautyPrimary),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: List.generate(5, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isActive
                              ? BeautyOnboardingPage.beautyPrimary
                              : BeautyOnboardingPage.beautySurfaceHigh,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(l10n),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      OutlinedButton(
                        onPressed: _submitting ? null : () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BeautyOnboardingPage.beautyPrimary,
                          side: const BorderSide(color: BeautyOnboardingPage.beautyPrimary, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.beautyOnboardingBackButton),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _handleNextOrSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: BeautyOnboardingPage.beautyPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _currentStep == 4 ? l10n.beautyOnboardingSubmitButton : l10n.beautyOnboardingNextButton,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildStepContent(AppLocalizations l10n) {
      switch (_currentStep) {
        case 0:
          return _buildStep1Hair(l10n);
        case 1:
          return _buildStep2Skin(l10n);
        case 2:
          return _buildStep3Goals(l10n);
        case 3:
          return _buildStep4FirstLog(l10n);
        case 4:
          return _buildStep5Summary(l10n);
        default:
          return const SizedBox.shrink();
      }
    }

    Widget _buildStep1Hair(AppLocalizations l10n) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beautyOnboardingStep1Title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BeautyOnboardingPage.beautyPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beautyOnboardingStep1Subtitle,
            style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.beautyOnboardingHairCompositionLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _hairType,
            decoration: InputDecoration(
              filled: true,
              fillColor: BeautyOnboardingPage.beautySurfaceHigh,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BeautyOnboardingPage.beautyPrimary, width: 2),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: BeautyOnboardingPage.beautyPrimary),
            dropdownColor: Colors.white,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: '4C', child: Text(l10n.beautyOnboardingHairType4c)),
              DropdownMenuItem(value: '4B', child: Text(l10n.beautyOnboardingHairType4b)),
              DropdownMenuItem(value: '4A', child: Text(l10n.beautyOnboardingHairType4a)),
              DropdownMenuItem(value: '3C', child: Text(l10n.beautyOnboardingHairType3c)),
              DropdownMenuItem(value: '3B', child: Text(l10n.beautyOnboardingHairType3b)),
              DropdownMenuItem(value: '3A', child: Text(l10n.beautyOnboardingHairType3a)),
              DropdownMenuItem(value: '2C', child: Text(l10n.beautyOnboardingHairType2c)),
              DropdownMenuItem(value: '2B', child: Text(l10n.beautyOnboardingHairType2b)),
              DropdownMenuItem(value: '2A', child: Text(l10n.beautyOnboardingHairType2a)),
              DropdownMenuItem(value: '1C', child: Text(l10n.beautyOnboardingHairType1c)),
              DropdownMenuItem(value: '1B', child: Text(l10n.beautyOnboardingHairType1b)),
              DropdownMenuItem(value: '1A', child: Text(l10n.beautyOnboardingHairType1a)),
              DropdownMenuItem(value: 'Locks', child: Text(l10n.beautyOnboardingHairTypeLocks)),
              DropdownMenuItem(value: 'Transition', child: Text(l10n.beautyOnboardingHairTypeTransition)),
              DropdownMenuItem(value: 'Protective', child: Text(l10n.beautyOnboardingHairTypeProtective)),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _hairType = val);
            },
          ),
          const SizedBox(height: 28),
          Text(
            l10n.beautyOnboardingPorosityLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSelectableChip(l10n.beautyOnboardingPorosityLow, 'low', _porosity, (val) => setState(() => _porosity = val)),
              _buildSelectableChip(l10n.beautyOnboardingPorosityMedium, 'medium', _porosity, (val) => setState(() => _porosity = val)),
              _buildSelectableChip(l10n.beautyOnboardingPorosityHigh, 'high', _porosity, (val) => setState(() => _porosity = val)),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.beautyOnboardingScalpLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSelectableChip(l10n.beautyOnboardingScalpNormal, 'normal', _scalpType, (val) => setState(() => _scalpType = val)),
              _buildSelectableChip(l10n.beautyOnboardingScalpDry, 'dry', _scalpType, (val) => setState(() => _scalpType = val)),
              _buildSelectableChip(l10n.beautyOnboardingScalpOily, 'oily', _scalpType, (val) => setState(() => _scalpType = val)),
              _buildSelectableChip(l10n.beautyOnboardingScalpSensitive, 'sensitive', _scalpType, (val) => setState(() => _scalpType = val)),
            ],
          ),
        ],
      );
    }

    Widget _buildStep2Skin(AppLocalizations l10n) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beautyOnboardingStep2Title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BeautyOnboardingPage.beautyPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beautyOnboardingStep2Subtitle,
            style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.beautyOnboardingSkinTypeLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _skinType,
            decoration: InputDecoration(
              filled: true,
              fillColor: BeautyOnboardingPage.beautySurfaceHigh,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BeautyOnboardingPage.beautyPrimary, width: 2),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: BeautyOnboardingPage.beautyPrimary),
            dropdownColor: Colors.white,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'mixte_t', child: Text(l10n.beautyOnboardingSkinTypeMixte)),
              DropdownMenuItem(value: 'seche_deshydratee', child: Text(l10n.beautyOnboardingSkinTypeSeche)),
              DropdownMenuItem(value: 'grasse_acneique', child: Text(l10n.beautyOnboardingSkinTypeGrasse)),
              DropdownMenuItem(value: 'sensible_reactive', child: Text(l10n.beautyOnboardingSkinTypeSensible)),
              DropdownMenuItem(value: 'hypermentee', child: Text(l10n.beautyOnboardingSkinTypeHyperpigmentation)),
              DropdownMenuItem(value: 'mature', child: Text(l10n.beautyOnboardingSkinTypeMature)),
              DropdownMenuItem(value: 'normale', child: Text(l10n.beautyOnboardingSkinTypeNormale)),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _skinType = val);
            },
          ),
          const SizedBox(height: 28),
          Text(
            l10n.beautyOnboardingSkinConcernsLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernHyperpigmentation, 'hyperpigmentation'),
          _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernAcne, 'acne_imperfections'),
          _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernDehydration, 'dehydration'),
          _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernBarrier, 'barrier_damage'),
          _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernSebum, 'excess_sebum'),
          _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernAging, 'aging_elasticity'),
          const SizedBox(height: 28),
          Text(
            l10n.beautyOnboardingBodyProfileLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSelectableChip(l10n.beautyOnboardingBodyNormal, 'normal', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
              _buildSelectableChip(l10n.beautyOnboardingBodyKeratose, 'keratose', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
              _buildSelectableChip(l10n.beautyOnboardingBodyEczema, 'eczema', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
              _buildSelectableChip(l10n.beautyOnboardingBodyVergetures, 'vergetures', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
              _buildSelectableChip(l10n.beautyOnboardingBodyDrySkin, 'corps_sec', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            ],
          ),
        ],
      );
    }

    Widget _buildStep3Goals(AppLocalizations l10n) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beautyOnboardingStep3Title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BeautyOnboardingPage.beautyPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beautyOnboardingStep3Subtitle,
            style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.beautyOnboardingHairGoalsLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalHairGrowth, 'hair_growth'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalAntiBreakage, 'anti_breakage'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalHairMoisture, 'hair_moisture'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalScalpSoothing, 'scalp_soothing'),

          const SizedBox(height: 28),
          Text(
            l10n.beautyOnboardingSkinGoalsLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
          ),
          const SizedBox(height: 12),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalSkinGlow, 'skin_glow'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalAntiSpot, 'skin_anti_spot'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalSkinMoisture, 'skin_moisture'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalAntiImperfection, 'skin_anti_imperfection'),
          _buildGoalCheckbox(l10n.beautyOnboardingGoalSkinBarrier, 'skin_barrier'),
        ],
      );
    }

    Widget _buildStep4FirstLog(AppLocalizations l10n) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beautyOnboardingStep4Title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BeautyOnboardingPage.beautyPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beautyOnboardingStep4Subtitle,
            style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.beautyOnboardingHairLengthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                l10n.beautyOnboardingValueCm(_hairLengthCm.toInt().toString()),
                style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
              ),
            ],
          ),
          Slider(
            value: _hairLengthCm,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            activeColor: BeautyOnboardingPage.beautyPrimary,
            onChanged: (val) => setState(() => _hairLengthCm = val),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.beautyOnboardingHairStrengthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                l10n.beautyOnboardingValueOutOfTen(_hairStrengthScore.toInt().toString()),
                style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
              ),
            ],
          ),
          Slider(
            value: _hairStrengthScore,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            activeColor: BeautyOnboardingPage.beautyPrimary,
            onChanged: (val) => setState(() => _hairStrengthScore = val),
          ),

          const SizedBox(height: 20),
          Text(l10n.beautyOnboardingSheddingRateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _buildSelectableChip(l10n.beautyOnboardingSheddingLow, 'low', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
              _buildSelectableChip(l10n.beautyOnboardingSheddingModerate, 'moderate', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
              _buildSelectableChip(l10n.beautyOnboardingSheddingHigh, 'high', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.beautyOnboardingSkinHydrationLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                l10n.beautyOnboardingValueOutOfTen(_skinHydrationLevel.toInt().toString()),
                style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
              ),
            ],
          ),
          Slider(
            value: _skinHydrationLevel,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            activeColor: BeautyOnboardingPage.beautyPrimary,
            onChanged: (val) => setState(() => _skinHydrationLevel = val),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.beautyOnboardingSkinClarityLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                l10n.beautyOnboardingValueOutOfTen(_skinClarityScore.toInt().toString()),
                style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
              ),
            ],
          ),
          Slider(
            value: _skinClarityScore,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            activeColor: BeautyOnboardingPage.beautyPrimary,
            onChanged: (val) => setState(() => _skinClarityScore = val),
          ),

          const SizedBox(height: 24),
          Text(l10n.beautyOnboardingNotesLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.beautyOnboardingNotesHint,
              filled: true,
              fillColor: BeautyOnboardingPage.beautySurfaceHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      );
    }

    Widget _buildStep5Summary(AppLocalizations l10n) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beautyOnboardingSummaryTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BeautyOnboardingPage.beautyPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beautyOnboardingSummarySubtitle,
            style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
          ),
          const SizedBox(height: 24),

          _buildSummaryCard(
            l10n,
            title: l10n.beautyOnboardingSummaryHairCardTitle,
            onEdit: () => setState(() => _currentStep = 0),
            children: [
              _buildSummaryRow(l10n.beautyOnboardingSummaryHairTypeRow, _hairType),
              _buildSummaryRow(l10n.beautyOnboardingSummaryPorosityRow, _porositySummaryValue(l10n)),
              _buildSummaryRow(l10n.beautyOnboardingSummaryScalpRow, _scalpSummaryValue(l10n)),
            ],
          ),

          const SizedBox(height: 16),
          _buildSummaryCard(
            l10n,
            title: l10n.beautyOnboardingSummarySkinCardTitle,
            onEdit: () => setState(() => _currentStep = 1),
            children: [
              _buildSummaryRow(l10n.beautyOnboardingSummarySkinTypeRow, _skinType.replaceAll('_', ' ').toUpperCase()),
              _buildSummaryRow(
                l10n.beautyOnboardingSummaryConcernsRow,
                _skinConcerns.isEmpty ? l10n.beautyOnboardingSummaryConcernsNone : _skinConcerns.join(', '),
              ),
              _buildSummaryRow(l10n.beautyOnboardingSummaryBodyProfileRow, _bodySkinProfile),
            ],
          ),

          const SizedBox(height: 16),
          _buildSummaryCard(
            l10n,
            title: l10n.beautyOnboardingSummaryGoalsCardTitle,
            onEdit: () => setState(() => _currentStep = 2),
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _beautyGoals.map((g) {
                  return Chip(
                    label: Text(g.replaceAll('_', ' ')),
                    backgroundColor: BeautyOnboardingPage.beautySurfaceHigh,
                    labelStyle: const TextStyle(fontSize: 12, color: BeautyOnboardingPage.beautyPrimary, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildSummaryCard(
            l10n,
            title: l10n.beautyOnboardingSummaryFirstLogCardTitle,
            onEdit: () => setState(() => _currentStep = 3),
            children: [
              _buildSummaryRow(l10n.beautyOnboardingSummaryHairLengthRow, l10n.beautyOnboardingValueCm(_hairLengthCm.toInt().toString())),
              _buildSummaryRow(l10n.beautyOnboardingSummaryHairStrengthRow, l10n.beautyOnboardingValueOutOfTen(_hairStrengthScore.toInt().toString())),
              _buildSummaryRow(l10n.beautyOnboardingSummarySheddingRow, _sheddingRateLabel(l10n, _hairSheddingRate)),
              _buildSummaryRow(l10n.beautyOnboardingSummarySkinHydrationRow, l10n.beautyOnboardingValueOutOfTen(_skinHydrationLevel.toInt().toString())),
              _buildSummaryRow(l10n.beautyOnboardingSummaryClarityRow, l10n.beautyOnboardingValueOutOfTen(_skinClarityScore.toInt().toString())),
              if (_notesCtrl.text.isNotEmpty) _buildSummaryRow(l10n.beautyOnboardingSummaryNotesRow, _notesCtrl.text),
            ],
          ),
        ],
      );
    }

    Widget _buildSummaryCard(
      AppLocalizations l10n, {
      required String title,
      required VoidCallback onEdit,
      required List<Widget> children,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: BeautyOnboardingPage.beautyPrimary),
                  onPressed: onEdit,
                  tooltip: l10n.beautyOnboardingSummaryEditTooltip,
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      );
    }

    Widget _buildSummaryRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSelectableChip(String label, String value, String currentValue, ValueChanged<String> onSelect) {
      final isSelected = currentValue == value;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: BeautyOnboardingPage.beautyPrimary,
        backgroundColor: BeautyOnboardingPage.beautySurfaceHigh,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AkeliColors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => onSelect(value),
      );
    }

    Widget _buildSkinConcernCheckbox(String title, String key) {
      final isSelected = _skinConcerns.contains(key);
      return CheckboxListTile(
        value: isSelected,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        activeColor: BeautyOnboardingPage.beautyPrimary,
        contentPadding: EdgeInsets.zero,
        onChanged: (val) {
          setState(() {
            if (val == true) {
              _skinConcerns.add(key);
            } else {
              _skinConcerns.remove(key);
            }
          });
        },
      );
    }

    Widget _buildGoalCheckbox(String title, String key) {
      final isSelected = _beautyGoals.contains(key);
      return CheckboxListTile(
        value: isSelected,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        activeColor: BeautyOnboardingPage.beautyPrimary,
        contentPadding: EdgeInsets.zero,
        onChanged: (val) {
          setState(() {
            if (val == true) {
              _beautyGoals.add(key);
            } else {
              _beautyGoals.remove(key);
            }
          });
        },
      );
    }

    Future<void> _handleNextOrSubmit() async {
      if (_currentStep < 4) {
        setState(() => _currentStep++);
        return;
      }

      _logger.userAction('Complete Beauty Onboarding submitted', screen: 'BeautyOnboardingPage');
      setState(() => _submitting = true);

      try {
        await ref.read(userProfileNotifierProvider.notifier).completeBeautyOnboarding(
              hairType: _hairType,
              porosity: _porosity,
              skinType: _skinType,
              scalpType: _scalpType,
              beautyGoals: _beautyGoals.toList(),
              skinConcerns: _skinConcerns.toList(),
              hairLengthCm: _hairLengthCm,
              hairStrengthScore: _hairStrengthScore,
              hairThicknessScore: _hairThicknessScore,
              hairSheddingRate: _hairSheddingRate,
              skinHydrationLevel: _skinHydrationLevel,
              skinClarityScore: _skinClarityScore,
              checkinNotes: _notesCtrl.text,
            );
        if (mounted) {
          context.go(AkeliRoutes.home);
        }
      } catch (e, st) {
        _logger.db('ERROR | completeBeautyOnboarding failed | $e', error: e, stackTrace: st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).beautyOnboardingSaveErrorSnackbar(e.toString()))),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _submitting = false);
        }
      }
    }
  }
  ```

  Note on the default notes text: the original code hardcoded `TextEditingController(text: 'Bilan initial du profil beauté')` at field-declaration time, before `context`/l10n is available. This fix moves that initial value into `didChangeDependencies()` (the first lifecycle point where `context` is safely usable), guarded by `_defaultNotesApplied` so it is only ever applied once, before the user can type over it.

- [ ] **Step 7: Update `test/features/beauty/beauty_onboarding_page_test.dart` to wrap `MaterialApp` with l10n delegates.**

  Replace the entire file with:

  ```dart
  import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
  import 'package:akeli/l10n/app_localizations.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    testWidgets('BeautyOnboardingPage renders 5-step wizard with Step 5 Resume & Confirmation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: BeautyOnboardingPage(),
          ),
        ),
      );

      // Step 1: Hair
      expect(find.text('Profil Beauté Botanique'), findsOneWidget);
      expect(find.textContaining('Empreinte Capillaire'), findsOneWidget);
      expect(find.textContaining('4C — Crépu Très Serré'), findsOneWidget);
      expect(find.text('Étape Suivante ➔'), findsOneWidget);

      // Tap Next → Step 2: Skin
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Diagnostic Cutané Profond'), findsOneWidget);

      // Tap Next → Step 3: Goals
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Objectifs Beauté & Priorités'), findsOneWidget);

      // Tap Next → Step 4: First Beauty Log Check-in
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Premier Bilan Initial'), findsOneWidget);
      expect(find.textContaining('Longueur Actuelle des Cheveux'), findsOneWidget);

      // Tap Next → Step 5: Resume & Confirmation
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Résumé & Confirmation'), findsOneWidget);
      expect(find.textContaining('👑 Profil Capillaire'), findsOneWidget);
      expect(find.textContaining('✨ Diagnostic Cutané'), findsOneWidget);
      expect(find.textContaining('📊 Mesures du Premier Bilan'), findsOneWidget);
      expect(find.text('Confirmer & Générer Mon Plan 30 Jours ✨'), findsOneWidget);
    });
  }
  ```

  Run:

  ```
  flutter test test/features/beauty/beauty_onboarding_page_test.dart
  ```

  Expected output:

  ```
  00:02 +1: All tests passed!
  ```

- [ ] **Step 8: Replace hardcoded strings in `lib/features/beauty/widgets/beauty_checkin_sheet.dart`.**

  Replace the entire file with (on top of Task 4's version):

  ```dart
  import 'package:flutter/material.dart';
  import '../../../core/logger.dart';
  import '../../../core/theme.dart';
  import '../../../l10n/app_localizations.dart';

  class BeautyCheckinSheet extends StatefulWidget {
    final String userId;
    final double? initialHairLengthCm;
    final double? initialHairStrengthScore;
    final double? initialHairThicknessScore;
    final double? initialSkinHydrationLevel;
    final double? initialSkinClarityScore;
    final Function(Map<String, dynamic> checkinData)? onSubmit;

    const BeautyCheckinSheet({
      super.key,
      required this.userId,
      this.initialHairLengthCm,
      this.initialHairStrengthScore,
      this.initialHairThicknessScore,
      this.initialSkinHydrationLevel,
      this.initialSkinClarityScore,
      this.onSubmit,
    });

    static Future<Map<String, dynamic>?> show(
      BuildContext context, {
      required String userId,
      double? initialHairLengthCm,
      double? initialHairStrengthScore,
      double? initialHairThicknessScore,
      double? initialSkinHydrationLevel,
      double? initialSkinClarityScore,
    }) {
      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BeautyCheckinSheet(
          userId: userId,
          initialHairLengthCm: initialHairLengthCm,
          initialHairStrengthScore: initialHairStrengthScore,
          initialHairThicknessScore: initialHairThicknessScore,
          initialSkinHydrationLevel: initialSkinHydrationLevel,
          initialSkinClarityScore: initialSkinClarityScore,
        ),
      );
    }

    @override
    State<BeautyCheckinSheet> createState() => _BeautyCheckinSheetState();
  }

  class _BeautyCheckinSheetState extends State<BeautyCheckinSheet> {
    final _logger = appLogger;
    late double _hairLengthCm;
    late double _hairStrengthScore;
    late double _hairThicknessScore;
    late double _skinHydrationLevel;
    late double _skinClarityScore;
    String _hairSheddingRate = 'normal';
    final _notesController = TextEditingController();

    @override
    void initState() {
      super.initState();
      _hairLengthCm = widget.initialHairLengthCm ?? 20.0;
      _hairStrengthScore = widget.initialHairStrengthScore ?? 7.0;
      _hairThicknessScore = widget.initialHairThicknessScore ?? 7.0;
      _skinHydrationLevel = widget.initialSkinHydrationLevel ?? 7.0;
      _skinClarityScore = widget.initialSkinClarityScore ?? 7.0;
    }

    @override
    void dispose() {
      _notesController.dispose();
      super.dispose();
    }

    void _handleSave() {
      _logger.userAction('Save Progress Check-In tapped', screen: 'BeautyCheckinSheet', metadata: {
        'hairLengthCm': _hairLengthCm,
        'hairStrengthScore': _hairStrengthScore,
        'hairThicknessScore': _hairThicknessScore,
        'skinHydrationLevel': _skinHydrationLevel,
        'skinClarityScore': _skinClarityScore,
        'hairSheddingRate': _hairSheddingRate,
      });
      final payload = <String, dynamic>{
        'userId': widget.userId,
        'hairLengthCm': _hairLengthCm,
        'hairStrengthScore': _hairStrengthScore,
        'hairThicknessScore': _hairThicknessScore,
        'skinHydrationLevel': _skinHydrationLevel,
        'skinClarityScore': _skinClarityScore,
        'hairSheddingRate': _hairSheddingRate,
        'checkinNotes': _notesController.text.trim(),
        'loggedAt': DateTime.now().toIso8601String(),
      };
      _logger.provider('BeautyCheckinSheet payload built | keys: ${payload.keys.join(', ')}');
      if (widget.onSubmit != null) {
        widget.onSubmit!(payload);
      }
      Navigator.of(context).pop(payload);
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context);
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 24 + bottomInset,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.beautyCheckinTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.beautyCheckinSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              Text(
                l10n.beautyCheckinHairLengthLabel(_hairLengthCm.toStringAsFixed(1)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('hair_length_slider'),
                value: _hairLengthCm,
                min: 2.0,
                max: 100.0,
                divisions: 196,
                activeColor: AkeliColors.primary,
                onChanged: (val) => setState(() => _hairLengthCm = val),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.beautyCheckinHairStrengthLabel(_hairStrengthScore.toStringAsFixed(1)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('hair_strength_slider'),
                value: _hairStrengthScore,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.accentAmber,
                onChanged: (val) => setState(() => _hairStrengthScore = val),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.beautyCheckinHairThicknessLabel(_hairThicknessScore.toStringAsFixed(1)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('hair_thickness_slider'),
                value: _hairThicknessScore,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.accentAmber,
                onChanged: (val) => setState(() => _hairThicknessScore = val),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.beautyCheckinSkinHydrationLabel(_skinHydrationLevel.toStringAsFixed(1)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('skin_hydration_slider'),
                value: _skinHydrationLevel,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.primaryContainer,
                onChanged: (val) => setState(() => _skinHydrationLevel = val),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.beautyCheckinSkinClarityLabel(_skinClarityScore.toStringAsFixed(1)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                key: const Key('skin_clarity_slider'),
                value: _skinClarityScore,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AkeliColors.primaryContainer,
                onChanged: (val) => setState(() => _skinClarityScore = val),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.beautyCheckinNotesLabel,
                  hintText: l10n.beautyCheckinNotesHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('save_beauty_checkin_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AkeliColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _handleSave,
                  child: Text(
                    l10n.beautyCheckinSaveButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

  (This file's shedding-rate chip row is added in Task 6, which runs after this l10n pass — Task 6 will use the `l10n` variable and 4 new ARB keys introduced there directly, per that task's own steps.)

- [ ] **Step 9: Update `test/features/beauty/widgets/beauty_checkin_sheet_test.dart` to wrap `MaterialApp` with l10n delegates (English, since this file's original text — and its EN ARB values — are English).**

  Add the import `import 'package:akeli/l10n/app_localizations.dart';` and change both tests' `MaterialApp(...)` from:

  ```dart
        MaterialApp(
          home: Scaffold(
  ```

  to:

  ```dart
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
  ```

  Run:

  ```
  flutter test test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 10: Replace hardcoded strings in `lib/features/beauty/widgets/today_beauty_routines_widget.dart`.**

  Replace the entire file with (on top of Task 4's version):

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/logger.dart';
  import '../../../core/router.dart';
  import '../../../core/theme.dart';
  import '../../../l10n/app_localizations.dart';
  import '../../../providers/beauty_plan_provider.dart';
  import '../../../shared/models/beauty_plan.dart';
  import '../../../shared/widgets/empty_state.dart';

  class TodayBeautyRoutinesWidget extends ConsumerWidget {
    final DateTime Function() now;
    static final _logger = appLogger;

    const TodayBeautyRoutinesWidget({super.key, this.now = DateTime.now});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      _logger.provider('TodayBeautyRoutinesWidget build()');
      final l10n = AppLocalizations.of(context);
      final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.todayBeautyRoutinesTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.textPrimary,
                      ),
                ),
                TextButton(
                  key: const Key('open_beauty_planner_button'),
                  onPressed: () {
                    context.push(AkeliRoutes.mealPlanner);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.todayBeautyRoutinesPlanningLink,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: AkeliColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          beautyPlanAsync.when(
            data: (plan) {
              if (plan == null || plan.slots.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    icon: Icons.spa_outlined,
                    title: l10n.todayBeautyRoutinesEmptyTitle,
                    subtitle: l10n.todayBeautyRoutinesEmptySubtitle,
                  ),
                );
              }

              final today = now();

              final todaySlots = plan.slots.where((s) {
                if (s.dayNumber != null) {
                  final slotDate = plan.startDate.add(Duration(days: s.dayNumber! - 1));
                  return slotDate.year == today.year &&
                      slotDate.month == today.month &&
                      slotDate.day == today.day;
                }
                return s.dayOfWeek == today.weekday;
              }).toList();

              if (todaySlots.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AkeliColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.todayBeautyRoutinesRestDay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AkeliColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: todaySlots.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final slot = todaySlots[index];
                  return _buildTodaySlotCard(context, ref, l10n, slot);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.todayBeautyRoutinesLoadError(err.toString()),
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildTodaySlotCard(
        BuildContext context, WidgetRef ref, AppLocalizations l10n, BeautyPlanSlot slot) {
      final isCompleted = slot.isCompleted;
      final recipe = slot.recipe;

      return Card(
        elevation: 0,
        color: isCompleted
            ? AkeliColors.surfaceContainerLow
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCompleted
                ? Colors.transparent
                : AkeliColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: AkeliColors.secondaryContainer,
              child: recipe?.thumbnailUrl != null && recipe!.thumbnailUrl!.isNotEmpty
                  ? Image.network(recipe.thumbnailUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.spa, color: AkeliColors.primary),
            ),
          ),
          title: Text(
            recipe?.title ?? slot.stepStage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? AkeliColors.textSecondary
                  : AkeliColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    slot.routineCategory.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  slot.frequencyTier != null
                      ? l10n.todayBeautyRoutinesTierLabel(slot.frequencyTier!)
                      : l10n.todayBeautyRoutinesDefaultLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AkeliColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing: Checkbox(
            value: isCompleted,
            activeColor: AkeliColors.primary,
            onChanged: (val) {
              _logger.userAction(
                'Beauty routine checkbox toggled',
                screen: 'TodayBeautyRoutinesWidget',
                metadata: {'slotId': slot.id, 'from': isCompleted, 'to': !isCompleted},
              );
              _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              ref
                  .read(toggleBeautySlotNotifierProvider.notifier)
                  .toggleCompletion(slot.id, isCompleted)
                  .then((_) {
                _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              }).catchError((e, st) {
                _logger.db('ERROR | toggleCompletion via TodayBeautyRoutinesWidget | $e', error: e, stackTrace: st);
              });
            },
          ),
          onTap: () {
            if (recipe != null) {
              context.push(AkeliRoutes.recipeDetailPath(recipe.id));
            }
          },
        ),
      );
    }
  }
  ```

- [ ] **Step 11: Update `test/features/beauty/widgets/today_beauty_routines_widget_test.dart` to wrap `MaterialApp` with l10n delegates.**

  Add the import `import 'package:akeli/l10n/app_localizations.dart';` and change both tests' `MaterialApp(...)` from:

  ```dart
            child: MaterialApp(
              home: Scaffold(
  ```

  to:

  ```dart
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('fr'),
              home: Scaffold(
  ```

  Run:

  ```
  flutter test test/features/beauty/widgets/today_beauty_routines_widget_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 12: Replace hardcoded strings in `lib/features/meal_planner/widgets/beauty_planner_view.dart`.**

  Replace the entire file with (on top of Task 4's version):

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../../core/logger.dart';
  import '../../../core/router.dart';
  import '../../../core/theme.dart';
  import '../../../l10n/app_localizations.dart';
  import '../../../providers/beauty_plan_provider.dart';
  import '../../../shared/models/beauty_plan.dart';
  import '../../../shared/widgets/empty_state.dart';

  class BeautyPlannerView extends ConsumerWidget {
    static final _logger = appLogger;

    const BeautyPlannerView({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      _logger.provider('BeautyPlannerView build()');
      final l10n = AppLocalizations.of(context);
      final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);

      return beautyPlanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            l10n.beautyPlannerLoadError(err.toString()),
            style: const TextStyle(color: AkeliColors.error),
          ),
        ),
        data: (plan) {
          if (plan == null || plan.slots.isEmpty) {
            return _buildEmptyBeautyState(context, ref, l10n);
          }

          final dailySlots = plan.slots.where((s) => s.frequencyTier == 'daily').toList();
          final weeklySlots = plan.slots.where((s) => s.frequencyTier == '1x_week' || s.frequencyTier == '2x_week').toList();
          final monthlySlots = plan.slots.where((s) => s.frequencyTier == '2x_month' || s.frequencyTier == '1x_month' || s.frequencyTier == null).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spa_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            l10n.beautyPlannerHeaderTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.beautyPlannerHeaderSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (dailySlots.isNotEmpty) ...[
                  _buildSectionHeader(context, l10n, l10n.beautyPlannerDailySectionTitle, dailySlots.length),
                  const SizedBox(height: 12),
                  ...dailySlots.take(2).map((slot) => _buildBeautySlotCard(context, ref, l10n, slot)),
                  const SizedBox(height: 24),
                ],

                if (weeklySlots.isNotEmpty) ...[
                  _buildSectionHeader(context, l10n, l10n.beautyPlannerWeeklySectionTitle, weeklySlots.length),
                  const SizedBox(height: 12),
                  ...weeklySlots.take(4).map((slot) => _buildBeautySlotCard(context, ref, l10n, slot)),
                  const SizedBox(height: 24),
                ],

                if (monthlySlots.isNotEmpty) ...[
                  _buildSectionHeader(context, l10n, l10n.beautyPlannerMonthlySectionTitle, monthlySlots.length),
                  const SizedBox(height: 12),
                  ...monthlySlots.take(3).map((slot) => _buildBeautySlotCard(context, ref, l10n, slot)),
                ],
              ],
            ),
          );
        },
      );
    }

    Widget _buildSectionHeader(BuildContext context, AppLocalizations l10n, String title, int count) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.textPrimary,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AkeliColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.beautyPlannerSectionCount(count),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AkeliColors.primary,
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildBeautySlotCard(BuildContext context, WidgetRef ref, AppLocalizations l10n, BeautyPlanSlot slot) {
      final recipe = slot.recipe;
      final isCompleted = slot.isCompleted;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCompleted
                ? AkeliColors.primary.withValues(alpha: 0.3)
                : AkeliColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        elevation: 0,
        color: isCompleted ? AkeliColors.surfaceContainerLow : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              color: AkeliColors.surfaceContainerHigh,
              child: recipe?.thumbnailUrl != null && recipe!.thumbnailUrl!.isNotEmpty
                  ? Image.network(recipe.thumbnailUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.spa, color: AkeliColors.primary),
            ),
          ),
          title: Text(
            recipe?.title ?? slot.stepStage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? AkeliColors.textSecondary : AkeliColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    slot.routineCategory.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.beautyPlannerDayLabel((slot.dayNumber ?? slot.dayOfWeek).toString()),
                  style: const TextStyle(fontSize: 12, color: AkeliColors.textSecondary),
                ),
              ],
            ),
          ),
          trailing: Checkbox(
            value: isCompleted,
            activeColor: AkeliColors.primary,
            onChanged: (val) {
              _logger.userAction(
                'Beauty routine checkbox toggled',
                screen: 'BeautyPlannerView',
                metadata: {'slotId': slot.id, 'from': isCompleted, 'to': !isCompleted},
              );
              _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              ref
                  .read(toggleBeautySlotNotifierProvider.notifier)
                  .toggleCompletion(slot.id, isCompleted)
                  .then((_) {
                _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
              }).catchError((e, st) {
                _logger.db('ERROR | toggleCompletion via BeautyPlannerView | $e', error: e, stackTrace: st);
              });
            },
          ),
          onTap: () {
            if (recipe != null) {
              context.push(AkeliRoutes.recipeDetailPath(recipe.id));
            }
          },
        ),
      );
    }

    Widget _buildEmptyBeautyState(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 64, color: AkeliColors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.beautyPlannerEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.beautyPlannerEmptySubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.bolt, color: Colors.white),
                label: Text(
                  l10n.beautyPlannerGenerateButton,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _logger.userAction('Générer Mon Plan Beauté tapped', screen: 'BeautyPlannerView');
                  _logger.db('BEFORE rpc | fn: generate_beauty_plan');
                  ref.read(generateBeautyPlanNotifierProvider.notifier).generatePlan().then((_) {
                    _logger.db('AFTER rpc | fn: generate_beauty_plan | success');
                  }).catchError((e, st) {
                    _logger.db('ERROR rpc | fn: generate_beauty_plan | $e', error: e, stackTrace: st);
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 13: Update `test/features/meal_planner/widgets/beauty_planner_view_test.dart` to wrap `MaterialApp` with l10n delegates.**

  Add the import `import 'package:akeli/l10n/app_localizations.dart';` and change both tests' `MaterialApp(...)` from:

  ```dart
            child: const MaterialApp(
              home: Scaffold(
  ```

  to:

  ```dart
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('fr'),
              home: Scaffold(
  ```

  Run:

  ```
  flutter test test/features/meal_planner/widgets/beauty_planner_view_test.dart
  ```

  Expected output:

  ```
  00:02 +2: All tests passed!
  ```

- [ ] **Step 14: Replace hardcoded strings in `lib/shared/widgets/color_set_modal.dart`, and give `ColorSetPreset` a stable, locale-independent `id`.**

  `ColorSetPreset.name`/`.description` were previously French literals used both for **display** and as the **identity** compared in `_selectedPreset.name == preset.name` and `presets.firstWhere((p) => p.primary == widget.initialPrimary, ...)`. Localizing `name`/`description` would make preset *identity* depend on the active locale, which is wrong. This step adds a stable `id` field or the actual selection/persistence key; display text is resolved from `id` via `AppLocalizations` inside `build()`.

  Replace the entire file with (on top of Task 4's version):

  ```dart
  import 'package:flutter/material.dart';
  import '../../core/logger.dart';
  import '../../core/theme.dart';
  import '../../l10n/app_localizations.dart';

  @immutable
  class ColorSetPreset {
    final String id;
    final Color primary;
    final Color secondary;

    const ColorSetPreset({
      required this.id,
      required this.primary,
      required this.secondary,
    });
  }

  class ColorSetModal extends StatefulWidget {
    final Color initialPrimary;
    final Color initialSecondary;
    final Function(Color primary, Color secondary)? onSelect;

    const ColorSetModal({
      super.key,
      required this.initialPrimary,
      required this.initialSecondary,
      this.onSelect,
    });

    static const List<ColorSetPreset> presets = [
      ColorSetPreset(
        id: 'teal_nutrition',
        primary: Color(0xFF00504A),
        secondary: Color(0xFFFF9F43),
      ),
      ColorSetPreset(
        id: 'rose_beauty',
        primary: Color(0xFF8A3B58),
        secondary: Color(0xFFD4AF37),
      ),
      ColorSetPreset(
        id: 'sage_botanique',
        primary: Color(0xFF4A6B5D),
        secondary: Color(0xFFCD7F32),
      ),
      ColorSetPreset(
        id: 'terracotta_soleil',
        primary: Color(0xFFB85D3B),
        secondary: Color(0xFFE0A96D),
      ),
    ];

    static String presetName(AppLocalizations l10n, String id) {
      switch (id) {
        case 'teal_nutrition':
          return l10n.colorSetModalPresetTealName;
        case 'rose_beauty':
          return l10n.colorSetModalPresetRoseName;
        case 'sage_botanique':
          return l10n.colorSetModalPresetSageName;
        case 'terracotta_soleil':
          return l10n.colorSetModalPresetTerracottaName;
        default:
          return id;
      }
    }

    static String presetDescription(AppLocalizations l10n, String id) {
      switch (id) {
        case 'teal_nutrition':
          return l10n.colorSetModalPresetTealDesc;
        case 'rose_beauty':
          return l10n.colorSetModalPresetRoseDesc;
        case 'sage_botanique':
          return l10n.colorSetModalPresetSageDesc;
        case 'terracotta_soleil':
          return l10n.colorSetModalPresetTerracottaDesc;
        default:
          return '';
      }
    }

    static Future<ColorSetPreset?> show(
      BuildContext context, {
      Color initialPrimary = const Color(0xFF00504A),
      Color initialSecondary = const Color(0xFFFF9F43),
    }) {
      return showModalBottomSheet<ColorSetPreset>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => ColorSetModal(
          initialPrimary: initialPrimary,
          initialSecondary: initialSecondary,
        ),
      );
    }

    @override
    State<ColorSetModal> createState() => _ColorSetModalState();
  }

  class _ColorSetModalState extends State<ColorSetModal> {
    final _logger = appLogger;
    late ColorSetPreset _selectedPreset;

    @override
    void initState() {
      super.initState();
      _selectedPreset = ColorSetModal.presets.firstWhere(
        (p) => p.primary == widget.initialPrimary,
        orElse: () => ColorSetModal.presets.first,
      );
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context);

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.colorSetModalTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.colorSetModalSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              ...ColorSetModal.presets.map((preset) {
                final isSelected = _selectedPreset.id == preset.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? preset.primary
                          : AkeliColors.outlineVariant.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  elevation: 0,
                  color: isSelected
                      ? preset.primary.withValues(alpha: 0.05)
                      : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: preset.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: preset.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      ColorSetModal.presetName(l10n, preset.id),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      ColorSetModal.presetDescription(l10n, preset.id),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: preset.primary)
                        : null,
                    onTap: () {
                      _logger.userAction('Color preset selected', screen: 'ColorSetModal', metadata: {'preset': preset.id});
                      setState(() => _selectedPreset = preset);
                    },
                  ),
                );
              }),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('apply_color_set_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPreset.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    _logger.userAction('Apply color palette tapped', screen: 'ColorSetModal', metadata: {'preset': _selectedPreset.id});
                    if (widget.onSelect != null) {
                      widget.onSelect!(_selectedPreset.primary, _selectedPreset.secondary);
                    }
                    Navigator.of(context).pop(_selectedPreset);
                  },
                  child: Text(
                    l10n.colorSetModalApplyButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

  Note: this step deliberately does **not** yet wire `onSelect`/`onTap` to any persistence provider — that is Task 7's job. The `_logger.userAction` calls above are the same Task 4 logging, now referencing `preset.id` instead of the removed `preset.name`.

- [ ] **Step 15: Update `test/shared/widgets/color_set_modal_test.dart`.**

  The preset no longer has `.name`/`.description`, so the test's assertions must switch to the localized display text (via `find.text(...)`, matching the French ARB values since we pin `locale: Locale('fr')`) and to `.id` for identity. Replace the entire file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/l10n/app_localizations.dart';
  import 'package:akeli/shared/widgets/color_set_modal.dart';

  void main() {
    group('ColorSetModal Widget Tests', () {
      testWidgets('renders color presets and allows selection', (WidgetTester tester) async {
        ColorSetPreset? selectedPreset;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedPreset = await ColorSetModal.show(context);
                  },
                  child: const Text('Open Color Selector'),
                ),
              ),
            ),
          ),
        );

        // Open modal
        await tester.tap(find.text('Open Color Selector'));
        await tester.pumpAndSettle();

        expect(find.text('Personnaliser le Thème de Couleurs'), findsOneWidget);
        expect(find.text('Rose & Gold (Beauty)'), findsOneWidget);

        // Select Rose & Gold preset
        await tester.tap(find.text('Rose & Gold (Beauty)'));
        await tester.pumpAndSettle();

        // Tap apply button (ensure visible in scroll view first)
        await tester.ensureVisible(find.byKey(const Key('apply_color_set_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('apply_color_set_button')));
        await tester.pumpAndSettle();

        expect(selectedPreset, isNotNull);
        expect(selectedPreset!.id, equals('rose_beauty'));
        expect(selectedPreset!.primary, equals(const Color(0xFF8A3B58)));
      });
    });
  }
  ```

  Run:

  ```
  flutter test test/shared/widgets/color_set_modal_test.dart
  ```

  Expected output:

  ```
  00:02 +1: All tests passed!
  ```

- [ ] **Step 16: Regenerate localizations, run `flutter analyze`, run the full area test suite, then commit.**

  ```
  flutter gen-l10n
  flutter analyze lib/features/beauty/ lib/features/meal_planner/widgets/beauty_planner_view.dart lib/shared/widgets/color_set_modal.dart
  ```

  Expected output:

  ```
  Analyzing beauty, beauty_planner_view.dart, color_set_modal.dart...
  No issues found! (ran in X.Xs)
  ```

  ```
  flutter test test/features/beauty/ test/features/meal_planner/widgets/beauty_planner_view_test.dart test/shared/widgets/color_set_modal_test.dart
  ```

  Expected output:

  ```
  00:07 +12: All tests passed!
  ```

  ```
  git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/features/beauty/ lib/features/meal_planner/widgets/beauty_planner_view.dart lib/shared/widgets/color_set_modal.dart test/features/beauty/ test/features/meal_planner/widgets/beauty_planner_view_test.dart test/shared/widgets/color_set_modal_test.dart
  git commit -m "feat(beauty): replace ~188 hardcoded strings with AppLocalizations across all 6 Beauty UI files"
  ```

### Task 6: Add the missing `hairSheddingRate` control to `BeautyCheckinSheet` (Medium)

**Files:**
- `lib/l10n/app_en.arb` / `lib/l10n/app_fr.arb` (4 new keys — already appended in Task 5's Step 1/2 edits: `beautyCheckinSheddingLabel/Low/Moderate/High`)
- `lib/features/beauty/widgets/beauty_checkin_sheet.dart` (fix — on top of Task 5's version)
- `test/features/beauty/widgets/beauty_checkin_sheet_test.dart` (TDD test extension)

**Interfaces:** No constructor changes. `_hairSheddingRate` gains a real `ChoiceChip` row (mirroring `beauty_onboarding_page.dart`'s `_buildSelectableChip` pattern — read there for the exact options list: `'low'`/`'moderate'`/`'high'`), so it is no longer hardcoded to `'normal'` forever.

Task 1 already added sliders for `hairThicknessScore`/`skinClarityScore` and wired all fields into the camelCase `_handleSave()` payload. `hairThicknessScore`/`skinClarityScore` are exercised by Task 1's own tests. This task's only remaining gap is `hairSheddingRate`, which still has no UI control.

### Steps

- [ ] **Step 1: Extend the failing test in `test/features/beauty/widgets/beauty_checkin_sheet_test.dart`.**

  Append this test inside the existing `group('BeautyCheckinSheet Widget Tests', () { ... })` block (after the two tests from Task 1):

  ```dart
    testWidgets(
        'tapping the "High" shedding-rate chip reaches the save payload as hairSheddingRate: "high"',
        (WidgetTester tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  submittedData = await BeautyCheckinSheet.show(
                    context,
                    userId: 'test-user-789',
                  );
                },
                child: const Text('Open Checkin'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Checkin'));
      await tester.pumpAndSettle();

      // Default is 'normal' (no chip selected) until the user picks one —
      // confirm the "High" chip exists and tap it.
      expect(find.byKey(const Key('shedding_rate_chip_high')), findsOneWidget);
      await tester.tap(find.byKey(const Key('shedding_rate_chip_high')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      // Fails against the current code: there is no chip control at all, so
      // `hairSheddingRate` can never become anything but the hardcoded
      // default `'normal'`.
      expect(submittedData!['hairSheddingRate'], equals('high'));
    });
  ```

  Also add `import 'package:akeli/l10n/app_localizations.dart';` to the top of the file if not already present from Task 5's Step 9 edit.

- [ ] **Step 2: Confirm the test fails against current code.**

  ```
  flutter test test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  ```

  Expected output — fails because `Key('shedding_rate_chip_high')` does not exist yet:

  ```
  ...tapping the "High" shedding-rate chip reaches the save payload as hairSheddingRate: "high" [E]
    Expected: exactly one matching node in the widget tree
    Actual: _KeyWidgetFinder:<zero widgets with key [<'shedding_rate_chip_high'>]>
  ...
  00:02 +2 -1: Some tests failed.
  ```

- [ ] **Step 3: Add the shedding-rate chip row to `lib/features/beauty/widgets/beauty_checkin_sheet.dart`.**

  Insert this block into `build()`, between the "Skin Clarity Score" slider's `SizedBox(height: 16)` and the `TextField` (notes) — i.e. replace:

  ```dart
                onChanged: (val) => setState(() => _skinClarityScore = val),
              ),
              const SizedBox(height: 16),

              TextField(
  ```

  with:

  ```dart
                onChanged: (val) => setState(() => _skinClarityScore = val),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.beautyCheckinSheddingLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSheddingChip(l10n.beautyCheckinSheddingLow, 'low'),
                  _buildSheddingChip(l10n.beautyCheckinSheddingModerate, 'moderate'),
                  _buildSheddingChip(l10n.beautyCheckinSheddingHigh, 'high'),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
  ```

  Add this new helper method (mirroring `beauty_onboarding_page.dart`'s `_buildSelectableChip`) right after `_handleSave()`:

  ```dart
    Widget _buildSheddingChip(String label, String value) {
      final isSelected = _hairSheddingRate == value;
      return ChoiceChip(
        key: Key('shedding_rate_chip_$value'),
        label: Text(label),
        selected: isSelected,
        selectedColor: AkeliColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AkeliColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) {
          _logger.userAction('Shedding rate chip selected', screen: 'BeautyCheckinSheet', metadata: {'value': value});
          setState(() => _hairSheddingRate = value);
        },
      );
    }
  ```

  (`l10n` is already in scope inside `build()` from Task 5's Step 8 edit; `_buildSheddingChip` is called from within `build()`, so no extra parameter threading is needed.)

- [ ] **Step 4: Confirm the test now passes.**

  ```
  flutter test test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  ```

  Expected output:

  ```
  00:02 +3: All tests passed!
  ```

- [ ] **Step 5: Run `flutter analyze` on the file and commit.**

  ```
  flutter analyze lib/features/beauty/widgets/beauty_checkin_sheet.dart
  ```

  Expected output:

  ```
  Analyzing beauty_checkin_sheet.dart...
  No issues found! (ran in X.Xs)
  ```

  ```
  git add lib/features/beauty/widgets/beauty_checkin_sheet.dart test/features/beauty/widgets/beauty_checkin_sheet_test.dart
  git commit -m "feat(beauty): add missing hairSheddingRate chip control to BeautyCheckinSheet"
  ```

### Task 7: Give `ColorSetModal` real Hive persistence via a new `color_set_provider.dart` (High)

**Files:**
- `lib/providers/color_set_provider.dart` (**new file** — explicitly directed by this finding; not in this area's original file list, but required to make the modal's own selection persist, which is this task's scope)
- `lib/shared/widgets/color_set_modal.dart` (fix — wire `onSelect`/preset-tap to the new provider — on top of Task 5's version)
- `test/providers/color_set_provider_test.dart` (**new test file**, mirrors the existing `test/providers/` convention, e.g. `test/providers/push_token_provider_test.dart`)

**Interfaces:** `final colorSetProvider = NotifierProvider<ColorSetNotifier, ColorSetPreset>(ColorSetNotifier.new);` exposing `.selectPreset(ColorSetPreset preset)`. Persists to the **same** already-open Hive box `'mode_state'` used by `lib/providers/mode_provider.dart`'s `ModeNotifier` (opened once in `lib/main.dart:27`, read-only reference — do not edit `main.dart` or `mode_provider.dart`), under a new key `'selected_color_set_id'`.

**CROSS-PLAN DEPENDENCY — read, do not implement:** This task only makes `ColorSetModal`'s own selection persist and gives other plans a provider to read from. It does **not** make the picker reachable or visually effective:
- **Area G** (owns `lib/core/theme.dart`) must thread `colorSetProvider`'s value into `getAppModeColor`/`buildLightTheme`/`buildDarkTheme` for a selected preset to actually change the app's rendered theme.
- **Area H** (owns `lib/features/settings/settings_page.dart`) must add a real entry point (a menu row or button) that calls `ColorSetModal.show(...)` — today nothing in the app calls `.show()` on it.

Do not touch `lib/core/theme.dart` or `lib/features/settings/settings_page.dart` in this task.

### Steps

- [ ] **Step 1: Write the failing test in `test/providers/color_set_provider_test.dart` (new file).**

  First read `lib/providers/mode_provider.dart`'s `ModeNotifier` (already done above) to confirm the exact Hive box-open/read/write pattern being mirrored. Create:

  ```dart
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:hive_flutter/hive_flutter.dart';
  import 'package:akeli/providers/color_set_provider.dart';
  import 'package:akeli/shared/widgets/color_set_modal.dart';

  void main() {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('color_set_provider_test');
      Hive.init(tempDir.path);
      await Hive.openBox('mode_state');
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('defaults to the first preset (Teal & Amber / Nutrition) when nothing is persisted', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final preset = container.read(colorSetProvider);
      expect(preset.id, equals(ColorSetModal.presets.first.id));
    });

    test('selectPreset persists the chosen preset id to Hive and updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rosePreset = ColorSetModal.presets.firstWhere((p) => p.id == 'rose_beauty');

      await container.read(colorSetProvider.notifier).selectPreset(rosePreset);

      expect(container.read(colorSetProvider).id, equals('rose_beauty'));

      final box = Hive.box('mode_state');
      expect(box.get('selected_color_set_id'), equals('rose_beauty'));
    });

    test('a fresh provider instance loads the previously persisted preset from Hive (round-trip)', () async {
      final box = Hive.box('mode_state');
      await box.put('selected_color_set_id', 'sage_botanique');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final preset = container.read(colorSetProvider);
      expect(preset.id, equals('sage_botanique'));
    });
  }
  ```

- [ ] **Step 2: Confirm the test fails (does not even compile — `color_set_provider.dart` does not exist yet).**

  ```
  flutter test test/providers/color_set_provider_test.dart
  ```

  Expected output:

  ```
  Error: Error when reading 'lib/providers/color_set_provider.dart': No such file or directory
  ```

- [ ] **Step 3: Create `lib/providers/color_set_provider.dart`.**

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:hive_flutter/hive_flutter.dart';
  import '../core/logger.dart';
  import '../shared/widgets/color_set_modal.dart';

  final _logger = appLogger;

  /// Persists the user's selected [ColorSetPreset] in the same Hive box
  /// ('mode_state') that `ModeNotifier` (lib/providers/mode_provider.dart)
  /// already opens in lib/main.dart — no new box is created.
  final colorSetProvider = NotifierProvider<ColorSetNotifier, ColorSetPreset>(ColorSetNotifier.new);

  class ColorSetNotifier extends Notifier<ColorSetPreset> {
    static const _boxName = 'mode_state';
    static const _colorSetKey = 'selected_color_set_id';

    @override
    ColorSetPreset build() {
      _logger.provider('ColorSetNotifier build()');
      ref.onDispose(() => _logger.provider('ColorSetNotifier disposed'));

      try {
        if (Hive.isBoxOpen(_boxName)) {
          final box = Hive.box(_boxName);
          final savedId = box.get(_colorSetKey) as String?;
          if (savedId != null) {
            final preset = ColorSetModal.presets.firstWhere(
              (p) => p.id == savedId,
              orElse: () => ColorSetModal.presets.first,
            );
            _logger.provider('ColorSetNotifier → initial: ${preset.id} (loaded from cache)');
            return preset;
          }
        }
      } catch (e) {
        _logger.provider('ColorSetNotifier → box read error: $e');
      }
      return ColorSetModal.presets.first;
    }

    Future<void> selectPreset(ColorSetPreset preset) async {
      _logger.provider('ColorSetNotifier → selecting: ${preset.id}');
      try {
        final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
        await box.put(_colorSetKey, preset.id);
      } catch (e) {
        _logger.provider('ColorSetNotifier selectPreset error: $e');
      }
      state = preset;
      _logger.provider('ColorSetNotifier → ${preset.id}');
    }
  }
  ```

- [ ] **Step 4: Confirm the test now passes.**

  ```
  flutter test test/providers/color_set_provider_test.dart
  ```

  Expected output:

  ```
  00:01 +3: All tests passed!
  ```

- [ ] **Step 5: Wire `color_set_modal.dart`'s own callbacks to `colorSetProvider`.**

  Convert `ColorSetModal`/`_ColorSetModalState` from `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState` so the widget can `ref.read(colorSetProvider.notifier)`. Apply this diff on top of Task 5's Step 14 version:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../core/logger.dart';
  import '../../core/theme.dart';
  import '../../l10n/app_localizations.dart';
  import '../../providers/color_set_provider.dart';
  ```

  ```dart
  class ColorSetModal extends ConsumerStatefulWidget {
    final Color initialPrimary;
    final Color initialSecondary;
    final Function(Color primary, Color secondary)? onSelect;

    const ColorSetModal({
      super.key,
      required this.initialPrimary,
      required this.initialSecondary,
      this.onSelect,
    });

    static const List<ColorSetPreset> presets = [
      // ...unchanged from Task 5's Step 14...
    ];

    static String presetName(AppLocalizations l10n, String id) {
      // ...unchanged...
    }

    static String presetDescription(AppLocalizations l10n, String id) {
      // ...unchanged...
    }

    static Future<ColorSetPreset?> show(
      BuildContext context, {
      Color initialPrimary = const Color(0xFF00504A),
      Color initialSecondary = const Color(0xFFFF9F43),
    }) {
      return showModalBottomSheet<ColorSetPreset>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => ColorSetModal(
          initialPrimary: initialPrimary,
          initialSecondary: initialSecondary,
        ),
      );
    }

    @override
    ConsumerState<ColorSetModal> createState() => _ColorSetModalState();
  }

  class _ColorSetModalState extends ConsumerState<ColorSetModal> {
    final _logger = appLogger;
    late ColorSetPreset _selectedPreset;

    @override
    void initState() {
      super.initState();
      _selectedPreset = ColorSetModal.presets.firstWhere(
        (p) => p.primary == widget.initialPrimary,
        orElse: () => ColorSetModal.presets.first,
      );
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context);
      // ...unchanged body down to the Apply button...
  ```

  Update only the Apply button's `onPressed` (everything else in `build()` — the preset list, the `onTap` per preset card — is unchanged from Task 5's Step 14):

  ```dart
                  onPressed: () {
                    _logger.userAction('Apply color palette tapped', screen: 'ColorSetModal', metadata: {'preset': _selectedPreset.id});
                    ref.read(colorSetProvider.notifier).selectPreset(_selectedPreset);
                    if (widget.onSelect != null) {
                      widget.onSelect!(_selectedPreset.primary, _selectedPreset.secondary);
                    }
                    Navigator.of(context).pop(_selectedPreset);
                  },
  ```

- [ ] **Step 6: Confirm `color_set_modal_test.dart` still passes (it doesn't assert on persistence, only on the returned preset, which is unchanged).**

  ```
  flutter test test/shared/widgets/color_set_modal_test.dart
  ```

  Expected output:

  ```
  00:02 +1: All tests passed!
  ```

  Note: this widget test does **not** wrap its `MaterialApp` in a `ProviderScope` today; `ConsumerStatefulWidget` requires an ancestor `ProviderScope` to call `ref.read(...)`. Add one:

  ```dart
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('fr'),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      selectedPreset = await ColorSetModal.show(context);
                    },
                    child: const Text('Open Color Selector'),
                  ),
                ),
              ),
            ),
          ),
        );
  ```

  (add `import 'package:flutter_riverpod/flutter_riverpod.dart';` to the test file's imports), then re-run:

  ```
  flutter test test/shared/widgets/color_set_modal_test.dart
  ```

  Expected output:

  ```
  00:02 +1: All tests passed!
  ```

- [ ] **Step 7: Run `flutter analyze` and commit.**

  ```
  flutter analyze lib/providers/color_set_provider.dart lib/shared/widgets/color_set_modal.dart
  ```

  Expected output:

  ```
  Analyzing color_set_provider.dart, color_set_modal.dart...
  No issues found! (ran in X.Xs)
  ```

  ```
  git add lib/providers/color_set_provider.dart lib/shared/widgets/color_set_modal.dart test/providers/color_set_provider_test.dart test/shared/widgets/color_set_modal_test.dart
  git commit -m "feat(beauty): persist ColorSetModal preset selection via new color_set_provider (Hive-backed)"
  ```

  **Reminder:** the preset picker is still unreachable from the app UI and still does not affect the rendered theme after this commit — those two gaps are Area H's and Area G's respective plans, not this one.

## Coverage Checklist

| # | Finding | Severity | Task | Notes |
|---|---|---|---|---|
| 1 | Check-in key-casing mismatch (`beauty_checkin_sheet.dart` snake_case vs. `beauty_analytics_page.dart` camelCase) | Critical | Task 1 | Also adds `hairThicknessScore`/`skinClarityScore` sliders and wires them into the camelCase payload, per the finding's explicit instruction. |
| 2 | "Today's Rituals" day-filter bug (`dayNumber` vs. `DateTime.now().day`) | Critical | Task 2 | Adds `now:` clock-injection constructor param; compares `plan.startDate + dayNumber - 1` to injected "today". Does not edit `beauty_plan.dart`'s wrong comment (Area E's). |
| 3 | Timeframe chips (7J/30J/90J/Tout) are cosmetic, never filter data | High | Task 3 | `_selectedTimeframeId` (internal id) + `_cutoffFor`/`_filterLogsByTimeframe` actually filter `logs` before the hair/skin/history sections render. |
| 4 | 5 of 6 files have zero `appLogger` calls | High | Task 4 | `beauty_analytics_page.dart`, `beauty_checkin_sheet.dart`, `today_beauty_routines_widget.dart`, `beauty_planner_view.dart`, `color_set_modal.dart`. `beauty_onboarding_page.dart` already had logging and is untouched by this task. |
| 5 | Zero `AppLocalizations` usage across all 6 files, zero Beauty ARB keys | High | Task 5 | 188 new keys added to both `app_en.arb`/`app_fr.arb` (additive-only); `beauty_checkin_sheet.dart`'s English originals are translated into French per the finding. `flutter gen-l10n` + `flutter analyze` both run clean at Task 5 Step 16. |
| 6 | `BeautyCheckinSheet` missing `hairThicknessScore`/`skinClarityScore` controls and `hairSheddingRate` control | Medium | Task 1 (thickness/clarity sliders) + Task 6 (shedding-rate chips) | Task 6 adds its own 4 ARB keys (`beautyCheckinSheddingLabel/Low/Moderate/High`) since that UI doesn't exist until this task runs (after Task 5's l10n pass). |
| 7 | `ColorSetModal` is unreachable dead code with no persistence | High | Task 7 | **Cross-plan finding — only half implemented here.** This plan implements: (a) new `lib/providers/color_set_provider.dart` with Hive persistence, tested by `test/providers/color_set_provider_test.dart`; (b) wiring the modal's own `onSelect`/Apply-button callback to that provider. **NOT implemented here (other plans' scope):** Area G (`lib/core/theme.dart`) must thread `colorSetProvider` into `getAppModeColor`/`buildLightTheme`/`buildDarkTheme`; Area H (`lib/features/settings/settings_page.dart`) must add a real UI entry point that calls `ColorSetModal.show(...)`. Until both of those land, the picker remains unreachable from the app and has no visual effect, even though its own selection now persists correctly. |

### Final state after all 7 tasks
- `flutter test test/features/beauty/ test/features/meal_planner/widgets/beauty_planner_view_test.dart test/shared/widgets/color_set_modal_test.dart test/providers/color_set_provider_test.dart` — all green.
- `flutter analyze lib/features/beauty/ lib/features/meal_planner/widgets/beauty_planner_view.dart lib/shared/widgets/color_set_modal.dart lib/providers/color_set_provider.dart` — no issues.
- `lib/l10n/app_en.arb` / `lib/l10n/app_fr.arb` — 192 new keys added (188 in Task 5 + 4 in Task 6), zero existing keys modified.
- 7 commits, one per task, each preceded by a red→green TDD cycle for its behavioral change (Task 5's l10n pass is the one purely mechanical, non-TDD exception, as it has no new behavior to red/green against).

