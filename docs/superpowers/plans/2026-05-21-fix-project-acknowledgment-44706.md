# Fix Plan — `project-acknowledgment-44706`

**Branch:** `project-acknowledgment-44706`
**Goal:** Fix all issues so the branch is testable and mergeable into `main`
**Authored by:** qwen.ai[bot] — this plan corrects its mistakes

---

## Context

This branch adds 6 real pages missing from Stitch design coverage:
- `lib/features/support/support_page.dart`
- `lib/features/legal/privacy_policy_page.dart`
- `lib/features/legal/terms_of_service_page.dart`
- `lib/features/referral/referral_page.dart`
- `lib/features/cooking/cooking_session_bottom_sheet.dart`
- `lib/features/journaling/journaling_bottom_sheet.dart`

Plus router updates and Android config changes. The pages are real (not stubs) — only compliance and structural issues need fixing.

---

## Issues to Fix

### Issue 1 — Wrong logger in all 6 Dart files

**Problem:** All files import `package:logger/logger.dart` and use `final _log = Logger()`. This bypasses the project's structured log pipeline, `kDebugMode` gating, and log categories.

**Fix for each file:**

Replace:
```dart
import 'package:logger/logger.dart';
final _log = Logger();
```

With:
```dart
import 'package:akeli/core/logger.dart';
final _logger = appLogger;
```

Then replace every `_log.i(...)` → `_logger.provider(...)` or `_logger.userAction(...)` as appropriate:
- Page `initState` / `dispose` → `_logger.provider('PageName initialized')` / `_logger.provider('PageName disposed')`
- Button taps, form submits → `_logger.userAction('Action label', screen: 'PageName')`
- Form validation failures → `_logger.provider('PageName | validation failed')`
- API calls (when wired) → follow `_logger.db()` / `_logger.edge()` pattern from CLAUDE.md

Apply to all 6 files:
1. `support_page.dart`
2. `privacy_policy_page.dart`
3. `terms_of_service_page.dart`
4. `referral_page.dart`
5. `cooking_session_bottom_sheet.dart`
6. `journaling_bottom_sheet.dart`

---

### Issue 2 — `referral_page.dart` has zero logging

**Problem:** No logger import, no lifecycle logs, no user action logs.

**Fix:** In addition to Issue 1 fix, add full logging:

```dart
// At class level
final _logger = appLogger;

// initState
@override
void initState() {
  super.initState();
  _logger.provider('ReferralPage build()');
}

// dispose
@override
void dispose() {
  _codeController.dispose();
  _logger.provider('ReferralPage disposed');
  super.dispose();
}

// _saveCode
_logger.userAction('Save referral code tapped', screen: 'ReferralPage');
// before API call:
_logger.edge('referral-update', 'BEFORE | code: ${_codeController.text}');
// after:
_logger.edge('referral-update', 'AFTER | success');

// Copy code button
_logger.userAction('Copy referral code tapped', screen: 'ReferralPage');

// Share button
_logger.userAction('Share referral tapped', screen: 'ReferralPage');
```

---

### Issue 3 — Legal/support/referral routes inside `ShellRoute` (wrong UX)

**Problem:** In `lib/core/router.dart`, `support`, `privacyPolicy`, `termsOfService`, and `referral` are nested inside the `ShellRoute`. This renders the bottom nav bar on legal/support screens — incorrect UX.

**Fix:** Move these 4 routes OUT of the `ShellRoute` routes list and place them at the top level alongside `recipeDetail`, `profile`, etc.

Current (wrong):
```dart
ShellRoute(
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(path: AkeliRoutes.home, ...),
    GoRoute(path: AkeliRoutes.mealPlanner, ...),
    GoRoute(path: AkeliRoutes.recipes, ...),
    GoRoute(path: AkeliRoutes.community, ...),
    GoRoute(path: AkeliRoutes.support, ...),       // ← wrong
    GoRoute(path: AkeliRoutes.privacyPolicy, ...),  // ← wrong
    GoRoute(path: AkeliRoutes.termsOfService, ...), // ← wrong
    GoRoute(path: AkeliRoutes.referral, ...),       // ← wrong
  ],
),
```

Fixed:
```dart
// Top-level routes (no shell / no bottom nav)
GoRoute(path: AkeliRoutes.support, builder: (context, state) => const SupportPage()),
GoRoute(path: AkeliRoutes.privacyPolicy, builder: (context, state) => const PrivacyPolicyPage()),
GoRoute(path: AkeliRoutes.termsOfService, builder: (context, state) => const TermsOfServicePage()),
GoRoute(path: AkeliRoutes.referral, builder: (context, state) => const ReferralPage()),

ShellRoute(
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(path: AkeliRoutes.home, ...),
    GoRoute(path: AkeliRoutes.mealPlanner, ...),
    GoRoute(path: AkeliRoutes.recipes, ...),
    GoRoute(path: AkeliRoutes.community, ...),
    // support/legal/referral removed from here
  ],
),
```

---

### Issue 4 — Hardcoded color in `referral_page.dart`

**Problem:** `const Color(0xFFF9F9E8)` used directly for `backgroundColor`.

**Fix:** Replace with the design token:
```dart
// Replace:
backgroundColor: const Color(0xFFF9F9E8),

// With:
backgroundColor: AkeliColors.surface,
```

Apply to all instances in `referral_page.dart` (AppBar backgroundColor and Scaffold backgroundColor).

---

### Issue 5 — `versionName = "1.0.0-local"` in `android/app/build.gradle.kts`

**Problem:** The `-local` suffix should not be merged to main.

**Fix:**
```kotlin
// Replace:
versionName = "1.0.0-local"

// With:
versionName = "1.0.0"
```

---

### Issue 6 — Markdown docs at repo root

**Problem:** 6 markdown files dumped at root: `MISSING_PAGES_COMPLETE.md`, `STITCH_DART_AUDIT.md`, `LOCAL_SETUP_GUIDE.md`, `PAGE_AUDIT_REPORT.md`, `PRE_PRODUCTION_AUDIT.md`, `PRE_PRODUCTION_CHECKLIST.md`.

**Fix:** Move all 6 to `akeli_docs/`:
```
git mv MISSING_PAGES_COMPLETE.md akeli_docs/
git mv STITCH_DART_AUDIT.md akeli_docs/
git mv LOCAL_SETUP_GUIDE.md akeli_docs/
git mv PAGE_AUDIT_REPORT.md akeli_docs/
git mv PRE_PRODUCTION_AUDIT.md akeli_docs/
git mv PRE_PRODUCTION_CHECKLIST.md akeli_docs/
```

---

## Fix Order

1. Fix logger imports in all 6 Dart files (Issues 1 + 2)
2. Move 4 routes out of ShellRoute (Issue 3)
3. Replace hardcoded color in `referral_page.dart` (Issue 4)
4. Fix `versionName` in `build.gradle.kts` (Issue 5)
5. Move markdown docs to `akeli_docs/` (Issue 6)
6. Commit with message: `fix: CLAUDE.md compliance, router structure, and cleanup for project-acknowledgment-44706`

## Testability Checklist

After fixes, verify locally:
- [ ] `flutter analyze` passes with no errors
- [ ] App navigates to `/support` — no bottom nav visible
- [ ] App navigates to `/privacy-policy` — no bottom nav visible
- [ ] App navigates to `/terms-of-service` — no bottom nav visible
- [ ] App navigates to `/referral` — no bottom nav visible
- [ ] All log calls appear in debug console using `appLogger` format
- [ ] `referral_page.dart` logs init, dispose, and every button tap
- [ ] Background color on all pages matches design tokens (no hardcoded hex)
