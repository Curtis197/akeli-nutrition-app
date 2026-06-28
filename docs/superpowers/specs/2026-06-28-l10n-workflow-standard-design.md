# L10n Workflow Standard & Full Retrofit Design

**Date:** 2026-06-28
**Status:** Approved

## Context

Akeli already has a complete l10n infrastructure:
- `l10n.yaml` configured with `app_en.arb` as template, output class `AppLocalizations`
- `app_en.arb` + `app_fr.arb` with ~250 strings covering most screens
- `AppLocalizations` generated files (`app_localizations_en.dart`, `app_localizations_fr.dart`)
- `LocaleNotifier` (Riverpod) persisting locale to `user_profile.locale` in Supabase
- `MaterialApp.router` fully wired with `locale`, `supportedLocales`, `localizationsDelegates`
- 39 of ~55 feature files already calling `AppLocalizations.of(context)` correctly

**Gap:** ~15 pages/widgets still have hardcoded user-visible strings. No enforcement rule exists in CLAUDE.md.

## Goal

1. Add a mandatory l10n standard to CLAUDE.md (parallel to the logging standard).
2. Retrofit all ~15 non-compliant files to be fully multilanguage.

## Approach

**Sequential batching (Approach A):** CLAUDE.md is updated first, then files are retrofitted in 4 batches. ARB files are updated once per batch to avoid conflicts. French translations are written at the same time as English — never deferred.

---

## Section 1 — CLAUDE.md L10n Standard

A new mandatory section added to `CLAUDE.md`, structured identically to the existing Logging Standard block.

### Rules

1. **No hardcoded user-visible strings** in any widget or page — zero exceptions.
2. **ARB-first**: every new string is added to both `app_en.arb` AND `app_fr.arb` before it appears in Dart code.
3. **Access pattern**: resolve `AppLocalizations` at build time:
   ```dart
   import 'package:akeli/l10n/app_localizations.dart';
   // inside build():
   final l10n = AppLocalizations.of(context);
   ```
4. **Key naming**: `<screen>_<key>` camelCase — e.g., `legalPrivacyTitle`, `journeyGoalsCalories`. Keys shared across multiple unrelated widgets use the existing `common_` bucket (e.g., `commonCancel`, `commonLoading`).
5. **Outside widget tree** (FCM handlers, background callbacks): use the root context fallback:
   ```dart
   AppLocalizations.of(rootScaffoldMessengerKey.currentContext!)?.notificationSeeLabel ?? 'View'
   ```
6. **Providers and notifiers never resolve l10n strings** — string resolution belongs exclusively at the widget layer.
7. **Plurals and placeholders** use the standard ARB format:
   ```json
   "screenItemCount": "{count, plural, one{{count} item} other{{count} items}}",
   "@screenItemCount": { "placeholders": { "count": { "type": "int" } } }
   ```

---

## Section 2 — Retrofit Scope & Batching

### Batch 1 — Shared Widgets
Files done first because feature pages may render them.

| File | Notes |
|------|-------|
| `lib/features/settings/widgets/allergen_picker_widget.dart` | Allergen names, labels |
| `lib/features/settings/widgets/settings_widgets.dart` | Shared setting row labels |
| `lib/features/home/home_creator_chip.dart` | Creator chip labels |
| `lib/features/recipes/widgets/ingredient_detail_sheet.dart` | Ingredient detail strings |
| `lib/features/cooking/cooking_session_bottom_sheet.dart` | Cooking session UI strings |

### Batch 2 — Journey/Nutrition Sub-widgets

| File | Notes |
|------|-------|
| `lib/features/nutrition/widgets/journey/journey_calendar.dart` | Month/day labels, empty state |
| `lib/features/nutrition/widgets/journey/journey_summary_row.dart` | Summary row labels |
| `lib/features/nutrition/widgets/journey/journey_goals_card.dart` | Goals card labels |

### Batch 3 — Feature Pages

| File | Notes |
|------|-------|
| `lib/features/subscription/subscription_page.dart` | Many keys already exist in ARB (`subscriptionTitle`, etc.) |
| `lib/features/journaling/journaling_bottom_sheet.dart` | Likely needs new `journaling_*` keys |
| `lib/features/ai_assistant/ai_chat_page.dart` | `aiAssistantTitle`, `aiAssistantPlaceholder`, `aiAssistantSend` already in ARB |
| `lib/features/referral/referral_page.dart` | `referralTitle`, `referralCopyCode`, `referralCodeCopied` already in ARB |
| `lib/features/support/support_page.dart` | `supportTitle` already in ARB |
| `lib/features/settings/saved_recipes_eligibility_page.dart` | Likely needs new `savedRecipesEligibility_*` keys |

### Batch 4 — Legal Pages + main.dart fix

| File | Notes |
|------|-------|
| `lib/features/legal/privacy_policy_page.dart` | Needs `legal_*` keys |
| `lib/features/legal/terms_of_service_page.dart` | Needs `legal_*` keys |
| `lib/main.dart` | Hardcoded `'Voir'` → `notificationSeeLabel` (already in ARB); use `rootScaffoldMessengerKey.currentContext` |

---

## Section 3 — Per-File Retrofit Workflow

For every file in every batch:

1. **Audit** — read file, list every hardcoded user-visible string literal.
2. **ARB update** — add missing keys to both `app_en.arb` AND `app_fr.arb` simultaneously. French is written immediately (not placeholder-deferred). Keys already present in the ARB are reused as-is.
3. **Wire** — add `import 'package:akeli/l10n/app_localizations.dart';`, add `final l10n = AppLocalizations.of(context);` in `build()`, replace every hardcoded string with `l10n.<key>`.
4. **Generate** — run `flutter gen-l10n` once per batch (after all ARB edits in that batch), not per file.
5. **Verify** — `flutter analyze` passes; no remaining string literals in the UI layer of the file.

**CLAUDE.md is committed before any retrofit work starts**, so the rule is live from the first file touched.

---

## ARB Key Naming Reference

| Screen/Widget | Prefix |
|---------------|--------|
| Allergen picker | `allergenPicker_` |
| Settings widgets | `settingsWidget_` |
| Home creator chip | `creatorChip_` |
| Ingredient detail | `ingredientDetail_` |
| Cooking session | `cookingSession_` |
| Journey calendar | `journeyCalendar_` |
| Journey summary row | `journeySummary_` |
| Journey goals card | `journeyGoals_` |
| Subscription page | `subscription_` (many already exist) |
| Journaling | `journaling_` |
| AI assistant | `aiAssistant_` (already exist) |
| Referral | `referral_` (already exist) |
| Support | `support_` (already exist) |
| Saved recipes eligibility | `savedRecipesEligibility_` |
| Legal | `legal_` |

---

## Out of Scope

- Model/domain files (`health_profile_model.dart`, `allergen_model.dart`, `recipe_tracking.dart`, etc.) — no UI strings, no l10n needed.
- Adding new languages beyond EN/FR — separate initiative.
- Lint/CI enforcement (e.g., custom lint rule to ban string literals) — can be a follow-up.
