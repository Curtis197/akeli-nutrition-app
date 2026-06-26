# Fix Plan — `multilang-app-audit-d2e69` (PR #4)

**Branch:** `multilang-app-audit-d2e69` → targets `language-selector`
**PR:** https://github.com/Curtis197/akeli-nutrition-app/pull/4
**Goal:** Fix all issues so the branch is testable and eventually mergeable into `main`
**Authored by:** qwen-chat coder — this plan corrects its mistakes

---

## Context

This branch adds language selection (FR/EN/Wolof/Bambara/Lingala etc.) and recipe translation via a `translate-recipe` edge function. The feature concept is valid and the DB schema (`recipe_translation` table, `get_all_ui_translations` RPC) is sound. However the implementation has critical structural issues that must be resolved before any testing is possible.

New files added:
- `lib/core/localization/app_locale.dart`
- `lib/core/providers/locale_provider.dart`
- `lib/core/services/translation_service.dart`
- `lib/models/multimedia_models.dart`
- `lib/services/media_upload_service.dart`
- `lib/widgets/ingredients/ingredient_widgets.dart`
- `lib/widgets/locale_selector.dart`
- `lib/widgets/recipe_steps/recipe_step_widgets.dart`
- `supabase/functions/optimize-image/index.ts`
- `supabase/functions/process-media-upload/index.ts`
- `supabase/functions/translate-recipe/index.ts`
- `supabase/migrations/20260301000003_language_support.sql`
- `supabase/migrations/20260301000004_multimedia_support.sql`
- `supabase/seed/02_translations.sql`

---

## Pre-Requisite: Rebase onto `main`

**This must be done before any code fixes.** The branch is currently based on `language-selector` which is 143 commits behind `main`. All code fixes applied to the old base will be worthless — the branch must run on the current codebase.

```bash
# Step 1: Rebase language-selector onto main
git checkout language-selector
git rebase main
git push --force-with-lease origin language-selector

# Step 2: Rebase the feature branch onto the updated language-selector
git checkout multilang-app-audit-d2e69
git rebase language-selector
git push --force-with-lease origin multilang-app-audit-d2e69
```

Resolve any conflicts that arise (most likely in `pubspec.yaml` and `.gitignore`).

---

## Issues to Fix

### Issue 1 — `LocaleProvider` uses `ChangeNotifier` instead of Riverpod

**Problem:** `lib/core/providers/locale_provider.dart` extends `ChangeNotifier` and `TranslationService` is a raw global singleton. The project uses Riverpod exclusively — this provider cannot be consumed by any widget or provider without importing a foreign pattern.

**Fix:** Rewrite as a Riverpod `AsyncNotifier`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import '../localization/app_locale.dart';
import '../services/translation_service.dart';

final localeProvider = AsyncNotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<AppLocale> {
  final _logger = appLogger;

  @override
  Future<AppLocale> build() async {
    _logger.provider('LocaleNotifier build()');
    ref.onDispose(() => _logger.provider('LocaleNotifier disposed'));
    final locale = await ref.read(translationServiceProvider).loadUserPreferredLanguage();
    _logger.provider('LocaleNotifier → initial locale: ${locale.code}');
    return locale;
  }

  Future<void> setLocale(AppLocale newLocale) async {
    _logger.provider('LocaleNotifier → setLocale: ${newLocale.code}');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(translationServiceProvider).loadTranslations(newLocale);
      _logger.provider('LocaleNotifier → ${newLocale.code} loaded');
      return newLocale;
    });
  }
}
```

Delete the old `LocaleProvider` class entirely.

---

### Issue 2 — `TranslationService.notifyListeners()` is a no-op stub

**Problem:** `lib/core/services/translation_service.dart` defines `void notifyListeners() {}` with an empty body. `_isLoading` state changes are set and cleared but nothing is ever notified — any UI depending on loading state will never update.

**Fix:** Convert `TranslationService` to a Riverpod provider and remove the manual `notifyListeners` pattern:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

class TranslationService {
  final _logger = appLogger;
  final Map<String, Map<String, String>> _translations = {};
  String? _currentLanguage;

  Future<void> loadTranslations(AppLocale locale) async {
    if (_currentLanguage == locale.code && _translations.isNotEmpty) return;

    _logger.db('BEFORE rpc | fn: get_all_ui_translations | locale: ${locale.code}');
    try {
      final client = Supabase.instance.client;
      final response = await client.rpc(
        'get_all_ui_translations',
        params: {'p_language_code': locale.code},
      );
      _logger.db('AFTER rpc | fn: get_all_ui_translations | rows: ${(response as List).length}');

      _translations.clear();
      for (var item in response) {
        final keyName = item['key_name'] as String;
        final value = item['value'] as String;
        _translations[keyName] ??= {};
        _translations[keyName]![locale.code] = value;
      }
      _currentLanguage = locale.code;
      await _saveLanguagePreference(locale.code);
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR rpc | fn: get_all_ui_translations | ${e.message}', error: e, stackTrace: st);
      rethrow;
    }
  }

  // Keep translate(), translateOrNull(), hasTranslation() methods unchanged
  // Remove: _isLoading field, notifyListeners(), global translationService singleton
}
```

Remove the `final translationService = TranslationService()` global singleton at the bottom of the file.

---

### Issue 3 — No structured logging in any new Flutter file (CLAUDE.md violation)

**Problem:** All 8 new Dart files have no `appLogger` usage. Files without any logging:
- `lib/widgets/locale_selector.dart`
- `lib/widgets/ingredients/ingredient_widgets.dart`
- `lib/widgets/recipe_steps/recipe_step_widgets.dart`
- `lib/models/multimedia_models.dart`
- `lib/services/media_upload_service.dart`

**Fix:** Add to every Dart file:
```dart
import 'package:akeli/core/logger.dart';
final _logger = appLogger;
```

Key log points for each:

**`locale_selector.dart`** (widget):
```dart
_logger.userAction('Language selected: ${locale.code}', screen: 'LocaleSelector');
```

**`media_upload_service.dart`**:
```dart
_logger.edge('process-media-upload', 'BEFORE | file: $fileName');
_logger.edge('process-media-upload', 'AFTER | url: $uploadedUrl');
_logger.edge('process-media-upload', 'ERROR | $e', error: e, stackTrace: st);
```

**`ingredient_widgets.dart`** / **`recipe_step_widgets.dart`** (build-only widgets — at minimum):
```dart
// In any callback (tap, expand, etc.):
_logger.userAction('Ingredient tapped: $ingredientName', screen: 'IngredientWidget');
```

---

### Issue 4 — No structured logging in any edge function (CLAUDE.md violation)

**Problem:** All 3 edge functions use bare `console.log`/`console.error`. Missing: `createLogger`, `logRLSCheck`, `logQueryResult`, requestId, ENTRY/EXIT pattern.

**Fix:** Apply to all 3 functions (`translate-recipe`, `optimize-image`, `process-media-upload`). Template for `translate-recipe/index.ts`:

```typescript
import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';
import { ok, err, unauthorized, serverError } from '../_shared/response.ts';

// At top of handler:
const logger = createLogger('translate-recipe');
const requestId = crypto.randomUUID();
logger.setRequestId(requestId);
const start = Date.now();
logger.info('⚡ ENTRY | method: ' + req.method);

// After auth check:
logger.setUserId(user.id);
logger.info('👤 Auth verified | userId: ' + user.id);

// Steps:
logger.debug('[STEP 1] Parsing request body');
logger.debug('[STEP 2] Validating recipe_id and target_language');

// Before each DB operation:
logRLSCheck(logger, 'recipe', 'SELECT', user.id);
// After each DB operation:
logQueryResult(logger, 'recipe', 'SELECT', recipe ? 1 : 0, recipeError ?? undefined);

// Before EXIT:
logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
return ok({ ... });

// Catch-all:
} catch (e) {
  logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
  return serverError(e);
}
```

Apply the same pattern to `optimize-image/index.ts` and `process-media-upload/index.ts`.

---

### Issue 5 — `translate-recipe` uses `SUPABASE_ANON_KEY` for a write operation

**Problem:** The function creates a Supabase client with `SUPABASE_ANON_KEY`. Writes to `recipe_translation` will be blocked by RLS unless there is an open INSERT policy (which would be a security gap).

**Fix:** Use `SUPABASE_SERVICE_ROLE_KEY` for the edge function client since it runs in a trusted server context:

```typescript
// Replace:
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_ANON_KEY') ?? '',
  { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
);

// With:
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);
// Auth is still verified separately via the anon client or JWT check
```

Apply the same fix to `optimize-image` and `process-media-upload`.

---

### Issue 6 — `translate-recipe` calls OpenAI instead of Claude

**Problem:** Uses `gpt-3.5-turbo` via the OpenAI API, requiring an `OPENAI_API_KEY` secret not used anywhere else in the project. The project is built on the Anthropic ecosystem.

**Fix:** Replace the OpenAI call with the Anthropic Messages API:

```typescript
// Replace translateWithAI function:
async function translateWithAI(
  text: string,
  targetLanguage: string,
  apiKey: string
): Promise<string> {
  const languageNames: Record<string, string> = {
    'fr': 'French', 'en': 'English', 'es': 'Spanish',
    'pt': 'Portuguese', 'wo': 'Wolof', 'bm': 'Bambara', 'ln': 'Lingala',
  };

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 2000,
      messages: [{
        role: 'user',
        content: `Translate the following culinary text to ${languageNames[targetLanguage] || targetLanguage}. Maintain formatting, measurements, and technical terms. Return only the translation.\n\n${text}`,
      }],
    }),
  });

  if (!response.ok) {
    throw new Error('Anthropic API error: ' + response.statusText);
  }

  const data = await response.json();
  return data.content[0].text.trim();
}
```

Change the env var reference from `OPENAI_API_KEY` to `ANTHROPIC_API_KEY`:
```typescript
const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
```

---

### Issue 7 — Migration timestamps may conflict

**Problem:** `20260301000003` and `20260301000004` (March 1, 2026) — depending on what migrations already exist in the DB, these may or may not be in the right order relative to existing migrations.

**Fix:** After the rebase in the pre-requisite step, check the latest migration timestamp in the project and rename if needed:

```bash
# Check current latest:
ls supabase/migrations/ | sort | tail -5

# If March 2026 is correct order, leave as-is.
# If not, rename to a date after the latest existing migration.
```

---

## Fix Order

1. **Rebase onto `main`** (pre-requisite — do this first)
2. Rewrite `LocaleProvider` as Riverpod `AsyncNotifier` (Issue 1)
3. Fix `TranslationService` — remove `notifyListeners()` stub, convert to Riverpod provider (Issue 2)
4. Add `appLogger` logging to all 5 remaining Dart files (Issue 3)
5. Add structured logging to all 3 edge functions (Issue 4)
6. Switch edge functions from `SUPABASE_ANON_KEY` to `SUPABASE_SERVICE_ROLE_KEY` (Issue 5)
7. Replace OpenAI call with Anthropic API in `translate-recipe` (Issue 6)
8. Verify migration timestamp order (Issue 7)
9. Commit: `fix: rewrite to Riverpod, CLAUDE.md logging compliance, Anthropic API for multilang branch`

---

## Testability Checklist

After fixes, verify locally:
- [ ] `flutter analyze` passes with no errors
- [ ] `LocaleSelector` widget renders in a page and calls `ref.read(localeProvider.notifier).setLocale(...)`
- [ ] Selecting a language updates the locale via Riverpod (no `ChangeNotifier` pattern)
- [ ] `get_all_ui_translations` RPC returns data for `fr` (seed data in `02_translations.sql`)
- [ ] `translate-recipe` edge function invoked via Supabase dashboard — returns translated content using Claude Haiku
- [ ] No `OPENAI_API_KEY` required anywhere
- [ ] All log calls appear in debug console using `appLogger` format
- [ ] DB writes to `recipe_translation` succeed (not blocked by RLS due to anon key)
