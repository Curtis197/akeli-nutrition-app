# Beauty Mode Fix — Area G: Flutter Core Mode-Switching Infrastructure

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the router's infinite-redirect crash and route-based onboarding-gate bypass, remove dead/duplicate routing code, correct the SDUI subsystem's false "done" documentation, bring `main_shell.dart`/`dynamic_layout_page.dart`/`mode_selector.dart` into CLAUDE.md logging/l10n compliance, and thread Area F's forthcoming color-set provider through the theme builders.

**Architecture:** The router's `redirect` callback currently mixes four sequential, non-exclusive `if` statements that can bounce a user between `/onboarding` and `/onboarding/beauty` forever; this plan extracts that logic into a single pure, unit-testable function (`computeAkeliRedirect`) evaluated as a strict if/else-if chain, then rewires the existing `GoRouter` to call it. Everything else (docs corrections, hardcoded strings, missing dark-theme fields, color-provider threading) is a mechanical, file-scoped fix verified by a dedicated test per finding.

**Tech Stack:** Flutter, GoRouter, Riverpod, flutter_test, ARB/l10n

## Global Constraints
- Repo: c:\Users\DELL LATITUDE 7480\akeli-nutrition-app, branch `sdui`.
- CLAUDE.md Logging Standard AND L10n Standard both apply to every file you touch.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Only touch files listed as "owned" in the review's Area G scope: `lib/core/router.dart`, `lib/core/theme.dart`, `lib/core/sdui/services/layout_cache_service.dart`, `lib/core/sdui/services/layout_fetch_service.dart`, `lib/core/sdui/widgets/dynamic_layout_page.dart`, `lib/core/sdui/widgets/widget_factory.dart`, `lib/shared/widgets/main_shell.dart`, `lib/main.dart`, `lib/widgets/mode_selector.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (shared — only add new keys, never edit/remove other areas' keys), plus new test files and the two SDUI doc files named in Task 2.
- **File-overlap sequencing (do not run the following concurrently against the same file):**
  - Tasks 1, 3, and 4 all edit `lib/core/router.dart`. Required order: **Task 1 before Task 3** (Task 3 extends Task 1's test file and reads Task 1's code). Task 4 touches a disjoint region (a duplicate `GoRoute` block, not the redirect closure) and may run before Task 1 or after Task 3 — never interleaved with them.
  - Tasks 5, 8, and 9 all append new keys to `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`. Run strictly in that numeric order — each task's ARB edit is anchored to the previous task's last inserted key.
  - Tasks 6 and 7 both edit `lib/core/theme.dart`. Run **Task 6 Part A before Task 7**.
  - Task 2's OPTIONAL steps (if attempted) also edit `lib/core/router.dart` — sequence them after Tasks 1, 3, and 4.
  - Run `flutter gen-l10n` after every ARB edit, before compiling or running any test that references the new keys.
- Task 6's main.dart wiring (Part B) depends on Area F's plan (`docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md`) having created `lib/providers/color_set_provider.dart`. As of this plan being written, that file does **not** exist yet — Task 6 documents the exact check-and-adapt procedure.

---

## Task 1: [Critical] Fix router infinite redirect loop

**Files:** `lib/core/router.dart`, `test/core/router_redirect_test.dart` (new).

**Interfaces:**
```dart
String? computeAkeliRedirect({
  required bool isAuthenticated,
  required bool isRecovery,
  required String currentPath,
  required bool hasProfile,
  required bool onboardingDone,
  required bool beautyOnboardingDone,
  required AppMode currentMode,
});
```

### Background (verified against the real file, 2026-07-23)

`lib/core/router.dart`'s `routerProvider` (lines 141–458) builds one `GoRouter` whose `redirect:` callback (lines 147–217) contains, inside `if (isAuth) { if (profile != null) { ... } }` (lines 183–213), **four independent sequential `if` statements**:

```dart
if (!profile.onboardingDone && !isOnOnboarding) {           // line 187
  ... return AkeliRoutes.onboarding;
}
if (profile.onboardingDone && isOnOnboarding) {              // line 195
  ... return AkeliRoutes.home;
}
// Beauty Mode Onboarding Check
if (currentMode == AppMode.beauty && !profile.beautyOnboardingDone && !isOnBeautyOnboarding) {  // line 201
  ... return AkeliRoutes.beautyOnboarding;
}
if (profile.beautyOnboardingDone && isOnBeautyOnboarding) {  // line 209
  ... return AkeliRoutes.home;
}
```

For a user with `profile.onboardingDone == false`, `profile.beautyOnboardingDone == false`, and `currentMode == AppMode.beauty` (a real, reachable state — e.g. a stale `AppMode.beauty` selection persisted in the `mode_state` Hive box from a previous account on the same device):
- On `/onboarding`: the first `if` is false (already on onboarding), the third `if` is true (`currentMode == beauty && !beautyOnboardingDone && !isOnBeautyOnboarding`) → redirects to `/onboarding/beauty`.
- On `/onboarding/beauty`: the first `if` is true again (`!onboardingDone && !isOnOnboarding`) → redirects back to `/onboarding`.

This is an infinite loop; go_router's own loop detection converts it into a thrown `GoException`, crashing navigation.

### Steps

- [ ] **Step 1: Write a failing test that reproduces the crash against the CURRENT (buggy) redirect chain.**

  Create `test/core/router_redirect_test.dart`:

  ```dart
  // test/core/router_redirect_test.dart
  //
  // FINDING #1 (Critical) — router infinite redirect loop.
  // See docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md Area G.
  //
  // This file starts by reproducing the CURRENT (pre-fix) redirect chain from
  // lib/core/router.dart lines 187-212 verbatim, as a local standalone copy —
  // the real logic lives inline inside a GoRouter closure and can't be
  // imported directly. Step 4 of this task replaces this local copy with an
  // import of the real, fixed `computeAkeliRedirect` function.
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:go_router/go_router.dart';
  import 'package:akeli/core/router.dart';
  import 'package:akeli/providers/mode_provider.dart';

  /// Verbatim reproduction of the CURRENT (pre-fix) redirect chain — four
  /// independent sequential `if`s, exactly as in lib/core/router.dart lines
  /// 187-212 today. This is what causes the infinite loop.
  String? _brokenRedirect({
    required String currentPath,
    required bool onboardingDone,
    required bool beautyOnboardingDone,
    required AppMode currentMode,
  }) {
    final isOnOnboarding = currentPath == AkeliRoutes.onboarding;
    final isOnBeautyOnboarding = currentPath == AkeliRoutes.beautyOnboarding;

    if (!onboardingDone && !isOnOnboarding) {
      return AkeliRoutes.onboarding;
    }
    if (onboardingDone && isOnOnboarding) {
      return AkeliRoutes.home;
    }
    // Beauty Mode Onboarding Check
    if (currentMode == AppMode.beauty && !beautyOnboardingDone && !isOnBeautyOnboarding) {
      return AkeliRoutes.beautyOnboarding;
    }
    if (beautyOnboardingDone && isOnBeautyOnboarding) {
      return AkeliRoutes.home;
    }
    return null;
  }

  void main() {
    testWidgets(
      'FINDING #1: beauty-mode user with incomplete nutrition onboarding does not crash with GoException',
      (tester) async {
        final router = GoRouter(
          initialLocation: AkeliRoutes.onboarding,
          redirect: (context, state) => _brokenRedirect(
            currentPath: state.uri.path,
            onboardingDone: false,
            beautyOnboardingDone: false,
            currentMode: AppMode.beauty,
          ),
          routes: [
            GoRoute(path: AkeliRoutes.onboarding, builder: (c, s) => const Scaffold(body: Text('onboarding'))),
            GoRoute(path: AkeliRoutes.beautyOnboarding, builder: (c, s) => const Scaffold(body: Text('beauty-onboarding'))),
            GoRoute(path: AkeliRoutes.home, builder: (c, s) => const Scaffold(body: Text('home'))),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Desired behavior: no crash. Against the current buggy chain this
        // FAILS because go_router's loop detection throws a GoException.
        expect(tester.takeException(), isNull);
      },
    );
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails against current code.**

  ```
  flutter test test/core/router_redirect_test.dart
  ```

  Expected output: the test **fails** — `tester.takeException()` returns a `GoException` (message containing "error while parsing" / redirect loop), so `expect(tester.takeException(), isNull)` reports a failure. This confirms the bug reproduces.

- [ ] **Step 3: Fix `lib/core/router.dart`.**

  Read the current file's `AkeliRoutes` class (ends around line 108) and the `redirect:` callback (lines 147–217) to get exact current text before editing.

  Insert the following new code **directly after the closing `}` of `abstract class AkeliRoutes { ... }`** (i.e. right before the `// RouterNotifier — triggers GoRouter refresh on auth state changes` comment):

  ```dart
  // ---------------------------------------------------------------------------
  // Redirect logic — pure function, unit-testable without Riverpod/Supabase.
  // See test/core/router_redirect_test.dart.
  //
  // Routes that gate on Beauty-mode onboarding regardless of the user's
  // currently-selected AppMode (Finding #3 — deep links / bookmarks / browser
  // back-forward on the web target must not bypass the gate just because
  // currentMode happens to be nutrition).
  // ---------------------------------------------------------------------------
  const _beautyGatedRoutes = <String>{
    AkeliRoutes.beautyAnalytics,
  };

  /// Computes the GoRouter redirect target for the current navigation state, or
  /// `null` if no redirect is needed.
  ///
  /// Exposed (not private) so it can be unit-tested directly — see
  /// test/core/router_redirect_test.dart — without needing to spin up
  /// Supabase, Riverpod, or a real GoRouter.
  ///
  /// IMPORTANT — mutual exclusivity: the nutrition-onboarding gate and the
  /// beauty-onboarding gate are evaluated as a single if/else-if chain, never
  /// as independent sequential ifs. Two independent ifs is what caused
  /// Finding #1's infinite redirect loop: a user with onboardingDone == false
  /// AND beautyOnboardingDone == false AND currentMode == AppMode.beauty
  /// would be bounced from /onboarding -> /onboarding/beauty (by the old
  /// third if) and then immediately back from /onboarding/beauty ->
  /// /onboarding (by the old first if), forever — go_router's own loop
  /// detection turns that into a thrown GoException.
  String? computeAkeliRedirect({
    required bool isAuthenticated,
    required bool isRecovery,
    required String currentPath,
    required bool hasProfile,
    required bool onboardingDone,
    required bool beautyOnboardingDone,
    required AppMode currentMode,
  }) {
    final isOnAuthPage = currentPath == AkeliRoutes.auth;
    final isOnResetPassword = currentPath == AkeliRoutes.resetPassword;
    final isOnOnboarding = currentPath == AkeliRoutes.onboarding;
    final isOnBeautyOnboarding = currentPath == AkeliRoutes.beautyOnboarding;
    final isOnPrivacyOrTerms =
        currentPath == AkeliRoutes.privacyPolicy || currentPath == AkeliRoutes.termsOfService;
    final isOnBeautyGatedRoute = _beautyGatedRoutes.contains(currentPath);

    if (isRecovery && !isOnResetPassword) {
      return AkeliRoutes.resetPassword;
    }

    if (!isAuthenticated && !isOnAuthPage && !isOnResetPassword) {
      return AkeliRoutes.auth;
    }

    if (isAuthenticated && isOnAuthPage) {
      return AkeliRoutes.home;
    }

    if (isAuthenticated && hasProfile) {
      // Privacy Policy / Terms of Service must always be reachable, regardless
      // of which onboarding stage the user is stuck on.
      if (isOnPrivacyOrTerms) {
        return null;
      }

      // --- Nutrition onboarding gate (always evaluated first) -----------------
      if (!onboardingDone) {
        if (!isOnOnboarding) {
          return AkeliRoutes.onboarding;
        }
        // Already on the nutrition onboarding page — stop here. Do NOT fall
        // through to the beauty gate below; that fall-through is exactly what
        // caused Finding #1's infinite loop.
        return null;
      }

      if (isOnOnboarding) {
        // Nutrition onboarding is done but the user is still viewing that page.
        return AkeliRoutes.home;
      }

      // --- Beauty onboarding gate (only reached once nutrition onboarding is
      // confirmed done) — keyed on EITHER the active mode OR the destination
      // route, so a user can't dodge it by switching currentMode to nutrition
      // and deep-linking straight into a beauty-gated route (Finding #3). ------
      final needsBeautyOnboarding =
          (currentMode == AppMode.beauty || isOnBeautyGatedRoute) && !beautyOnboardingDone;
      if (needsBeautyOnboarding) {
        if (!isOnBeautyOnboarding) {
          return AkeliRoutes.beautyOnboarding;
        }
        return null;
      }

      if (beautyOnboardingDone && isOnBeautyOnboarding) {
        return AkeliRoutes.home;
      }
    }

    return null;
  }
  ```

  Then **replace the entire body of the `redirect:` callback** inside `routerProvider` (currently lines 147–217, from `redirect: (context, state) {` through its matching `},`) with:

  ```dart
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isAuth = user != null;
      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.valueOrNull;
      final currentMode = ref.read(currentModeProvider);

      final authState = ref.read(authStreamProvider).valueOrNull;
      final isRecovery = authState?.event == AuthChangeEvent.passwordRecovery;

      appLogger.navigation(
        state.uri.path,
        '',
        reason: 'redirect check | isAuth: $isAuth | hasProfile: ${profile != null}',
      );

      final target = computeAkeliRedirect(
        isAuthenticated: isAuth,
        isRecovery: isRecovery,
        currentPath: state.uri.path,
        hasProfile: profile != null,
        onboardingDone: profile?.onboardingDone ?? false,
        beautyOnboardingDone: profile?.beautyOnboardingDone ?? false,
        currentMode: currentMode,
      );

      if (target != null) {
        appLogger.navigation(state.uri.path, target, reason: 'computeAkeliRedirect');
      }

      return target;
    },
  ```

  Do not touch anything else in the file at this step (the `routes: [ ... ]` list, including the duplicate `/onboarding` entry, is handled separately in Task 4).

- [ ] **Step 4: Replace the entire contents of `test/core/router_redirect_test.dart`** with the fixed version below (pure-function unit tests + a Riverpod-free integration test against a real `GoRouter`):

  ```dart
  // test/core/router_redirect_test.dart
  //
  // FINDING #1 (Critical) — router infinite redirect loop.
  // See docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md Area G.
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:go_router/go_router.dart';
  import 'package:akeli/core/router.dart';
  import 'package:akeli/providers/mode_provider.dart';

  void main() {
    group('computeAkeliRedirect — pure unit tests', () {
      test('unauthenticated user is redirected to /auth', () {
        final result = computeAkeliRedirect(
          isAuthenticated: false,
          isRecovery: false,
          currentPath: AkeliRoutes.home,
          hasProfile: false,
          onboardingDone: false,
          beautyOnboardingDone: false,
          currentMode: AppMode.nutrition,
        );
        expect(result, AkeliRoutes.auth);
      });

      test('password recovery event redirects to /reset-password regardless of path', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: true,
          currentPath: AkeliRoutes.home,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: true,
          currentMode: AppMode.nutrition,
        );
        expect(result, AkeliRoutes.resetPassword);
      });

      test('nutrition onboarding incomplete redirects to /onboarding', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.home,
          hasProfile: true,
          onboardingDone: false,
          beautyOnboardingDone: false,
          currentMode: AppMode.nutrition,
        );
        expect(result, AkeliRoutes.onboarding);
      });

      test('fully onboarded nutrition user on home gets no redirect', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.home,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: false,
          currentMode: AppMode.nutrition,
        );
        expect(result, isNull);
      });

      test('beauty user who completed both onboardings gets no redirect', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.home,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: true,
          currentMode: AppMode.beauty,
        );
        expect(result, isNull);
      });

      group('FINDING #1 regression — stale beauty mode + incomplete nutrition onboarding', () {
        const onboardingDone = false;
        const beautyOnboardingDone = false;
        const currentMode = AppMode.beauty;

        test('from /onboarding: stays put (no bounce to beauty onboarding)', () {
          final result = computeAkeliRedirect(
            isAuthenticated: true,
            isRecovery: false,
            currentPath: AkeliRoutes.onboarding,
            hasProfile: true,
            onboardingDone: onboardingDone,
            beautyOnboardingDone: beautyOnboardingDone,
            currentMode: currentMode,
          );
          expect(result, isNull);
        });

        test('from /onboarding/beauty: bounces back to /onboarding exactly once (no loop)', () {
          final result = computeAkeliRedirect(
            isAuthenticated: true,
            isRecovery: false,
            currentPath: AkeliRoutes.beautyOnboarding,
            hasProfile: true,
            onboardingDone: onboardingDone,
            beautyOnboardingDone: beautyOnboardingDone,
            currentMode: currentMode,
          );
          expect(result, AkeliRoutes.onboarding);
        });

        test('re-evaluating from /onboarding after the bounce is stable (proves termination)', () {
          final result = computeAkeliRedirect(
            isAuthenticated: true,
            isRecovery: false,
            currentPath: AkeliRoutes.onboarding,
            hasProfile: true,
            onboardingDone: onboardingDone,
            beautyOnboardingDone: beautyOnboardingDone,
            currentMode: currentMode,
          );
          expect(result, isNull);
        });
      });
    });

    group('Integration: GoRouter does not throw GoException (FINDING #1)', () {
      testWidgets(
        'beauty-mode user with incomplete nutrition onboarding does not crash with GoException',
        (tester) async {
          final router = GoRouter(
            initialLocation: AkeliRoutes.onboarding,
            redirect: (context, state) => computeAkeliRedirect(
              isAuthenticated: true,
              isRecovery: false,
              currentPath: state.uri.path,
              hasProfile: true,
              onboardingDone: false,
              beautyOnboardingDone: false,
              currentMode: AppMode.beauty,
            ),
            routes: [
              GoRoute(path: AkeliRoutes.onboarding, builder: (c, s) => const Scaffold(body: Text('onboarding'))),
              GoRoute(path: AkeliRoutes.beautyOnboarding, builder: (c, s) => const Scaffold(body: Text('beauty-onboarding'))),
              GoRoute(path: AkeliRoutes.home, builder: (c, s) => const Scaffold(body: Text('home'))),
            ],
          );

          await tester.pumpWidget(MaterialApp.router(routerConfig: router));
          await tester.pumpAndSettle();

          // Desired behavior: no crash. This is the same assertion that FAILED
          // against the pre-fix `_brokenRedirect` reproduction in Step 1 — it
          // now passes because computeAkeliRedirect resolves the loop with a
          // stable state.
          expect(tester.takeException(), isNull);
          expect(find.text('onboarding'), findsOneWidget);
        },
      );
    });
  }
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**

  ```
  flutter test test/core/router_redirect_test.dart
  ```

  Expected output: `00:0X +9: All tests passed!` (9 tests: 6 pure-unit + 3 in the "FINDING #1 regression" group, plus the 1 integration test = 10 total — count them after writing; all green, zero failures).

- [ ] **Step 6: Run `flutter analyze` to confirm no compile errors were introduced.**

  ```
  flutter analyze lib/core/router.dart
  ```

  Expected output: `No issues found!` (or only pre-existing, unrelated issues).

---

## Task 2: [Critical] Correct false "done" SDUI documentation + optional demo route

**Files:** `docs/03_v1_app_flutter/architecture_principes/SDUI_IMPLEMENTATION_STATUS.md`, `docs/03_v1_app_flutter/architecture_principes/SDUI_IMPLEMENTATION_AUDIT.md`, and (OPTIONAL sub-task only) `lib/core/router.dart`, `test/core/sdui_demo_route_test.dart` (new).

**Interfaces:** none (docs-only for the mandatory part; `AkeliRoutes.sduiDemo = '/sdui-demo'` for the optional part).

### Part A (MANDATORY) — fix the false claims

The SDUI subsystem (`layout_cache_service.dart`, `layout_fetch_service.dart`, `dynamic_layout_page.dart`, `widget_factory.dart`) is fully-coded and internally correct but has **zero references anywhere else in `lib/`** — it is never routed to. `SDUI_IMPLEMENTATION_STATUS.md` falsely claims router/main_shell integration is "✅ Done". `SDUI_IMPLEMENTATION_AUDIT.md` already correctly says "Integration Pending" — it only needs a dated confirmation that this is still true today.

- [ ] **Step 1: Edit `docs/03_v1_app_flutter/architecture_principes/SDUI_IMPLEMENTATION_STATUS.md`.**

  Replace the header block (currently lines 1–9):
  ```markdown
  # SDUI Implementation Status Report

  **Date**: 2024-01-01  
  **Branch**: beauty-mode  
  **Status**: ✅ **COMPLETE - Ready for Testing**

  ---

  ## 📊 Implementation Progress: 95% Complete
  ```
  with:
  ```markdown
  # SDUI Implementation Status Report

  **Date**: 2024-01-01 (original) — **corrected 2026-07-23, see banner below**
  **Branch**: beauty-mode / sdui
  **Status**: ⚠️ **SUPERSEDED — see correction below**

  > **2026-07-23 correction (Beauty Mode branch review, Area G):** The claims
  > below that router.dart and main_shell.dart integration are "✅ Done" are
  > **false as of 2026-07-23**. SDUI infrastructure (cache/fetch services,
  > widget factory, DynamicLayoutPage) is implemented but **not yet wired into
  > any route**. Beauty/Nutrition mode switching today is handled entirely via
  > native widget branching in each feature page (e.g. `NutritionPage` swaps
  > to `BeautyAnalyticsPage`), not via SDUI. `main_shell.dart` does have a mode
  > switcher, but it is a plain dialog (`showModeSelectorDialog`), not the
  > PopupMenu design described below, and it does not touch SDUI in any way.
  > The service-layer claims ("Core Services … Ready", "Widget Factory …
  > Ready") remain accurate — that code is genuinely well-built, it is simply
  > unreachable from the app today.

  ---

  ## 📊 Implementation Progress: 95% Complete (services only — routing integration is 0%, see correction above)
  ```

  Replace the "Router Configuration" subsection (currently lines 16–19):
  ```markdown
  #### 2. Router Configuration
  ✅ **Done** - See `lib/core/router.dart`
  - `/home` → Nutrition mode (DynamicLayoutPage)
  - `/beauty` → Beauty mode (DynamicLayoutPage)
  ```
  with:
  ```markdown
  #### 2. Router Configuration
  ⚠️ **NOT done, as of 2026-07-23** — `lib/core/router.dart` has no route that
  builds `DynamicLayoutPage`. `/home` renders `HomePage` (native widget); there
  is no `/beauty` route at all (Beauty mode instead uses `/beauty-analytics`,
  rendering `BeautyAnalyticsPage`, a native widget). See Task 2 of
  `docs/superpowers/plans/2026-07-23-beauty-fix-g-core-infra.md` for the
  optional `/sdui-demo` route that finally exercises this code.
  ```

  Replace the "Mode Switcher UI" subsection (currently lines 27–32):
  ```markdown
  #### 5. Mode Switcher UI ⭐ **NEW**
  ✅ **Complete** - Updated `lib/shared/widgets/main_shell.dart`
  - Added mode indicator in AppBar title
  - PopupMenu button to switch between Nutrition and Beauty
  - Visual feedback showing current active mode
  - Color-coded badges (Primary for Nutrition, Secondary for Beauty)
  ```
  with:
  ```markdown
  #### 5. Mode Switcher UI ⭐ **NEW**
  ⚠️ **Partially accurate, corrected 2026-07-23** - `lib/shared/widgets/main_shell.dart`
  does have a mode indicator in the AppBar `actions`, but it opens
  `showModeSelectorDialog` (a full-screen `AlertDialog`, see
  `lib/widgets/mode_selector.dart`), not a PopupMenu. It is unrelated to SDUI —
  it just flips the `currentModeProvider` Riverpod state, which native-widget
  pages branch on directly.
  ```

  Replace the "File Reference" table rows for `router.dart` and (implicitly) the future-work row for `main_shell.dart` (currently lines 176–178 and 190–194):
  ```markdown
  lib/main.dart                              ✅ Hive initialization
  lib/core/router.dart                       ✅ Added beauty route + DynamicLayoutPage
  supabase/migrations/*_create_sdui_layouts.sql ✅ Database schema
  ```
  with:
  ```markdown
  lib/main.dart                              ✅ Hive initialization
  lib/core/router.dart                       ⚠️ NOT wired to DynamicLayoutPage as of 2026-07-23 (see correction banner)
  supabase/migrations/*_create_sdui_layouts.sql ✅ Database schema (confirm table still matches — not re-verified in this pass)
  ```

- [ ] **Step 2: Edit `docs/03_v1_app_flutter/architecture_principes/SDUI_IMPLEMENTATION_AUDIT.md`.**

  Insert a verification addendum directly after the header block (currently lines 1–6, ending `---`):
  ```markdown
  # SDUI Mode Switching Implementation Audit
  **Date**: 2026-01-09  
  **Branch**: beauty-mode  
  **Status**: Foundation Complete, Integration Pending

  ---

  > **2026-07-23 verification addendum (Beauty Mode branch review, Area G):**
  > Re-checked against the current `sdui` branch. The assessment below is
  > **still accurate today** — SDUI infrastructure is implemented but not yet
  > wired into any route; Beauty/Nutrition mode switching is currently
  > handled via native widget branching (e.g. `NutritionPage` swaps to
  > `BeautyAnalyticsPage`), not SDUI. The one place this document is
  > misleading is the Conclusion's "production-ready" language — that refers
  > only to the internal service code (`layout_cache_service.dart`,
  > `layout_fetch_service.dart`, `widget_factory.dart`,
  > `dynamic_layout_page.dart`), not to the app being ready to ship on SDUI.
  > See `docs/superpowers/plans/2026-07-23-beauty-fix-g-core-infra.md` Task 2.
  ```

  Then edit the Conclusion section (currently lines 540–544):
  ```markdown
  ## Conclusion

  **Overall Status**: 🟡 **Ready for Integration Phase**

  The SDUI foundation is solid and production-ready. All critical services are implemented with proper error handling, caching, and offline support. The main work ahead is **integration**, not invention.
  ```
  with:
  ```markdown
  ## Conclusion

  **Overall Status**: 🟡 **Ready for Integration Phase** (still true as of 2026-07-23 — see verification addendum above)

  The SDUI **service layer** (cache, fetch, widget factory, DynamicLayoutPage) is solid and production-ready in isolation. All critical services are implemented with proper error handling, caching, and offline support. **No route in the app renders this layer today** — the main work ahead is genuinely **integration**, not invention, but "integration" has not started.
  ```

- [ ] **Step 3 (OPTIONAL — skip if time-constrained): write a failing test for a new `/sdui-demo` route.**

  Create `test/core/sdui_demo_route_test.dart`:

  ```dart
  // test/core/sdui_demo_route_test.dart
  //
  // FINDING #2 (Critical, optional sub-task) — SDUI is dead code. This adds a
  // brand-new, additive `/sdui-demo` route (no existing route is touched or
  // replaced) so the subsystem is finally reachable, and proves it renders.
  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:hive/hive.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:akeli/core/sdui/services/layout_cache_service.dart';
  import 'package:akeli/core/sdui/widgets/dynamic_layout_page.dart';

  void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});

      // Avoid the path_provider platform channel: point Hive at a plain temp dir.
      final tempDir = await Directory.systemTemp.createTemp('akeli_sdui_demo_test');
      Hive.init(tempDir.path);
      await Hive.openBox('layout_cache');
      await Hive.openBox('mode_state');

      // DynamicLayoutPage's LayoutFetchService reads Supabase.instance.client
      // eagerly in a field initializer — it must be initialized even though
      // this test never reaches the network path (cache hit short-circuits it).
      await Supabase.initialize(
        url: 'https://sdui-demo-route-test.supabase.co',
        anonKey: 'test-anon-key-not-real',
      );

      // Pre-seed the cache so fetchLayout() resolves from Hive only — no real
      // network call is made, keeping this test fast and deterministic.
      await LayoutCacheService().cacheLayout(
        mode: 'nutrition',
        layoutId: 'demo-route-test-layout',
        layoutJson: {
          'components': [
            {'type': 'hero_banner', 'config': {'title': 'Demo', 'subtitle': 'SDUI'}},
          ],
        },
      );
    });

    testWidgets('a standalone GoRouter rendering /sdui-demo shows DynamicLayoutPage without throwing', (tester) async {
      final router = GoRouter(
        initialLocation: '/sdui-demo',
        routes: [
          GoRoute(
            path: '/sdui-demo',
            builder: (context, state) => const DynamicLayoutPage(mode: 'nutrition'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(DynamicLayoutPage), findsOneWidget);
    });
  }
  ```

- [ ] **Step 4 (OPTIONAL): run the test and confirm it fails (the route/import target doesn't exist as production wiring yet — the test itself compiles fine since it builds its own standalone `GoRouter`, so run it first to establish the DynamicLayoutPage-mounts-cleanly baseline before touching router.dart).**

  ```
  flutter test test/core/sdui_demo_route_test.dart
  ```

  Expected: passes on its own (it doesn't depend on `lib/core/router.dart` yet) — this step is really about confirming `DynamicLayoutPage` itself mounts cleanly in isolation before wiring the real route in Step 5. If it fails here, do not proceed to Step 5 until `DynamicLayoutPage` mounts cleanly standalone.

- [ ] **Step 5 (OPTIONAL): wire `/sdui-demo` into `lib/core/router.dart` as a brand-new route — do not replace or modify any existing route.**

  Add to the `AkeliRoutes` class (anywhere inside the class body, e.g. directly under `static const resetPassword = "/reset-password";`):
  ```dart
    static const sduiDemo = '/sdui-demo';
  ```

  Add the import at the top of `lib/core/router.dart`, alongside the other feature imports:
  ```dart
  import 'sdui/widgets/dynamic_layout_page.dart';
  ```

  Add a new top-level `GoRoute` entry inside the `routes: [ ... ]` list of `routerProvider` (anywhere outside the `ShellRoute`, e.g. directly after the `dmChat` `GoRoute`):
  ```dart
        GoRoute(
          path: AkeliRoutes.sduiDemo,
          builder: (context, state) => const DynamicLayoutPage(mode: 'nutrition'),
        ),
  ```

  Note: this route is intentionally reachable outside the normal onboarding-gated flow so it can be smoke-tested manually (`flutter run` then navigate to `/sdui-demo`); it is not linked from any UI.

- [ ] **Step 6 (OPTIONAL): re-run the demo-route test to confirm nothing regressed.**

  ```
  flutter test test/core/sdui_demo_route_test.dart
  ```

  Expected output: `00:0X +1: All tests passed!`

---

## Task 3: [High] Beauty-onboarding guard keyed to route, not just mode

**Files:** `lib/core/router.dart` (already fixed in Task 1), `test/core/router_redirect_test.dart` (extend).

**Interfaces:** reuses `computeAkeliRedirect` and the `_beautyGatedRoutes` constant from Task 1 — this task adds test coverage and a mutation check proving that coverage is real.

### Background

Task 1's `computeAkeliRedirect` already includes the fix for this finding (the `needsBeautyOnboarding` line reads `(currentMode == AppMode.beauty || isOnBeautyGatedRoute) && !beautyOnboardingDone`), because the bug and its fix live in the exact same conditional. This task's job is to add the specific regression tests for **this** finding (a user with `currentMode == AppMode.nutrition` navigating directly to `/beauty-analytics`) and prove, via a temporary mutation, that those tests would actually catch a regression of this specific behavior.

- [ ] **Step 1: Confirm the route-based check is present.**

  Read `lib/core/router.dart` and confirm it contains (from Task 1):
  ```dart
  const _beautyGatedRoutes = <String>{
    AkeliRoutes.beautyAnalytics,
  };
  ```
  and, inside `computeAkeliRedirect`:
  ```dart
      final needsBeautyOnboarding =
          (currentMode == AppMode.beauty || isOnBeautyGatedRoute) && !beautyOnboardingDone;
  ```
  If Task 1 has not landed yet, stop and complete Task 1 first.

- [ ] **Step 2: Add the new test group to `test/core/router_redirect_test.dart`.**

  Insert this new `group` immediately after the `'FINDING #1 regression — stale beauty mode + incomplete nutrition onboarding'` group and before the `'Integration: GoRouter does not throw GoException (FINDING #1)'` group:

  ```dart
    group('FINDING #3 regression — beauty gate keyed to destination route, not just currentMode', () {
      test('nutrition-mode user cannot bypass the gate by deep-linking to /beauty-analytics', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyAnalytics,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: false,
          currentMode: AppMode.nutrition,
        );
        expect(result, AkeliRoutes.beautyOnboarding);
      });

      test('same deep link is allowed once beauty onboarding is actually done', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyAnalytics,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: true,
          currentMode: AppMode.nutrition,
        );
        expect(result, isNull);
      });

      test('gate is not restricted to the nutrition/beauty binary — health mode is also gated by route', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyAnalytics,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: false,
          currentMode: AppMode.health,
        );
        expect(result, AkeliRoutes.beautyOnboarding);
      });
    });
  ```

- [ ] **Step 3: Run the tests and confirm they pass (they should, immediately — Task 1 already implemented the fix).**

  ```
  flutter test test/core/router_redirect_test.dart
  ```

  Expected output: `00:0X +13: All tests passed!` (10 from Task 1 + 3 new).

- [ ] **Step 4: Prove the new tests are meaningful via a temporary mutation.**

  In `lib/core/router.dart`, temporarily change:
  ```dart
      final needsBeautyOnboarding =
          (currentMode == AppMode.beauty || isOnBeautyGatedRoute) && !beautyOnboardingDone;
  ```
  to:
  ```dart
      final needsBeautyOnboarding =
          currentMode == AppMode.beauty && !beautyOnboardingDone;
  ```
  (i.e. temporarily remove the `|| isOnBeautyGatedRoute` clause, simulating the pre-fix bug for this specific finding).

  Re-run:
  ```
  flutter test test/core/router_redirect_test.dart
  ```

  Expected output: the **new FINDING #3 tests fail** (2 of the 3: the "cannot bypass" and "health mode" cases now return `null` instead of `AkeliRoutes.beautyOnboarding`), while everything else still passes. This proves the tests genuinely detect a regression of this finding.

- [ ] **Step 5: Revert the temporary mutation exactly.**

  Restore:
  ```dart
      final needsBeautyOnboarding =
          (currentMode == AppMode.beauty || isOnBeautyGatedRoute) && !beautyOnboardingDone;
  ```

  Re-run:
  ```
  flutter test test/core/router_redirect_test.dart
  ```

  Expected output: `00:0X +13: All tests passed!` again.

---

## Task 4: [Medium] Remove duplicate `GoRoute` registration for `/onboarding`

**Files:** `lib/core/router.dart`, `test/core/router_duplicate_route_test.dart` (new).

**Interfaces:** none (source-hygiene fix).

### Background

`lib/core/router.dart`'s `routes: [ ... ]` list registers `AkeliRoutes.onboarding` **twice** — once near the top (grouped with `beautyOnboarding`, `auth`, structurally consistent with Task 1's redirect fix), and again immediately after the `resetPassword` route (a copy-paste artifact, harmless today only because go_router takes the first match):

```dart
      GoRoute(
        path: AkeliRoutes.onboarding,          // KEEP — first occurrence
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.beautyOnboarding,
        builder: (context, state) => const BeautyOnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AkeliRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AkeliRoutes.onboarding,          // REMOVE — duplicate
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.recipeDetail,
        ...
```

- [ ] **Step 1: Write a failing test.**

  Create `test/core/router_duplicate_route_test.dart`:

  ```dart
  // test/core/router_duplicate_route_test.dart
  //
  // FINDING #4 (Medium) — duplicate GoRoute registration for /onboarding.
  // This is a source-hygiene defect (go_router takes the first match, so
  // behavior is unaffected), so it's verified with a direct source check
  // rather than a runtime GoRouter test.
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    test('lib/core/router.dart registers AkeliRoutes.onboarding exactly once', () {
      final source = File('lib/core/router.dart').readAsStringSync();
      final matches = 'path: AkeliRoutes.onboarding,'.allMatches(source).length;
      expect(
        matches,
        1,
        reason: 'Expected exactly one "path: AkeliRoutes.onboarding," GoRoute registration, found $matches',
      );
    });

    test('lib/core/router.dart still registers AkeliRoutes.beautyOnboarding exactly once (sanity check)', () {
      final source = File('lib/core/router.dart').readAsStringSync();
      final matches = 'path: AkeliRoutes.beautyOnboarding,'.allMatches(source).length;
      expect(matches, 1);
    });
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails against current code.**

  ```
  flutter test test/core/router_duplicate_route_test.dart
  ```

  Expected output: the first test **fails** — `matches` is `2`, not `1`.

- [ ] **Step 3: Remove the duplicate block.**

  In `lib/core/router.dart`, find this exact text (the `resetPassword` route immediately followed by the duplicate `onboarding` route, immediately followed by the start of the `recipeDetail` route):
  ```dart
      GoRoute(
        path: AkeliRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AkeliRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.recipeDetail,
  ```
  and replace it with:
  ```dart
      GoRoute(
        path: AkeliRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AkeliRoutes.recipeDetail,
  ```
  (i.e. delete the 4-line duplicate `GoRoute(path: AkeliRoutes.onboarding, ...)` block, keeping the first occurrence near the top of the routes list — the one grouped with `beautyOnboarding`, which is structurally consistent with Task 1's redirect fix).

- [ ] **Step 4: Run the test again and confirm it passes.**

  ```
  flutter test test/core/router_duplicate_route_test.dart
  ```

  Expected output: `00:0X +2: All tests passed!`

---

## Task 5: [Medium] `main_shell.dart` hardcoded tab labels + zero logging

**Files:** `lib/shared/widgets/main_shell.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `test/shared/widgets/main_shell_test.dart` (new).

**Interfaces:**
```dart
List<String> mainShellTabLabels(AppLocalizations l10n, bool isBeauty);
```

### Background

`lib/shared/widgets/main_shell.dart` line 47 hardcodes `'Routines'`/`'Remèdes'` in the same array as three properly-localized `l10n.*` values:
```dart
    final tabLabels = isBeauty
        ? [l10n.navHome, 'Routines', 'Remèdes', l10n.navCommunity]
        : [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity];
```
The file also has zero `appLogger` calls despite substantial edits (mode-aware tabs, mode badge, `showModeSelectorDialog` tap).

- [ ] **Step 1: Add ARB keys.**

  In `lib/l10n/app_en.arb`, find the last key-value pair (currently ending with):
  ```json
    "onboardingValidationAgeMax": "Age must be at most 100",
    "@onboardingValidationAgeMax": {}
  ```
  and replace it with:
  ```json
    "onboardingValidationAgeMax": "Age must be at most 100",
    "@onboardingValidationAgeMax": {},
    "mainShellTabRoutines": "Routines",
    "@mainShellTabRoutines": {},
    "mainShellTabRemedies": "Remedies",
    "@mainShellTabRemedies": {}
  ```

  In `lib/l10n/app_fr.arb`, find the last key-value pair (currently ending with):
  ```json
    "onboardingValidationAgeMax": "L'âge doit être d'au plus 100 ans",
    "@onboardingValidationAgeMax": {}
  ```
  and replace it with:
  ```json
    "onboardingValidationAgeMax": "L'âge doit être d'au plus 100 ans",
    "@onboardingValidationAgeMax": {},
    "mainShellTabRoutines": "Routines",
    "@mainShellTabRoutines": {},
    "mainShellTabRemedies": "Remèdes",
    "@mainShellTabRemedies": {}
  ```

- [ ] **Step 2: Regenerate localizations.**

  ```
  flutter gen-l10n
  ```

  Expected output: no errors; `lib/l10n/app_localizations_en.dart` and `lib/l10n/app_localizations_fr.dart` now contain `mainShellTabRoutines`/`mainShellTabRemedies` getters.

- [ ] **Step 3: Write a failing test.**

  Create `test/shared/widgets/main_shell_test.dart`:

  ```dart
  // test/shared/widgets/main_shell_test.dart
  //
  // FINDING #5 (Medium) — main_shell.dart:47 hardcodes 'Routines'/'Remèdes'.
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/l10n/app_localizations_en.dart';
  import 'package:akeli/l10n/app_localizations_fr.dart';
  import 'package:akeli/shared/widgets/main_shell.dart';

  void main() {
    group('mainShellTabLabels (Finding #5)', () {
      test('beauty-mode tab labels are fully localized in English — no hardcoded French', () {
        final l10n = AppLocalizationsEn();
        final labels = mainShellTabLabels(l10n, true);
        expect(labels, [l10n.navHome, l10n.mainShellTabRoutines, l10n.mainShellTabRemedies, l10n.navCommunity]);
        expect(labels, isNot(contains('Routines')));
        expect(labels, isNot(contains('Remèdes')));
      });

      test('beauty-mode tab labels are fully localized in French', () {
        final l10n = AppLocalizationsFr();
        final labels = mainShellTabLabels(l10n, true);
        expect(labels, [l10n.navHome, l10n.mainShellTabRoutines, l10n.mainShellTabRemedies, l10n.navCommunity]);
      });

      test('nutrition-mode tab labels are unaffected', () {
        final l10n = AppLocalizationsEn();
        final labels = mainShellTabLabels(l10n, false);
        expect(labels, [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity]);
      });
    });
  }
  ```

- [ ] **Step 4: Run the test and confirm it fails against current code.**

  ```
  flutter test test/shared/widgets/main_shell_test.dart
  ```

  Expected output: compile error — `mainShellTabLabels` is not defined in `package:akeli/shared/widgets/main_shell.dart`.

- [ ] **Step 5: Implement the fix in `lib/shared/widgets/main_shell.dart`.**

  Add the logger import alongside the existing imports (at the top of the file, after `import '../../l10n/app_localizations.dart';`):
  ```dart
  import '../../core/logger.dart';
  ```

  Add a top-level (file-scope, not class-scope — `MainShell`'s constructor is `const`, so a class-level logger field would break constness) logger instance and the new pure helper function, placed directly after the imports and before `class MainShell extends ConsumerWidget {`:
  ```dart
  final _logger = appLogger;

  /// Pure, testable tab-label computation — see test/shared/widgets/main_shell_test.dart.
  List<String> mainShellTabLabels(AppLocalizations l10n, bool isBeauty) {
    return isBeauty
        ? [l10n.navHome, l10n.mainShellTabRoutines, l10n.mainShellTabRemedies, l10n.navCommunity]
        : [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity];
  }
  ```

  Replace the hardcoded `tabLabels` assignment (currently):
  ```dart
      final tabLabels = isBeauty
          ? [l10n.navHome, 'Routines', 'Remèdes', l10n.navCommunity]
          : [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity];
  ```
  with:
  ```dart
      _logger.provider('MainShell build() | mode: ${mode.name} | isBeauty: $isBeauty');
      final tabLabels = mainShellTabLabels(l10n, isBeauty);
  ```

  Replace the mode-badge tap handler (currently):
  ```dart
                return GestureDetector(
                  onTap: () => showModeSelectorDialog(context, ref),
  ```
  with:
  ```dart
                return GestureDetector(
                  onTap: () {
                    _logger.userAction('Mode switcher tapped', screen: 'MainShell');
                    showModeSelectorDialog(context, ref);
                  },
  ```

- [ ] **Step 6: Run the test again and confirm it passes.**

  ```
  flutter test test/shared/widgets/main_shell_test.dart
  ```

  Expected output: `00:0X +3: All tests passed!`

- [ ] **Step 7: Run `flutter analyze` to confirm no compile errors were introduced.**

  ```
  flutter analyze lib/shared/widgets/main_shell.dart
  ```

  Expected output: `No issues found!`

---

## Task 6: [Medium/High, cross-plan] Thread Area F's color-set provider through `theme.dart`

**Files:** `lib/core/theme.dart`, `lib/main.dart`, `test/core/theme_test.dart` (extend).

**Interfaces:**
```dart
Color getAppModeColor(AppMode mode, {Color? customPrimary});
ThemeData buildLightTheme([AppMode mode = AppMode.nutrition, Color? customPrimary]);
ThemeData buildDarkTheme([AppMode mode = AppMode.nutrition, Color? customPrimary]);
```

### Part A — `theme.dart` signature changes (independent of Area F, do this now)

- [ ] **Step 1: Add failing tests to `test/core/theme_test.dart`.**

  Add this import to the top of the existing file:
  ```dart
  import 'package:akeli/providers/mode_provider.dart';
  ```

  Add these new `group`s inside `void main() { ... }`, after the existing `group('AkeliColors', ...)` block:
  ```dart
    group('getAppModeColor customPrimary override (Finding #6 — Area F dependency)', () {
      test('returns customPrimary when provided, overriding the mode default', () {
        const custom = Color(0xFF123456);
        expect(getAppModeColor(AppMode.beauty, customPrimary: custom), custom);
      });

      test('falls back to the mode default when customPrimary is null', () {
        expect(getAppModeColor(AppMode.beauty), const Color(0xFF8A3B58));
      });
    });

    group('buildLightTheme / buildDarkTheme customPrimary override', () {
      test('buildLightTheme colorScheme.primary uses customPrimary when provided', () {
        const custom = Color(0xFF123456);
        final theme = buildLightTheme(AppMode.nutrition, custom);
        expect(theme.colorScheme.primary, custom);
      });

      test('buildDarkTheme colorScheme.primary uses customPrimary when provided', () {
        const custom = Color(0xFF123456);
        final theme = buildDarkTheme(AppMode.nutrition, custom);
        expect(theme.colorScheme.primary, custom);
      });
    });
  ```

- [ ] **Step 2: Run the tests and confirm they fail against current code.**

  ```
  flutter test test/core/theme_test.dart
  ```

  Expected output: compile error — `getAppModeColor`/`buildLightTheme`/`buildDarkTheme` don't accept a `customPrimary` argument yet.

- [ ] **Step 3: Implement the signature changes in `lib/core/theme.dart`.**

  Replace:
  ```dart
  Color getAppModeColor(AppMode mode) {
    switch (mode) {
      case AppMode.nutrition:
        return const Color(0xFF00504A);
      case AppMode.beauty:
        return const Color(0xFF8A3B58);
      case AppMode.health:
        return const Color(0xFF2196F3);
      case AppMode.sport:
        return const Color(0xFFFF9800);
      case AppMode.family:
        return const Color(0xFF9C27B0);
    }
  }
  ```
  with:
  ```dart
  Color getAppModeColor(AppMode mode, {Color? customPrimary}) {
    if (customPrimary != null) return customPrimary;
    switch (mode) {
      case AppMode.nutrition:
        return const Color(0xFF00504A);
      case AppMode.beauty:
        return const Color(0xFF8A3B58);
      case AppMode.health:
        return const Color(0xFF2196F3);
      case AppMode.sport:
        return const Color(0xFFFF9800);
      case AppMode.family:
        return const Color(0xFF9C27B0);
    }
  }
  ```

  Replace:
  ```dart
  ThemeData buildLightTheme([AppMode mode = AppMode.nutrition]) {
    final primaryColor = getAppModeColor(mode);
  ```
  with:
  ```dart
  ThemeData buildLightTheme([AppMode mode = AppMode.nutrition, Color? customPrimary]) {
    final primaryColor = getAppModeColor(mode, customPrimary: customPrimary);
  ```

  Replace:
  ```dart
  ThemeData buildDarkTheme([AppMode mode = AppMode.nutrition]) {
    final primaryColor = getAppModeColor(mode);
  ```
  with:
  ```dart
  ThemeData buildDarkTheme([AppMode mode = AppMode.nutrition, Color? customPrimary]) {
    final primaryColor = getAppModeColor(mode, customPrimary: customPrimary);
  ```

  All 15 existing call sites of `getAppModeColor(mode)` and both call sites of `buildLightTheme(currentMode)`/`buildDarkTheme(currentMode)` (in `lib/main.dart`) remain valid unchanged, since the new parameters are optional and additive.

- [ ] **Step 4: Run the tests again and confirm they pass.**

  ```
  flutter test test/core/theme_test.dart
  ```

  Expected output: `00:0X +9: All tests passed!` (5 original `AkeliColors` tests + 4 new).

- [ ] **Step 5: Run `flutter analyze` on every file that calls these functions, to confirm nothing broke.**

  ```
  flutter analyze lib/core/theme.dart lib/main.dart lib/widgets/mode_selector.dart lib/shared/widgets/main_shell.dart
  ```

  Expected output: `No issues found!` (or only pre-existing, unrelated issues).

### Part B — wire `main.dart` to Area F's color-set provider (BLOCKED until Area F's plan lands)

- [ ] **Step 0 — dependency gate (do this before writing any code in this part):**

  Check whether `lib/providers/color_set_provider.dart` exists:
  ```
  test -f lib/providers/color_set_provider.dart && echo EXISTS || echo MISSING
  ```

  - If **MISSING**: also check whether `docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md` exists. If it does, read it for the exact provider name/type before proceeding. If neither exists, **STOP** — do not fabricate the provider or touch `lib/main.dart`. Mark this part "blocked: waiting on Area F" and move on; Part A above is unaffected and should already be complete.
  - If it **EXISTS**: open it and confirm the exported provider's name and the shape of the value it exposes (this plan assumes, based on the pre-existing `lib/shared/widgets/color_set_modal.dart`'s `ColorSetPreset` class — which has a `Color primary` field — that Area F most likely reused that type, e.g. `final colorSetProvider = StateProvider<ColorSetPreset?>((ref) => null);` or a `NotifierProvider` of the same value type). **If the actual name/type differs from `colorSetProvider` / `ColorSetPreset.primary` used below, substitute the real names in every snippet in this part before writing any code — do not skip this reconciliation.**

- [ ] **Step 1: Edit `lib/main.dart`.**

  Add the import (adjust the path/symbol if Step 0 found a different provider name or file location):
  ```dart
  import 'providers/color_set_provider.dart';
  ```

  Replace:
  ```dart
      final router = ref.watch(routerProvider);
      final locale = ref.watch(localeProvider);
      final currentMode = ref.watch(currentModeProvider);

      return MaterialApp.router(
        title: 'Akeli',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(currentMode),
        darkTheme: buildDarkTheme(currentMode),
  ```
  with (adjust `colorSetProvider`/`?.primary` if Step 0 found different names):
  ```dart
      final router = ref.watch(routerProvider);
      final locale = ref.watch(localeProvider);
      final currentMode = ref.watch(currentModeProvider);
      final customColorSet = ref.watch(colorSetProvider);
      final customPrimary = customColorSet?.primary;
      appLogger.provider(
        'AkeliApp.build() | currentMode: ${currentMode.name} | hasCustomColor: ${customPrimary != null}',
      );

      return MaterialApp.router(
        title: 'Akeli',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(currentMode, customPrimary),
        darkTheme: buildDarkTheme(currentMode, customPrimary),
  ```

- [ ] **Step 2: Run analyze to confirm it compiles against the real Area F provider.**

  ```
  flutter analyze lib/main.dart
  ```

  Expected output: `No issues found!`

- [ ] **Step 3: Manual smoke test (no automated test for this part — it's a straight-line wiring change already covered by Part A's unit tests on the theme functions themselves).**

  ```
  flutter run -d windows
  ```

  Confirm the app launches and the theme still renders (teal for nutrition mode) with no `customPrimary` set yet (Area F's UI for actually setting a custom color set is out of scope for Area G).

---

## Task 7: [Low] `buildDarkTheme()` missing component themes

**Files:** `lib/core/theme.dart`, `test/core/theme_test.dart` (extend).

**Interfaces:** none new — extends the `ThemeData` returned by `buildDarkTheme` with 5 additional component-theme fields already present in `buildLightTheme`.

**Depends on:** Task 6 Part A (this task edits the same `buildDarkTheme` function; do Task 6 Part A first).

### Background

`buildDarkTheme()` (currently lines 273–311) only sets `colorScheme`, `scaffoldBackgroundColor`, `textTheme`, `appBarTheme`, and `cardTheme`. `buildLightTheme()` additionally sets `filledButtonTheme`, `outlinedButtonTheme`, `bottomNavigationBarTheme`, `chipTheme`, and `progressIndicatorTheme` — none of which `buildDarkTheme()` defines, so dark-mode buttons/nav bar/chips/progress indicators silently fall back to Material 3 defaults instead of the app's mode-reactive styling.

- [ ] **Step 1: Add failing tests to `test/core/theme_test.dart`.**

  Add this new `group`, after the groups added in Task 6:
  ```dart
    group('buildDarkTheme component theme parity (Finding #7)', () {
      test('defines filledButtonTheme with mode-reactive pill-shaped full-width style', () {
        final theme = buildDarkTheme(AppMode.beauty);
        final style = theme.filledButtonTheme.style;
        expect(style, isNotNull, reason: 'buildDarkTheme must define filledButtonTheme like buildLightTheme does');
        expect(style!.minimumSize?.resolve(<WidgetState>{}), const Size(double.infinity, 52));
        expect(style.backgroundColor?.resolve(<WidgetState>{}), getAppModeColor(AppMode.beauty));
      });

      test('defines outlinedButtonTheme with mode-reactive border color', () {
        final theme = buildDarkTheme(AppMode.beauty);
        final style = theme.outlinedButtonTheme.style;
        expect(style, isNotNull);
        expect(style!.side?.resolve(<WidgetState>{})?.color, getAppModeColor(AppMode.beauty));
      });

      test('defines bottomNavigationBarTheme with dark surface + mode-reactive selected color', () {
        final theme = buildDarkTheme(AppMode.beauty);
        expect(theme.bottomNavigationBarTheme.backgroundColor, AkeliColors.surfaceDark);
        expect(theme.bottomNavigationBarTheme.selectedItemColor, getAppModeColor(AppMode.beauty));
      });

      test('defines chipTheme with a dark background', () {
        final theme = buildDarkTheme(AppMode.nutrition);
        expect(theme.chipTheme.backgroundColor, AkeliColors.backgroundDark);
      });

      test('defines progressIndicatorTheme with mode-reactive color', () {
        final theme = buildDarkTheme(AppMode.beauty);
        expect(theme.progressIndicatorTheme.color, getAppModeColor(AppMode.beauty));
      });
    });
  ```

- [ ] **Step 2: Run the tests and confirm they fail against current code.**

  ```
  flutter test test/core/theme_test.dart
  ```

  Expected output: the 5 new tests **fail** — `buildDarkTheme()`'s `filledButtonTheme.style`, `outlinedButtonTheme.style`, `bottomNavigationBarTheme.backgroundColor`, `chipTheme.backgroundColor`, and `progressIndicatorTheme.color` are all `null` by default (Material 3 has no built-in dark styling matching these expectations).

- [ ] **Step 3: Implement the fix in `lib/core/theme.dart`.**

  Replace the `buildDarkTheme` function's `ThemeData(...)` body (currently):
  ```dart
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AkeliColors.backgroundDark,
      textTheme: _buildTextTheme(AkeliColors.textPrimaryDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AkeliColors.backgroundDark,
        foregroundColor: AkeliColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AkeliColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AkeliColors.surfaceDark,
        elevation: AkeliElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.md),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
  ```
  with:
  ```dart
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AkeliColors.backgroundDark,
      textTheme: _buildTextTheme(AkeliColors.textPrimaryDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AkeliColors.backgroundDark,
        foregroundColor: AkeliColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AkeliColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AkeliColors.surfaceDark,
        elevation: AkeliElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.md),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.pill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.pill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AkeliColors.surfaceDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: AkeliColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: AkeliElevation.high,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AkeliColors.backgroundDark,
        selectedColor: primaryColor.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AkeliColors.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
          side: BorderSide(color: AkeliColors.outline.withValues(alpha: 0.4)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
  ```

- [ ] **Step 4: Run the tests again and confirm they pass.**

  ```
  flutter test test/core/theme_test.dart
  ```

  Expected output: `00:0X +14: All tests passed!` (9 from Task 6 Part A + 5 new).

- [ ] **Step 5: Run `flutter analyze` to confirm no compile errors were introduced.**

  ```
  flutter analyze lib/core/theme.dart
  ```

  Expected output: `No issues found!`

---

## Task 8: [Low] `dynamic_layout_page.dart` hardcoded English error strings

**Files:** `lib/core/sdui/widgets/dynamic_layout_page.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `test/core/sdui_dynamic_layout_page_l10n_test.dart` (new).

**Interfaces:** none new (l10n getters generated by `flutter gen-l10n`: `dynamicLayoutUnableToLoad`, `dynamicLayoutUnknownError`, `dynamicLayoutTryAgain`, `dynamicLayoutNoContentForMode(String mode)`, `dynamicLayoutCheckBackLater`).

**Sequencing note:** this task appends ARB keys after Task 5's — run Task 5 before this task.

- [ ] **Step 1: Add ARB keys.**

  In `lib/l10n/app_en.arb`, find the last key-value pair (now ending with Task 5's addition):
  ```json
    "mainShellTabRemedies": "Remedies",
    "@mainShellTabRemedies": {}
  ```
  and replace it with:
  ```json
    "mainShellTabRemedies": "Remedies",
    "@mainShellTabRemedies": {},
    "dynamicLayoutUnableToLoad": "Unable to load layout",
    "@dynamicLayoutUnableToLoad": {},
    "dynamicLayoutUnknownError": "Unknown error",
    "@dynamicLayoutUnknownError": {},
    "dynamicLayoutTryAgain": "Try Again",
    "@dynamicLayoutTryAgain": {},
    "dynamicLayoutNoContentForMode": "No content for {mode} mode",
    "@dynamicLayoutNoContentForMode": {
      "placeholders": {
        "mode": { "type": "String" }
      }
    },
    "dynamicLayoutCheckBackLater": "Check back later for updates",
    "@dynamicLayoutCheckBackLater": {}
  ```

  In `lib/l10n/app_fr.arb`, find the last key-value pair (now ending with Task 5's addition):
  ```json
    "mainShellTabRemedies": "Remèdes",
    "@mainShellTabRemedies": {}
  ```
  and replace it with:
  ```json
    "mainShellTabRemedies": "Remèdes",
    "@mainShellTabRemedies": {},
    "dynamicLayoutUnableToLoad": "Impossible de charger la mise en page",
    "@dynamicLayoutUnableToLoad": {},
    "dynamicLayoutUnknownError": "Erreur inconnue",
    "@dynamicLayoutUnknownError": {},
    "dynamicLayoutTryAgain": "Réessayer",
    "@dynamicLayoutTryAgain": {},
    "dynamicLayoutNoContentForMode": "Aucun contenu pour le mode {mode}",
    "@dynamicLayoutNoContentForMode": {
      "placeholders": {
        "mode": { "type": "String" }
      }
    },
    "dynamicLayoutCheckBackLater": "Revenez plus tard pour les mises à jour",
    "@dynamicLayoutCheckBackLater": {}
  ```

- [ ] **Step 2: Regenerate localizations.**

  ```
  flutter gen-l10n
  ```

  Expected output: no errors.

- [ ] **Step 3: Write a failing test.**

  Create `test/core/sdui_dynamic_layout_page_l10n_test.dart`:

  ```dart
  // test/core/sdui_dynamic_layout_page_l10n_test.dart
  //
  // FINDING #8 (Low) — dynamic_layout_page.dart hardcoded English error strings.
  import 'dart:io';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/l10n/app_localizations_en.dart';
  import 'package:akeli/l10n/app_localizations_fr.dart';

  void main() {
    group('ARB keys resolve correctly through generated l10n classes', () {
      test('English strings', () {
        final l10n = AppLocalizationsEn();
        expect(l10n.dynamicLayoutUnableToLoad, 'Unable to load layout');
        expect(l10n.dynamicLayoutUnknownError, 'Unknown error');
        expect(l10n.dynamicLayoutTryAgain, 'Try Again');
        expect(l10n.dynamicLayoutNoContentForMode('beauty'), 'No content for beauty mode');
        expect(l10n.dynamicLayoutCheckBackLater, 'Check back later for updates');
      });

      test('French strings are present (pre-fix widget had zero French coverage)', () {
        final l10n = AppLocalizationsFr();
        expect(l10n.dynamicLayoutUnableToLoad, isNotEmpty);
        expect(l10n.dynamicLayoutTryAgain, isNotEmpty);
        expect(l10n.dynamicLayoutNoContentForMode('beauty'), contains('beauty'));
      });
    });

    group('dynamic_layout_page.dart source no longer hardcodes English UI strings', () {
      test('no hardcoded error/empty-state literals remain', () {
        final source = File('lib/core/sdui/widgets/dynamic_layout_page.dart').readAsStringSync();
        expect(source.contains("'Unable to load layout'"), isFalse);
        expect(source.contains("'Unknown error'"), isFalse);
        expect(source.contains("'Try Again'"), isFalse);
        expect(source.contains("'Check back later for updates'"), isFalse);
        expect(source.contains(r"'No content for ${widget.mode} mode'"), isFalse);
      });

      test('error/empty views now read from AppLocalizations', () {
        final source = File('lib/core/sdui/widgets/dynamic_layout_page.dart').readAsStringSync();
        expect(source, contains('AppLocalizations.of(context)'));
      });
    });
  }
  ```

- [ ] **Step 4: Run the test and confirm it fails against current code.**

  ```
  flutter test test/core/sdui_dynamic_layout_page_l10n_test.dart
  ```

  Expected output: the "source no longer hardcodes" group **fails** (the literals are still present; `AppLocalizations.of(context)` is not yet present).

- [ ] **Step 5: Implement the fix in `lib/core/sdui/widgets/dynamic_layout_page.dart`.**

  Add the import alongside the existing imports:
  ```dart
  import 'package:akeli/l10n/app_localizations.dart';
  ```

  Replace the `_buildErrorView` method body (currently):
  ```dart
    Widget _buildErrorView() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Unable to load layout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
  ```
  with:
  ```dart
    Widget _buildErrorView() {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.dynamicLayoutUnableToLoad,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? l10n.dynamicLayoutUnknownError,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.dynamicLayoutTryAgain),
              ),
            ],
          ),
        ),
      );
    }
  ```

  Replace the `_buildEmptyView` method body (currently):
  ```dart
    Widget _buildEmptyView() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.view_quilt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No content for ${widget.mode} mode',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back later for updates',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  ```
  with:
  ```dart
    Widget _buildEmptyView() {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.view_quilt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.dynamicLayoutNoContentForMode(widget.mode),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dynamicLayoutCheckBackLater,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  ```

  (`_buildErrorView`/`_buildEmptyView` are instance methods on `_DynamicLayoutPageState`, which extends `ConsumerState` — `context` is available directly via the inherited `State.context` getter, no parameter changes needed.)

- [ ] **Step 6: Run the test again and confirm it passes.**

  ```
  flutter test test/core/sdui_dynamic_layout_page_l10n_test.dart
  ```

  Expected output: `00:0X +4: All tests passed!`

- [ ] **Step 7: Run `flutter analyze` to confirm no compile errors were introduced.**

  ```
  flutter analyze lib/core/sdui/widgets/dynamic_layout_page.dart
  ```

  Expected output: `No issues found!`

---

## Task 9: [Low] `mode_selector.dart` hardcoded header color + l10n gaps

**Files:** `lib/widgets/mode_selector.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `test/widgets/mode_selector_test.dart` (new).

**Interfaces:**
```dart
String getAppModeDescription(AppMode mode, AppLocalizations l10n);
```
(signature change — was `String getAppModeDescription(AppMode mode)`; its only call site, inside `showModeSelectorDialog`, already has a `BuildContext` in scope.)

**Sequencing note:** this task appends ARB keys after Task 8's — run Task 8 before this task.

- [ ] **Step 1: Add ARB keys.**

  In `lib/l10n/app_en.arb`, find the last key-value pair (now ending with Task 8's addition):
  ```json
    "dynamicLayoutCheckBackLater": "Check back later for updates",
    "@dynamicLayoutCheckBackLater": {}
  ```
  and replace it with:
  ```json
    "dynamicLayoutCheckBackLater": "Check back later for updates",
    "@dynamicLayoutCheckBackLater": {},
    "modeSelectorDialogTitle": "App Mode (SDUI)",
    "@modeSelectorDialogTitle": {},
    "modeSelectorCloseButton": "Close",
    "@modeSelectorCloseButton": {},
    "modeSelectorSwitchedSnackbar": "Switched to {modeName} mode",
    "@modeSelectorSwitchedSnackbar": {
      "placeholders": {
        "modeName": { "type": "String" }
      }
    },
    "modeSelectorBadgeSduiV1": "SDUI V1",
    "@modeSelectorBadgeSduiV1": {},
    "modeSelectorTileSubtitle": "Switch between Nutrition and Beauty",
    "@modeSelectorTileSubtitle": {},
    "modeDescriptionNutrition": "Meal planning, macros, and personalized recipes",
    "@modeDescriptionNutrition": {},
    "modeDescriptionBeauty": "Skin & hair care routines, traditional remedies",
    "@modeDescriptionBeauty": {},
    "modeDescriptionHealth": "Health metrics tracking, weight and vitals",
    "@modeDescriptionHealth": {},
    "modeDescriptionSport": "Training programs and activity tracking",
    "@modeDescriptionSport": {},
    "modeDescriptionFamily": "Family nutrition and meal management",
    "@modeDescriptionFamily": {}
  ```

  In `lib/l10n/app_fr.arb`, find the last key-value pair (now ending with Task 8's addition):
  ```json
    "dynamicLayoutCheckBackLater": "Revenez plus tard pour les mises à jour",
    "@dynamicLayoutCheckBackLater": {}
  ```
  and replace it with:
  ```json
    "dynamicLayoutCheckBackLater": "Revenez plus tard pour les mises à jour",
    "@dynamicLayoutCheckBackLater": {},
    "modeSelectorDialogTitle": "Mode d'application (SDUI)",
    "@modeSelectorDialogTitle": {},
    "modeSelectorCloseButton": "Fermer",
    "@modeSelectorCloseButton": {},
    "modeSelectorSwitchedSnackbar": "Passé en mode {modeName}",
    "@modeSelectorSwitchedSnackbar": {
      "placeholders": {
        "modeName": { "type": "String" }
      }
    },
    "modeSelectorBadgeSduiV1": "SDUI V1",
    "@modeSelectorBadgeSduiV1": {},
    "modeSelectorTileSubtitle": "Basculer entre Nutrition et Beauté",
    "@modeSelectorTileSubtitle": {},
    "modeDescriptionNutrition": "Planification de repas, macros et recettes adaptées",
    "@modeDescriptionNutrition": {},
    "modeDescriptionBeauty": "Routines soins peau & cheveux, remèdes traditionnels",
    "@modeDescriptionBeauty": {},
    "modeDescriptionHealth": "Suivi paramètres de santé, poids et constantes",
    "@modeDescriptionHealth": {},
    "modeDescriptionSport": "Programmes d'entraînement et suivi d'activité",
    "@modeDescriptionSport": {},
    "modeDescriptionFamily": "Gestion de la nutrition et des repas familiaux",
    "@modeDescriptionFamily": {}
  ```

- [ ] **Step 2: Regenerate localizations.**

  ```
  flutter gen-l10n
  ```

  Expected output: no errors.

- [ ] **Step 3: Write failing tests.**

  Create `test/widgets/mode_selector_test.dart`:

  ```dart
  // test/widgets/mode_selector_test.dart
  //
  // FINDING #9 (Low) — mode_selector.dart hardcodes a teal header regardless
  // of active mode, and getAppModeDescription()/dialog/snackbar copy has l10n
  // gaps.
  import 'package:flutter/material.dart';
  import 'package:flutter_localizations/flutter_localizations.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/core/theme.dart';
  import 'package:akeli/l10n/app_localizations.dart';
  import 'package:akeli/l10n/app_localizations_en.dart';
  import 'package:akeli/l10n/app_localizations_fr.dart';
  import 'package:akeli/providers/mode_provider.dart';
  import 'package:akeli/widgets/mode_selector.dart';

  class _FixedModeNotifier extends ModeNotifier {
    final AppMode _fixed;
    _FixedModeNotifier(this._fixed);
    @override
    AppMode build() => _fixed;
  }

  void main() {
    group('getAppModeDescription is localized (Finding #9)', () {
      test('English mode descriptions come from ARB, not hardcoded French', () {
        final l10n = AppLocalizationsEn();
        expect(getAppModeDescription(AppMode.beauty, l10n), isNot(contains('cheveux')));
        expect(getAppModeDescription(AppMode.beauty, l10n), l10n.modeDescriptionBeauty);
        expect(getAppModeDescription(AppMode.nutrition, l10n), l10n.modeDescriptionNutrition);
      });

      test('French mode descriptions are still available', () {
        final l10n = AppLocalizationsFr();
        expect(getAppModeDescription(AppMode.beauty, l10n), l10n.modeDescriptionBeauty);
      });
    });

    group('mode selector dialog visuals (Finding #9)', () {
      testWidgets('header icon uses the active mode color, not a hardcoded teal', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentModeProvider.overrideWith(() => _FixedModeNotifier(AppMode.beauty)),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showModeSelectorDialog(context, ref),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.dashboard_customize_rounded));
        expect(iconWidget.color, getAppModeColor(AppMode.beauty));
        expect(iconWidget.color, isNot(AkeliColors.primary));
      });
    });
  }
  ```

- [ ] **Step 4: Run the tests and confirm they fail against current code.**

  ```
  flutter test test/widgets/mode_selector_test.dart
  ```

  Expected output: compile error — `getAppModeDescription` does not accept an `AppLocalizations` argument yet. (Once that's fixed, the color test would separately fail on its own — `iconWidget.color` is the hardcoded `AkeliColors.primary` — but the compile error surfaces first.)

- [ ] **Step 5: Implement the fix in `lib/widgets/mode_selector.dart`.**

  Add the import alongside the existing imports:
  ```dart
  import '../l10n/app_localizations.dart';
  ```

  Replace the `getAppModeDescription` function (currently):
  ```dart
  /// Helper to get description for each AppMode
  String getAppModeDescription(AppMode mode) {
    switch (mode) {
      case AppMode.nutrition:
        return 'Planification de repas, macros et recettes adaptées';
      case AppMode.beauty:
        return 'Routines soins peau & cheveux, remèdes traditionnels';
      case AppMode.health:
        return 'Suivi paramètres de santé, poids et constantes';
      case AppMode.sport:
        return 'Programmes d\'entraînement et suivi d\'activité';
      case AppMode.family:
        return 'Gestion de la nutrition et des repas familiaux';
    }
  }
  ```
  with:
  ```dart
  /// Helper to get description for each AppMode
  String getAppModeDescription(AppMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppMode.nutrition:
        return l10n.modeDescriptionNutrition;
      case AppMode.beauty:
        return l10n.modeDescriptionBeauty;
      case AppMode.health:
        return l10n.modeDescriptionHealth;
      case AppMode.sport:
        return l10n.modeDescriptionSport;
      case AppMode.family:
        return l10n.modeDescriptionFamily;
    }
  }
  ```

  In `showModeSelectorDialog`, right after the existing:
  ```dart
    _logger.userAction('Opening App Mode Selector Dialog', screen: 'SettingsPage');
    final currentMode = ref.read(currentModeProvider);
  ```
  add:
  ```dart
    final l10n = AppLocalizations.of(context);
  ```

  Replace the header icon container (currently):
  ```dart
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AkeliColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: AkeliColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mode d\'application (SDUI)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
  ```
  with:
  ```dart
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getAppModeColor(currentMode).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: getAppModeColor(currentMode),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.modeSelectorDialogTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
  ```

  Replace the "SDUI V1" badge text (currently):
  ```dart
                          child: const Text(
                            'SDUI V1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
  ```
  with:
  ```dart
                          child: Text(
                            l10n.modeSelectorBadgeSduiV1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
  ```

  Replace the description call (currently):
  ```dart
                  subtitle: Text(
                    getAppModeDescription(mode),
  ```
  with:
  ```dart
                  subtitle: Text(
                    getAppModeDescription(mode, l10n),
  ```

  Replace the snackbar text (currently):
  ```dart
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Passé en mode ${mode.displayName}'),
                          ],
                        ),
  ```
  with:
  ```dart
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(l10n.modeSelectorSwitchedSnackbar(mode.displayName)),
                          ],
                        ),
  ```

  Replace the "Fermer" close button (currently):
  ```dart
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: AkeliColors.onSurfaceVariant)),
          ),
        ],
  ```
  with:
  ```dart
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.modeSelectorCloseButton, style: const TextStyle(color: AkeliColors.onSurfaceVariant)),
          ),
        ],
  ```

  In `ModeSelectorTile.build`, add right after:
  ```dart
    final currentMode = ref.watch(currentModeProvider);
    final color = getAppModeColor(currentMode);
    final icon = getAppModeIcon(currentMode);
  ```
  add:
  ```dart
    final l10n = AppLocalizations.of(context);
  ```

  Replace the tile's hardcoded title/subtitle (currently):
  ```dart
      title: const Text(
        'Mode d\'application (SDUI)',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AkeliColors.onSurface,
        ),
      ),
      subtitle: Text(
        'Basculer entre Nutrition et Beauté',
        style: TextStyle(
          fontSize: 12,
          color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
  ```
  with:
  ```dart
      title: Text(
        l10n.modeSelectorDialogTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AkeliColors.onSurface,
        ),
      ),
      subtitle: Text(
        l10n.modeSelectorTileSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
  ```

- [ ] **Step 6: Run the tests again and confirm they pass.**

  ```
  flutter test test/widgets/mode_selector_test.dart
  ```

  Expected output: `00:0X +3: All tests passed!`

- [ ] **Step 7: Run `flutter analyze` to confirm no compile errors were introduced.**

  ```
  flutter analyze lib/widgets/mode_selector.dart
  ```

  Expected output: `No issues found!`

---

## Task 10: [Medium, found during orchestrator self-review] `AppMode.displayName` renders unlocalized French mode names to English-locale users

**Files:**
- Modify: `lib/shared/widgets/main_shell.dart:111`
- Modify: `lib/widgets/mode_selector.dart:112,161,231` (on top of Task 9's edits to this file — apply this task's changes after Task 9)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (add new keys, additive only)
- Test: `test/shared/widgets/main_shell_test.dart` (check if this file exists via `Glob test/shared/widgets/main_shell_test.dart`; if not, create it)

**Interfaces:** `String appModeLabel(AppMode mode, AppLocalizations l10n)` — new top-level function in `lib/widgets/mode_selector.dart` (exported, so `main_shell.dart` can import and call it).

`lib/providers/mode_provider.dart`'s `AppMode.displayName` getter (read it — it hardcodes `'Nutrition'/'Beauté'/'Santé'/'Sport'/'Famille'`) is consumed directly as user-visible text at 4 call sites: `main_shell.dart:111` (the mode badge in the nav bar), and `mode_selector.dart:112,161,231` (the dialog's mode list, the "Passé en mode X" snackbar, and the current-mode label). Per CLAUDE.md's L10n Standard rule 6 ("Providers and notifiers never resolve l10n strings — widget layer only"), the fix belongs at these widget call sites, not inside `mode_provider.dart` itself — do not add an `AppLocalizations` import to `mode_provider.dart`.

**A 5th call site, `lib/features/settings/settings_page.dart:339` (`ref.watch(currentModeProvider).displayName`), is owned by Area H's plan, not this one — this task does not touch it.** Note it here as a cross-plan flag: Area H should apply the identical fix at that call site using the `appModeLabel` helper this task creates (import `package:akeli/widgets/mode_selector.dart` or move the helper to a lower-level shared file if Area H's plan runs first and finds this awkward — either ordering works since the helper is a pure function).

- [ ] **Step 1: Write the failing test.**

  If `test/shared/widgets/main_shell_test.dart` doesn't exist, create it with this content (adjust imports to match this codebase's existing widget-test scaffolding conventions — check an existing test like `test/features/settings/settings_page_beauty_test.dart` for the exact `ProviderScope` + `MaterialApp` + `AppLocalizations.delegate` pump pattern and mirror it exactly):

  ```dart
  testWidgets('mode badge shows localized English label, not hardcoded French, when locale is en', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentModeProvider.overrideWith(() => _FixedMode(AppMode.beauty))],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainShell(child: Container()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beauté'), findsNothing);
    expect(find.text('Beauty'), findsOneWidget);
  });
  ```

  (Read `mode_provider.dart`'s `currentModeProvider` definition first to write a correct `_FixedMode` override class matching its actual Notifier type — do not guess the override syntax.)

- [ ] **Step 2: Confirm the test fails.**

  ```
  flutter test test/shared/widgets/main_shell_test.dart
  ```

  Expected output: test fails at `expect(find.text('Beauté'), findsNothing)` — `Beauté` is found (hardcoded regardless of locale).

- [ ] **Step 3: Add 5 ARB keys to both files.**

  Add to `lib/l10n/app_en.arb`:
  ```json
  "appModeNutrition": "Nutrition",
  "appModeBeauty": "Beauty",
  "appModeHealth": "Health",
  "appModeSport": "Sport",
  "appModeFamily": "Family",
  ```

  Add to `lib/l10n/app_fr.arb`:
  ```json
  "appModeNutrition": "Nutrition",
  "appModeBeauty": "Beauté",
  "appModeHealth": "Santé",
  "appModeSport": "Sport",
  "appModeFamily": "Famille",
  ```

- [ ] **Step 4: Add the `appModeLabel` helper to `lib/widgets/mode_selector.dart`.**

  Add this top-level function (place it near the top of the file, after imports, alongside `getAppModeDescription` from Task 9):

  ```dart
  String appModeLabel(AppMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppMode.nutrition:
        return l10n.appModeNutrition;
      case AppMode.beauty:
        return l10n.appModeBeauty;
      case AppMode.health:
        return l10n.appModeHealth;
      case AppMode.sport:
        return l10n.appModeSport;
      case AppMode.family:
        return l10n.appModeFamily;
    }
  }
  ```

- [ ] **Step 5: Replace the 3 remaining `mode.displayName` usages in `mode_selector.dart` (lines 112, 161, 231 — re-read the file after Task 9's edits to get current line numbers, since Task 9 already modified this file).**

  Replace each `mode.displayName` / `currentMode.displayName` with `appModeLabel(mode, l10n)` / `appModeLabel(currentMode, l10n)` (an `l10n` local variable already exists in each of these build methods per Task 9's edits — confirm before use, add `final l10n = AppLocalizations.of(context);` if a given method doesn't already have it in scope).

- [ ] **Step 6: Fix `main_shell.dart:111`.**

  Add the import `import 'package:akeli/widgets/mode_selector.dart' show appModeLabel;` (or the correct relative import path used elsewhere in this file) and `final l10n = AppLocalizations.of(context);` if not already present in this `build()` method, then change:
  ```dart
                      Text(
                        mode.displayName,
  ```
  to:
  ```dart
                      Text(
                        appModeLabel(mode, l10n),
  ```

- [ ] **Step 7: Confirm the test passes.**

  ```
  flutter test test/shared/widgets/main_shell_test.dart
  ```

  Expected output: `00:0X +1: All tests passed!`

- [ ] **Step 8: Run `flutter gen-l10n` then `flutter analyze`.**

  ```
  flutter gen-l10n
  flutter analyze lib/shared/widgets/main_shell.dart lib/widgets/mode_selector.dart
  ```

  Expected output: no errors, `No issues found!`

- [ ] **Step 9: Commit.**

  ```bash
  git add lib/shared/widgets/main_shell.dart lib/widgets/mode_selector.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb test/shared/widgets/main_shell_test.dart
  git commit -m "fix(i18n): localize AppMode display names instead of hardcoded French in mode badge/selector"
  ```

  **Reminder:** `lib/features/settings/settings_page.dart:339` has the identical bug and is Area H's file, not this plan's — do not fix it here; it's flagged for Area H in this task's description above.

---

## Coverage Checklist

| # | Finding (severity) | Task | Special conditions |
|---|---|---|---|
| 1 | Router infinite redirect loop (Critical) | Task 1 | — |
| 2 | SDUI subsystem dead code / false "done" docs (Critical) | Task 2 | Part A (docs correction) is **mandatory**. Part B (`/sdui-demo` route + test) is **explicitly OPTIONAL — skip if time-constrained**, per the review's instructions. |
| 3 | Beauty-onboarding guard keyed to `currentMode`, not route (High) | Task 3 | Depends on Task 1 (reuses `computeAkeliRedirect`/`_beautyGatedRoutes`); includes a mutation-based proof that its tests are meaningful, not just green by coincidence. |
| 4 | Duplicate `GoRoute` for `/onboarding` (Medium) | Task 4 | — |
| 5 | `main_shell.dart` hardcoded tab labels + zero logging (Medium) | Task 5 | — |
| 6 | `theme.dart` needs Area F's `colorSetProvider` (Medium/High, cross-plan) | Task 6 | Part A (signature changes) is independent and unblocked. Part B (`main.dart` wiring) is **BLOCKED** until `lib/providers/color_set_provider.dart` exists (created by Area F's plan, `docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md`, which did not exist as of this plan's writing) — Step 0 of Part B is a mandatory dependency gate. |
| 7 | `buildDarkTheme()` missing 5 component themes (Low) | Task 7 | Depends on Task 6 Part A (same function). |
| 8 | `dynamic_layout_page.dart` hardcoded English strings (Low) | Task 8 | — |
| 9 | `mode_selector.dart` hardcoded color + l10n gaps (Low) | Task 9 | — |
| 10 | `AppMode.displayName` hardcoded French, no l10n (Medium) | Task 10 | **Added during orchestrator self-review** (not one of the original 9 findings dispatched to this plan). Covers `main_shell.dart:111` and `mode_selector.dart`'s 3 remaining `.displayName` usages. `settings_page.dart:339` has the identical bug but is Area H's owned file — flagged there, not fixed here. |

---

**Self-review performed before saving this plan:**
- Placeholder scan: no "TBD", no "add appropriate error handling", no "similar to Task N", no step describes code without showing it.
- Route-constant consistency verified across all tasks: `AkeliRoutes.onboarding`, `.beautyOnboarding`, `.home`, `.auth`, `.resetPassword`, `.privacyPolicy`, `.termsOfService`, `.beautyAnalytics`, and the new `.sduiDemo` are used identically everywhere they appear.
- ARB key names verified unique and non-colliding with any existing key in `app_en.arb`/`app_fr.arb` (checked via the file reads performed while writing this plan); Tasks 5, 8, 9 append in strict numeric order to avoid collisions with each other.
- Function/parameter names verified consistent: `computeAkeliRedirect`, `mainShellTabLabels`, `getAppModeColor(mode, {customPrimary})`, `getAppModeDescription(mode, l10n)` all match between their definition site and every call site shown in this plan.
