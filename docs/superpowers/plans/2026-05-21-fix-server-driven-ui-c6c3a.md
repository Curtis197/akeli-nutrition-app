# Fix Plan — `server-driven-ui-for-wellness-app-c6c3a`

**Branch:** `server-driven-ui-for-wellness-app-c6c3a`
**Goal:** Fix all issues so the branch is testable and mergeable into `main`
**Authored by:** qwen.ai[bot] — this plan corrects its mistakes

---

## Context

This branch introduces Server-Driven UI (SDUI) architecture with Beauty mode switching. It is 3 commits ahead of `main` and 0 behind — correctly based. The concept is sound and the DB schema is well-designed. The issues are structural and compliance-only.

New files added:
- `lib/core/sdui/layout_cache_service.dart` ← DUPLICATE (delete this one)
- `lib/core/sdui/layout_fetch_service.dart` ← DUPLICATE (delete this one)
- `lib/core/sdui/providers/mode_provider.dart` ← DUPLICATE (delete this one)
- `lib/core/sdui/widget_factory.dart` ← DUPLICATE (delete this one)
- `lib/core/sdui/services/layout_cache_service.dart` ← KEEP
- `lib/core/sdui/services/layout_fetch_service.dart` ← KEEP
- `lib/core/sdui/widgets/widget_factory.dart` ← KEEP
- `lib/core/sdui/widgets/dynamic_layout_page.dart`
- `lib/providers/mode_provider.dart` ← KEEP (Riverpod provider)
- `lib/shared/widgets/main_shell.dart` (modified)
- `lib/main.dart` (modified — already has correct logging)
- `supabase/migrations/20240101000001_create_sdui_layouts.sql`
- `supabase/migrations/20240102000001_create_beauty_mode_schema.sql`

---

## Issues to Fix

### Issue 1 — Duplicate file pairs

**Problem:** Two copies of each service exist at different paths. Dart will resolve imports to one or the other depending on which path is used, creating inconsistency and dead code.

**Fix:** Delete the top-level duplicates and keep only the `services/` and `widgets/` subdirectory versions:

```bash
git rm lib/core/sdui/layout_cache_service.dart
git rm lib/core/sdui/layout_fetch_service.dart
git rm lib/core/sdui/widget_factory.dart
git rm lib/core/sdui/providers/mode_provider.dart
```

Then update any import in `lib/core/sdui/widgets/dynamic_layout_page.dart` or other files that may reference the deleted paths — point them to `lib/core/sdui/services/` and `lib/core/sdui/widgets/`.

---

### Issue 2 — No structured logging in new Dart files (CLAUDE.md violation)

**Problem:** All new Dart files use `debugPrint(...)` instead of `appLogger`. Files affected:
- `lib/providers/mode_provider.dart`
- `lib/core/sdui/services/layout_cache_service.dart`
- `lib/core/sdui/services/layout_fetch_service.dart`
- `lib/core/sdui/widgets/widget_factory.dart`
- `lib/core/sdui/widgets/dynamic_layout_page.dart`
- `lib/shared/widgets/main_shell.dart`

**Fix for each file** — add at the top of each class:
```dart
import 'package:akeli/core/logger.dart';
final _logger = appLogger;
```

Then replace `debugPrint('[ClassName] ...')` with the appropriate log category:

| Context | Method |
|---|---|
| Provider/notifier lifecycle | `_logger.provider(...)` |
| Mode switch state transitions | `_logger.provider('ModeNotifier → ${newMode.name}')` |
| Cache read/write | `_logger.db('BEFORE/AFTER | cache op: ...')` |
| Supabase fetch | `_logger.db('BEFORE | table: layouts | op: SELECT')` |
| Widget factory unknown type | `_logger.provider('SDUIWidgetFactory | unknown type: $type')` |
| Navigation | `_logger.navigation(from, to)` |

Specific replacements in `mode_provider.dart`:
```dart
// Replace:
debugPrint('[ModeNotifier] Loaded saved mode: ${savedMode.name}');
// With:
_logger.provider('ModeNotifier → ${savedMode.name} (loaded from cache)');

// Replace:
debugPrint('[ModeNotifier] Switching mode: ${state.name} -> ${newMode.name}');
// With:
_logger.provider('ModeNotifier → switching: ${state.name} → ${newMode.name}');
```

Specific replacements in `layout_fetch_service.dart` (Supabase fetch):
```dart
_logger.db('BEFORE | table: layouts | op: SELECT | mode: $mode');
// ... fetch ...
_logger.db('AFTER | table: layouts | rows: ${result != null ? 1 : 0}');
// on error:
_logger.db('ERROR | table: layouts | $e', error: e, stackTrace: st);
```

---

### Issue 3 — `main_shell.dart` reads mode from URL instead of Riverpod

**Problem:** `_getCurrentMode(BuildContext context)` pattern-matches on `GoRouterState.of(context).uri.path`. This means the Riverpod `currentModeProvider` and the shell UI are two independent sources of truth and will diverge.

**Fix:** Convert `MainShell` from `StatefulWidget` to `ConsumerWidget` (or `ConsumerStatefulWidget`) and read mode from `currentModeProvider`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mode_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final modeName = currentMode.name; // 'nutrition' or 'beauty'

    // Use modeName instead of _getCurrentMode(context) everywhere in build
    // Call ref.read(currentModeProvider.notifier).switchMode(AppMode.beauty)
    // instead of _switchMode(context, 'beauty')
  }
}
```

Remove `_getCurrentMode()` and `_switchMode()` helper methods entirely — replace with Riverpod reads.

---

### Issue 4 — `StateNotifierProvider` (deprecated Riverpod v1 API)

**Problem:** `lib/providers/mode_provider.dart` uses `StateNotifierProvider<ModeNotifier, AppMode>`. The rest of the codebase uses `AutoDisposeAsyncNotifier` / `NotifierProvider`.

**Fix:** Rewrite `ModeNotifier` as a `Notifier`:

```dart
final currentModeProvider = NotifierProvider<ModeNotifier, AppMode>(ModeNotifier.new);

class ModeNotifier extends Notifier<AppMode> {
  final _logger = appLogger;

  @override
  AppMode build() {
    _logger.provider('ModeNotifier build()');
    // Load saved mode synchronously from Hive (already opened in main.dart)
    final box = Hive.box('mode_state');
    final saved = box.get('current_mode', defaultValue: 'nutrition') as String;
    final mode = AppMode.values.firstWhere((m) => m.name == saved, orElse: () => AppMode.nutrition);
    _logger.provider('ModeNotifier → initial: ${mode.name}');
    return mode;
  }

  Future<void> switchMode(AppMode newMode) async {
    if (state == newMode) return;
    _logger.provider('ModeNotifier → switching: ${state.name} → ${newMode.name}');
    final box = Hive.box('mode_state');
    await box.put('current_mode', newMode.name);
    state = newMode;
    _logger.provider('ModeNotifier → ${newMode.name}');
  }
}
```

---

### Issue 5 — Migration timestamps conflict with existing schema

**Problem:** `20240101000001_create_sdui_layouts.sql` (Jan 1, 2024) and `20240102000001_create_beauty_mode_schema.sql` (Jan 2, 2024) will run before all existing V1 migrations, potentially referencing tables that don't yet exist at that sequence point.

**Fix:** Rename the migration files to a timestamp after the latest existing migration:

```bash
# Check latest migration timestamp first, then name accordingly:
git mv supabase/migrations/20240101000001_create_sdui_layouts.sql \
       supabase/migrations/20260521000001_create_sdui_layouts.sql

git mv supabase/migrations/20240102000001_create_beauty_mode_schema.sql \
       supabase/migrations/20260521000002_create_beauty_mode_schema.sql
```

---

### Issue 6 — 8 markdown files at repo root and inside `lib/`

**Problem:** The following files don't belong at the repo root or inside `lib/`:
- `AKELI_V1_Documentation.md`
- `ARCHITECTURE_AUDIT_MODE_SWITCHING.md`
- `MODE_SWITCHING_AUDIT_IMPLEMENTATION.md`
- `SDUI_IMPLEMENTATION_AUDIT.md`
- `SDUI_IMPLEMENTATION_GUIDE.md`
- `SDUI_IMPLEMENTATION_PLAN.md`
- `SDUI_IMPLEMENTATION_STATUS.md`
- `SDUI_IMPLEMENTATION_SUMMARY.md`
- `lib/core/sdui/SDUI_IMPLEMENTATION_GUIDE.md`

**Fix:**
```bash
git mv AKELI_V1_Documentation.md akeli_docs/
git mv ARCHITECTURE_AUDIT_MODE_SWITCHING.md akeli_docs/
git mv MODE_SWITCHING_AUDIT_IMPLEMENTATION.md akeli_docs/
git mv SDUI_IMPLEMENTATION_AUDIT.md akeli_docs/
git mv SDUI_IMPLEMENTATION_GUIDE.md akeli_docs/
git mv SDUI_IMPLEMENTATION_PLAN.md akeli_docs/
git mv SDUI_IMPLEMENTATION_STATUS.md akeli_docs/
git mv SDUI_IMPLEMENTATION_SUMMARY.md akeli_docs/
git rm lib/core/sdui/SDUI_IMPLEMENTATION_GUIDE.md
```

---

## Fix Order

1. Delete duplicate file pairs — keep `services/` and `widgets/` versions (Issue 1)
2. Add `appLogger` logging to all 5 new Dart files (Issue 2)
3. Convert `MainShell` to `ConsumerWidget`, read mode from `currentModeProvider` (Issue 3)
4. Rewrite `ModeNotifier` using `NotifierProvider` (Issue 4)
5. Rename migration timestamps to `20260521000001` / `20260521000002` (Issue 5)
6. Move 8 markdown docs to `akeli_docs/`, delete the one inside `lib/` (Issue 6)
7. Commit: `fix: CLAUDE.md compliance, Riverpod migration, dedup files for server-driven-ui branch`

---

## Testability Checklist

After fixes, verify locally:
- [ ] `flutter analyze` passes with no errors
- [ ] App launches with Hive initialized (check debug logs for `Hive initialized`)
- [ ] Mode switcher in AppBar toggles between Nutrition and Beauty
- [ ] Mode persists across hot restarts (reads from Hive `mode_state` box)
- [ ] `currentModeProvider` and shell UI are in sync — no divergence
- [ ] No duplicate import errors from deleted file paths
- [ ] `supabase db push` applies new migrations in correct order after existing V1 schema
- [ ] All log calls use `appLogger` format in debug console
