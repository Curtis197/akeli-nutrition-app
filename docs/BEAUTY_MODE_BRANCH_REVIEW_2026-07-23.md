# Beauty Mode (`sdui` branch) — Independent Branch Review

> **Date:** 2026-07-23
> **Scope:** 83 commits, 114 files, ~15,200 insertions, `origin/main...sdui`
> **Method:** 10 independent parallel audits, one per subsystem, each diffing against `origin/main` and reading full file contents rather than trusting `docs/BEAUTY_MODE_ARCHITECTURE_LOG.md`'s self-reported "243-245/245 Flutter, 24/24 Pytest passing" claims.
> **Headline finding:** the "all green" narrative repeated ~40 times in the architecture log does not hold up. Multiple core user flows (viewing your beauty plan, submitting a check-in, generating a plan at all) are broken in ways no existing test catches, several tables have no RLS at all, and CLAUDE.md's two zero-exception mandatory standards (structured logging, l10n) are almost entirely unmet across the branch.

---

## Executive Summary — read this first

| Severity | Count (approx., deduped) |
|---|---|
| Critical | 19 |
| High | 17 |
| Medium | 16 |
| Low | 14 |

### If you fix nothing else, fix these (in rough blast-radius order):

1. **`beauty_plan.is_active` column is referenced by every plan-generation RPC but was never created.** `generate_beauty_plan`, `generate_initial_beauty_plan`, `generate_beauty_plan_from_saved` all fail at runtime with `column "is_active" does not exist`. This means **onboarding-time plan generation cannot work at all** as shipped. (Area B)
2. **`beauty_plan` / `beauty_plan_slot` have zero RLS policies.** Any authenticated user can read, edit, or delete any other user's routine plan/slots. (Area B, C)
3. **Multiple IDOR / broken-auth holes**: `generate_routine_plan`, the current `recommend_recipes` overloads, `complete_beauty_onboarding`, `generate_beauty_shopping_list`, and the payout-breakdown RPCs all lack an `auth.uid() = p_user_id` check that earlier versions of some of these functions actually had — the check was *dropped* in later rewrites. (Area A, B, C)
4. **`activeBeautyPlanProvider` silently returns `null` for every real user with a generated plan** because the nested recipe query never selects `creator_id`, and `Recipe.fromJson` throws on the missing field, swallowed by a catch block. The Care Plan tab, Today's Rituals widget, Analytics page, and shopping list all read this provider — they all silently show "no plan" for a user who has one. (Area E)
5. **Every beauty check-in a user submits is silently discarded.** `beauty_checkin_sheet.dart` builds its payload with snake_case keys; `beauty_analytics_page.dart` reads it back with camelCase keys. Every lookup is `null`, so hardcoded defaults get written to `beauty_log` instead of what the user entered. No test catches this because the one test that exists asserts the sheet's own (wrong) output against itself. (Area F, J)
6. **"Today's Rituals" widget's day filter is wrong for almost every real user.** `dayNumber` is a plan-relative offset from whatever date the plan was generated, not a calendar day-of-month — but the widget compares it to `DateTime.now().day`. Only correct if a user happens to generate their plan on the 1st. (Area F)
7. **The SDUI (Server-Driven UI) subsystem — the branch's namesake feature — is fully-coded, internally correct, and never wired in.** `DynamicLayoutPage`/`WidgetFactory`/`layout_fetch_service` have zero references anywhere else in `lib/`. Multiple planning docs (`SDUI_IMPLEMENTATION_STATUS.md`, `SDUI_IMPLEMENTATION_AUDIT.md`) claim this is "✅ Done"/"production-ready." Beauty Mode actually works today via hardcoded native-widget branching, not SDUI. (Area G)
8. **`health_profile_page.dart`'s "Beauty isolation" refactor deleted working Nutrition-mode functionality** — age/goal-type/weight-goal fields, the pace slider, and all input validation are gone from the Nutrition form, silently regressing the "Nutrition Targets Redesign" work from earlier this project (previously confirmed safe to ship). US-locale users will also now see a blank height field. (Area H)
9. **`test/shared/models/beauty_log_test.dart` does not compile** against the current `BeautyLog` model (references fields removed in a later rewrite). This directly falsifies the "243-245/245 Flutter tests passing" claim for the current commit and everything after it. (Area E, J)
10. **CLAUDE.md's Logging Standard and L10n Standard — both declared "mandatory, zero exceptions" — are essentially unmet across the entire branch**: 11 of 46 new/modified Dart files have zero logger calls; 29 of 31 modified files added zero logging to their new code; **zero lines were ever added to `lib/l10n/app_en.arb` or `app_fr.arb`** across all 83 commits, despite ~130+ hardcoded user-facing strings identified (a floor, not a ceiling). (Area I)
11. Several "mirrored" screens are cosmetic only: **AI chat** (relabeled UI, same nutrition-only backend/system prompt), **profile page** and **saved recipes** (tab labels swap, but underlying providers have no mode filter — nutrition and beauty content mix together), **meal schedule page** (reachable in Beauty mode, 100% nutrition calorie-editor content under a "soins" title). (Area H)
12. **The entire beauty creator payout system is never invoked in production** — no cron job, no edge function wrapper exists for `calculate_creator_payouts` anywhere, unlike Nutrition's dedicated `compute-monthly-revenue` function. Creators are never actually paid by this mechanism despite the detailed revenue-share math. Separately, the same fan-subscription rows are already being counted as revenue by Nutrition's existing ledger — a double-counting risk if this is ever wired up as-is. (Area C)
13. **Zero automated tests exist for any beauty SQL/RPC** — no pgTAP coverage for the payout math, the fan-mode boost, plan generation, or virtue masking, i.e. the layer with the most money/correctness risk has the least test scrutiny of anything in the branch. (Area J)

The rest of this document is the full per-area breakdown.

---

## Area A — SQL: Vector Engine, Virtue Vectors & Recommendation Core

**Files:** `20260720000001-08`, `20260721000003-06,10,15,21` + seed catalogs.

### Well-implemented
- Dimension index mapping (dims 27-49) is internally consistent between SQL and Python — no off-by-one errors.
- Consistent NULL-vector guards before every cosine-distance operation; graceful cold-start fallback to popularity ordering.
- No dynamic SQL/injection risk; allergen exclusion preserved through every rewrite.

### Issues
- **[Critical]** `generate_routine_plan` (`20260720000001.sql:90-126`) — `SECURITY DEFINER`, no `auth.uid() = p_user_id` check. Any user can deactivate/overwrite another user's plan.
- **[Critical]** `recommend_recipes`'s two most recent rewrites (`20260721000006.sql`, `20260721000021.sql`) **dropped** the `auth.uid()` check present in earlier versions of the same function (`20260720000002.sql:40`, `20260720000008.sql:60`). Any user can pull another user's recommendation ranking (privacy leak of hair/skin diagnostics).
- **[High]** The "Hybrid Selective Virtue Masking" migration (`20260721000006.sql`) doesn't actually implement masking in SQL — the real masking logic lives only in Python's `compute_recipe_vector(active_goals=...)`, which **no production caller ever passes** (`main.py` never supplies `active_goals`). The claimed feature doesn't function anywhere in the live pipeline.
- **[High]** `recommend_recipes` has **4 unreconciled overloads** (int-based ×2, varchar-based, text-based) because no version was ever `DROP FUNCTION`'d before `CREATE OR REPLACE`. Two overloads differ only by `varchar` vs `text` param type — exactly the shape that produces PostgREST's `PGRST203 "could not choose the best candidate function"` ambiguity error.
- **[Medium/High]** Duplicate ingredient seed rows: `ingredient` has no unique constraint, so `ON CONFLICT DO NOTHING` in `20260720000009.sql` is a no-op against `20260720000005.sql`'s earlier inserts of the same 9 `active_key`s — these duplicates then fan out into duplicated ingredient-list line items on recipes.
- **[Medium]** `20260721000004_standardize_ingredient_virtue_vectors.sql` **overwrites** (not merges) virtue JSONB for 9 ingredients, silently discarding weights set by earlier migrations (e.g. shea butter loses `growth_retention`, `scalp_soothing`, `sebum_balance`, `glow_brightening`).
- **[Medium]** No `SET search_path` on any new `SECURITY DEFINER` function, despite an existing project precedent fix (`20260603000001_fix_generate_meal_plan_security_definer.sql`) for exactly this class of issue.
- **[Medium]** Fan-mode 1.5x similarity boost is unclamped (can exceed 1.0); currently latent since no Dart caller consumes it, but will misbehave once displayed.
- **[Low]** `product_type`/`is_premade_product` classification is fully wired (DB + Python + Dart filter UI) but every seeded recipe is hardcoded `'diy'` — the `artisanal`/`industrial` paths are unreachable dead code today.
- **[Low]** No `recipe_vector` rows are ever inserted for the ~58 seeded remedies by any migration — recommendations return nothing for them until the external Python batch job is run manually.

---

## Area B — SQL: Beauty Plan Generation, Scheduling & Fan Mode

**Files:** `20260721000001,02,07,08,09,18,19,20,22`.

### Well-implemented
- `recipe.frequency` taxonomy is cleanly seeded across all 5 tiers.
- `beauty_log` (unlike `beauty_plan`) has complete, correctly-scoped RLS.
- Onboarding chain correctly sequences upsert → flag → baseline log → initial plan in one transaction.
- `generate_initial_beauty_plan`'s remainder-of-month date arithmetic is itself correct (no off-by-one).

### Issues
- **[Critical]** `is_active` column never added to `beauty_plan` (see Executive Summary #1) — every generator RPC fails at runtime.
- **[Critical]** No RLS at all on `beauty_plan`/`beauty_plan_slot` (see Executive Summary #2).
- **[High]** The "90% fan-mode quota" (`20260721000022.sql`) is dead code: `v_fan_count`/`v_other_count` are declared and never incremented; `v_max_other_slots` is computed only *after* all slots are already inserted. Contrast with Nutrition's `generate_meal_plan`, which correctly hard-gates every row before insertion. The migration's own "100% parity with Nutrition Mode" claim does not hold.
- **[High]** 2x_month/1x_month branches (`20260721000008/19/22`) call `recommend_recipes` **without** `p_frequency`, so both day-28 calls deterministically return the identical top-1 recipe — users get the same remedy inserted twice under different labels, with no unique constraint to prevent it.
- **[High]** Because `v_day_num` counts from the plan's start date (not calendar day), users who onboard after day ~4-18 of the month silently lose the 2x_month/1x_month slots entirely for that partial month — the majority of onboarding dates are affected.
- **[Medium]** The uncommitted `v_found` fallback (in your working tree) only guards the 2x_week branch — the daily and 1x_week branches have the same zero-rows risk with no fallback, and no migration ever confirms frequency-tagged recipes actually have `recipe_vector` rows to be found by.
- **[Low]** `generate_beauty_plan_from_saved` (both variants) never generates 2x_month/1x_month slots at all — an asymmetry vs. the standard generator.
- **[Low]** The uncommitted change edits an already-applied migration file in place rather than adding a new migration — breaks the append-only convention and would checksum-mismatch any environment that already applied `000008`.

---

## Area C — SQL: Revenue/Payout Engine, Onboarding, Community & Shopping

**Files:** `20260521000003`, `20260721000011-14,16-17`, `20260522000001`, both edge functions.

### Well-implemented
- Edge function JWT verification is genuinely enforced (not decorative) in both onboarding functions.
- `calculate_creator_payouts` recomputes aggregates rather than incrementing, so it's naturally idempotent against unchanged data.
- SDUI layouts migration and community "My Groups" query correctly use mode-scoping — the pattern was known, just not applied everywhere (see Area H).

### Issues
- **[Critical]** `complete_beauty_onboarding` RPC has no `auth.uid()` check — any authenticated client can call it directly (bypassing the edge function entirely) and overwrite another user's health profile and beauty plan.
- **[Critical]** Cross-system double-counting: Beauty's `calculate_creator_payouts` and Nutrition's existing `compute-monthly-revenue` both independently recognize the same `fan_subscription` rows as revenue, with no reconciliation between the two ledgers.
- **[High]** No authorization check on `get_creator_beauty_payout_breakdown`, `get_platform_retained_beauty_revenue`, `get_creator_beauty_revenue_share` — any user can query any creator's/platform's financial data.
- **[High]** The entire beauty payout system has no cron/edge-function invocation anywhere — creators are never actually paid by this mechanism as shipped, despite "tested live" claims in the architecture log.
- **[High]** `calculate_creator_payouts` has 2 coexisting overloads (1-arg legacy over dead tables `beauty_care_logs`/`fan_allocations`, and the real 2-arg version) — ambiguous call resolution risk.
- **[High]** `BEAUTY_MODE_REMUNERATION_AUDIT.md` documents a different, abandoned system (wrong migration filename, describes a tokenized model that was never shipped) and its own checklist is unchecked — it isn't evidence of anything, despite reading like an audit sign-off.
- **[High]** Community "Browse Groups" (as opposed to "My Groups") has **no** mode filter — Beauty groups leak into Nutrition mode's discovery feed and vice versa.
- **[Medium]** `get_platform_retained_beauty_revenue` doesn't filter out slots with no `creator_id` (the ~50 starter recipes have none), overstating what's reported as "creator payout" and understating "platform retained."
- **[Medium]** `creator_monthly_payouts` RLS policy compares `auth.uid() = creator_id`, but `creator_id` is a separate table's PK, not the user's own UID — legitimate creators can never see their own payout row through this policy (the correct idiom is used correctly elsewhere in the codebase, just not here).
- **[Medium]** No idempotency guard once a payout is `'paid'` — a later re-run can silently overwrite the recorded amount with no audit trail.
- **[Medium]** `generate_beauty_shopping_list` — same IDOR pattern as above, no `auth.uid()` check on `p_beauty_plan_id`.
- **[Medium]** `complete-beauty-onboarding/index.ts` violates the mandatory Deno logging standard — no `logRLSCheck`/`logQueryResult` around its DB write, and its catch-all omits `stack: e.stack`.
- **[Low]** `revenue_value = ROUND(1/N, 6)` doesn't guarantee slot sums equal exactly 1.0 (sub-cent drift only, not currently a real-world risk).
- **[Low]** The Python-vectorization trigger fire-and-forget in the edge function treats any non-2xx HTTP response as "success" (only network-level rejection is caught) — a pre-existing gap in Nutrition's onboarding, now duplicated onto Beauty's.

---

## Area D — Python Vectorization Engine

**Files:** `python/engine/vectorization.py`, `database.py`, `main.py`, both test files.

### Well-implemented
- Premade-vs-DIY dispatch is genuinely mutually exclusive and backed by a real test.
- Selective virtue masking correctly preserves physical dims while zeroing goal dims — and is properly tested (unlike the SQL layer's version of the same feature, which doesn't exist — see Area A).
- Creator-vector centroid math is correctly normalized with real numeric-outcome tests.

### Issues
- **[Critical]** The nightly batch (`main.py:188`) calls `compute_user_vector(user_id)` with **no mode argument**, defaulting to `"nutrition"`. There is no schema column to infer mode from. Any Beauty-mode user whose vector gets refreshed by the nightly batch has their 50D beauty vector **silently overwritten with nutrition-only data**. The existing test for this mocks the function entirely and never asserts what mode it was called with.
- **[High]** `get_active_users()` only queries nutrition-tracking tables, never `beauty_log` — a pure-beauty user (no nutrition logs) never appears in the nightly refresh population at all, so their vector never updates after onboarding either. Combined with the above: there is no code path that correctly refreshes a beauty vector.
- **[High]** `DIM_SCALP_TYPE` (dim 29) is defined and documented but **never written anywhere** — no spectrum dict exists for it, and the DB doesn't even store a graded scalp-type value. One full documented dimension of the "50D vector" is permanently 0.0, with no test asserting on index 29.
- **[High]** 3 of the 15 hair-type options offered in onboarding (Locks, Transition, Protective-style) have no entry in `HAIR_TYPE_SPECTRUM` and silently fall back to a near-max default (0.85-0.90) with zero logging — users who pick these common options are silently miscoded as a generic 4B texture.
- **[Medium]** Beauty tests assert loose bounds (`vector[i] > 0.0`) rather than the documented exact spectrum values — would not catch a materially wrong weight.
- **[Medium]** Recipe-side skin-type encoding hardcodes a lower cap (0.90) than the user-side spectrum's max (1.00 for "acne"), violating the file's own stated invariant that a dimension means the same thing on both sides.
- **[Medium]** The 2x goal-weight amplification is applied to only 6 of 18 goal/virtue dims, with no documentation anywhere explaining why those 6 and not the other 12 — reads as an arbitrary omission that under-ranks users pursuing the other 12 goals.
- **[Low]** Missing-field fallback defaults (`porosity or "high"`, `skin_type or "oily"`) skew to spectrum extremes, inconsistent with the DB's own neutral defaults (`'medium'`, `'combination'`).
- **[Low]** Doc/code mismatch: architecture log claims `1A-1C=0.10`; code actually has `1C: 0.15`.
- **[Low]** Broad `except Exception: pass` around check-in-boost fetch, no logging — indistinguishable from "no check-in yet."

---

## Area E — Flutter: Models & Providers

**Files:** `beauty_log.dart`, `beauty_plan.dart`, `recipe.dart`, `user_profile.dart`, `health_profile_model.dart`, and 7 providers.

### Well-implemented
- `mode_provider.dart` has genuinely good provider-lifecycle logging and a real graceful-fallback path for a corrupt/missing persisted mode.
- `ShoppingListNotifier`'s beauty branch correctly and consistently scopes to `beauty_plan_id` throughout — no cross-contamination with nutrition lists.
- `revenueValue` parses correctly as `double`; taxonomy fields use safe `?? fallback` rather than throwing enum parsers.

### Issues
- **[Critical]** `activeBeautyPlanProvider`'s recipe embed never selects `creator_id`; `Recipe.fromJson` throws on the missing required field; the exception is swallowed by a catch-and-log — **the provider always resolves to `null` for any real generated plan.** Every screen depending on it (planner, today-widget, analytics, shopping list) silently shows empty state.
- **[Critical]** `test/shared/models/beauty_log_test.dart` references fields (`protectiveStyleActive`, `routineCompliancePct`) and a constructor param (`createdAt`) that don't exist on the current `BeautyLog` model — confirmed via `dart analyze` (7 errors). This test cannot compile, contradicting every "243-245/245 passing" claim from this commit onward.
- **[High]** `Recipe.copyWith()` was never updated for the 10 new beauty fields (`mode`, `beautyType`, `virtueWeights`, etc.) — they silently reset to constructor defaults on every `.copyWith()` call. This fires on **every non-French-locale recipe fetch** via the translation-application path, wiping beauty classification for English-locale users browsing beauty content.
- **[High]** Beauty-only feed filters (`productType`/`routineCategory`/`beautyGoal`) are never cleared on mode switch — a filter left set from Beauty mode silently zeroes out the entire Nutrition feed after switching modes, since nutrition recipes never match the beauty-only taxonomy columns the server-side `AND` requires.
- **[High]** `beauty_plan_provider.dart` (the whole file) has **zero** provider-lifecycle logging (no `build()`/`onDispose` logs) and 3 of its 4 DB/RPC writes (`toggleCompletion`, `generatePlan`, `addLog`) log only on the error path — no BEFORE/AFTER logging at all, in direct violation of CLAUDE.md's mandatory pattern.
- **[Medium]** `completeBeautyOnboarding()` in `user_profile_provider.dart` has no AFTER log on the edge-function success path and no logging at all around its RPC fallback — a silent failure there propagates with zero diagnostic signal.

---

## Area F — Flutter: Beauty-Specific UI Pages & Widgets

**Files:** `beauty_analytics_page.dart`, `beauty_onboarding_page.dart`, `beauty_checkin_sheet.dart`, `today_beauty_routines_widget.dart`, `beauty_planner_view.dart`, `color_set_modal.dart`, `mode_selector.dart`.

### Well-implemented
- `beauty_analytics_page_test.dart` and `beauty_onboarding_page_test.dart` genuinely assert computed values (percentage math, hair-growth delta), not just widget presence.
- `mode_selector.dart` has the best logging coverage of any file in the branch (`userAction` on dialog open and mode switch).
- `BeautyOnboardingPage`'s submit handler correctly guards `setState`/navigation with `mounted` checks.
- `BeautyPlannerView` correctly buckets slots by frequency tier and this is actually tested.

### Issues
- **[Critical]** Check-in key-casing mismatch (see Executive Summary #5) — every submitted check-in is silently discarded.
- **[Critical]** "Today's Rituals" day-number filter bug (see Executive Summary #6) — broken for almost all real users.
- **[High]** Time-range chips (7J/30J/90J/Tout) on the Analytics page are purely cosmetic — `_selectedTimeframe` is set but never read anywhere that affects the displayed data.
- **[High]** 5 of 7 files in this area have **zero** `appLogger` calls (`beauty_analytics_page.dart` even imports the logger but never instantiates/calls it); all 7 have **zero** `AppLocalizations` usage, and neither ARB file has a single Beauty-related key. ~130+ hardcoded strings identified branch-wide.
- **[High]** `ColorSetModal` is unreachable dead code — no screen anywhere calls `.show()` on it, and even if it were wired up, its selection has no persistence mechanism and never feeds into the actual theme (`getAppModeColor`/`buildLightTheme`/`buildDarkTheme` are a hardcoded switch with no external input).
- **[High]** Visible in-session color inconsistency: `today_beauty_routines_widget.dart` and `beauty_planner_view.dart` hardcode Nutrition's teal `AkeliColors.primary`, while `beauty_analytics_page.dart`/`beauty_onboarding_page.dart` hardcode their own local Rosewood/Gold constants — neither reads the shared mode-reactive theme, and the two pairs visibly disagree with each other within the same Beauty session.
- **[Medium]** `BeautyCheckinSheet` has no UI control at all for `hairThicknessScore` or `skinClarityScore` (both required `BeautyLog` fields collected at onboarding) — they can never be updated by a returning user. `hairSheddingRate` is likewise hardcoded to `'normal'` with no way to change it from this sheet.
- **[Medium]** `beauty_onboarding_page.dart` logging is partial: no dispose log, 4 of 5 navigation taps unlogged, RPC call has ERROR logging only (no BEFORE/AFTER).
- **[Low]** Check-in sliders never pre-fill from the user's last log (continuity gap, not a crash).

---

## Area G — Flutter: Core Mode-Switching Infrastructure (router/theme/SDUI/shell)

**Files:** `router.dart`, `theme.dart`, `lib/core/sdui/**`, `main_shell.dart`, `main.dart`.

### Well-implemented
- SDUI's internal code (cache keying, defensive casting, unknown-component handling) is genuinely well-built and follows the project's own documented past lessons (`docs/sdui-workflow-and-cautions.md`) — the problem is entirely that it's never connected (see below), not that it's poorly written.
- Layout cache is correctly mode-keyed, so switching modes can't serve stale cross-mode layout data if it were ever used.
- `main.dart`'s Hive bootstrap ordering is correct; theme genuinely rebuilds reactively on mode switch via `ref.watch(currentModeProvider)`.

### Issues
- **[Critical]** Router can enter an infinite redirect loop (`/onboarding → /onboarding/beauty → /onboarding → ...`), which go_router's own loop detection turns into a hard `GoException` crash, for any user whose device has a stale `AppMode.beauty` selection (e.g. from a previous account on the same device/simulator) combined with incomplete nutrition onboarding.
- **[Critical]** The SDUI subsystem is fully dead code (see Executive Summary #7) — router never routes to `DynamicLayoutPage`; multiple planning docs falsely claim this is done and production-ready.
- **[High]** The beauty-onboarding guard checks `currentMode`, not the destination route — a user can navigate directly to `/beauty-analytics` (deep link, bookmark, browser back/forward on the `web/` target) while `currentMode == nutrition`, bypassing the onboarding gate entirely.
- **[Medium]** Duplicate `GoRoute` registration for `/onboarding` (copy-paste artifact; harmless since go_router takes first match, but dead code that should have been caught in review).
- **[Medium]** `main_shell.dart:47` hardcodes `'Routines'`/`'Remèdes'` tab labels directly in the same array as three properly-localized `l10n.*` values — and the file has zero logger calls despite being the highest-traffic modified file on the branch.
- **[Low]** Architecture log's dark-theme coverage claim doesn't hold — `buildDarkTheme()` never defines the five component themes the changelog describes as updated (pre-existing gap, not a regression from this branch).
- **[Low]** `dynamic_layout_page.dart` has hardcoded English error strings — moot today since it's unreachable, but needs fixing before ever wiring it in.
- **[Low]** The mode-switcher dialog itself hardcodes a teal header icon regardless of active mode — the exact "hardcoded primary creates visible inconsistency" pattern this session was otherwise trying to fix.

---

## Area H — Flutter: Existing-Screen Mode Mirroring

**Files:** 23 pre-existing screens/widgets this branch was supposed to make mode-aware (settings, nutrition, meal planner, recipes, community, profile, support, AI assistant, auth/onboarding) + `home_page.dart`.

**This is the area that most directly matches your own suspicion — "some well made, other completely missed." Per-screen verdict:**

### Done well (genuinely deep, not cosmetic)
- `home_page.dart` — full data-source swap, working-tree theme refactor now fully consistent.
- `nutrition_page.dart` — clean page-swap to `BeautyAnalyticsPage`, backed by real distinct providers, properly tested across both modes.
- `meal_planner_page.dart` — real `BeautyPlannerView` swap.
- `feed_page.dart` — genuinely deep: filter UI → provider → RPC → SQL, all wired correctly (though see l10n gap below).
- `community_page.dart` — real data-level isolation via `.eq('app_mode', ...)` on reads and writes.
- `settings_page.dart` — correct per-mode routing and a fully-completed theme-color refactor.
- `health_profile_page.dart` — structurally split into real distinct forms per mode... **but see Critical regression below.**

### Missed or only cosmetic
- **[Critical]** `health_profile_page.dart`'s Nutrition-mode form lost age/goal-type/weight-goal/pace-slider fields and all input validation in the process of "isolating" Beauty fields — a real functional regression, plus a blank-height-field bug for US-locale users.
- **[Critical]** `meal_schedule_page.dart` — reachable from Settings in Beauty mode ("Planification des Soins"), but its body is 100% the nutrition calorie-percentage editor with zero further mode branching.
- **[Critical]** `ai_chat_page.dart` — title/colors/suggestion chips relabeled for Beauty, but the actual chat call sends no mode flag and the edge function's system prompt is hardcoded nutrition-only and untouched by this branch. Users talking to "Assistant Beauté" get the nutrition assistant.
- **[High]** `profile_page.dart` — only the two tab *labels* change; the underlying liked-recipes provider has no mode filter, so nutrition and beauty content are mixed together under whichever label is showing.
- **[High]** `saved_recipes_page.dart` — same pattern; reachable from Settings in Beauty mode, same mixing.
- **[Medium]** `nutrition_plan_page.dart` — title-only swap over an irrelevant macro-editor body (currently unreachable in Beauty mode, but latent).
- **[Medium]** `meal_planner_view_toggle.dart`'s new "Month" view segment is unreachable in either mode — `meal_planner_page.dart`'s beauty branch bypasses this widget entirely.
- **[Medium]** `health_profile_page_beauty_test.dart` only tests Beauty mode — structurally could never have caught the Nutrition-mode regression above.
- **[Low]** `onboarding_page.dart`/`onboarding_data.dart` have zero mode-awareness and write hardcoded placeholder beauty defaults for every new signup regardless of chosen mode (low impact since `BeautyOnboardingPage` later overwrites real values for beauty users).
- **[High, cross-cutting]** Systemic l10n violations across nearly every file in this list — dozens of hardcoded French strings, zero ARB changes anywhere on the branch (detailed fully in Area I).

---

## Area I — CLAUDE.md Compliance: Logging Standard + L10n Standard

CLAUDE.md declares both standards **mandatory, zero exceptions**, for every Dart file and Deno function touched. Reality across this branch's 46 non-test Dart files + 2 Deno files:

- **Logging:** 11 of 46 files (24%) have zero logger calls at all — including files with a dead `import logger.dart` never instantiated. Of the 31 pre-existing files this branch modified, **29 (94%) added zero logging to their new code**, even though the surrounding file already had logging infrastructure in place — i.e., the pattern was known and simply not extended to new work. Reference density in CLAUDE.md's own example files is ~1 log call per 10-13 lines; nothing in this branch comes close.
- **L10n:** `git diff --stat` on both `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` returns **completely empty** across all 83 commits. Every one of ~130+ identified hardcoded user-facing strings (a floor — several large-diff files were spot-checked, not exhaustively enumerated) is a direct violation. Some files (`beauty_checkin_sheet.dart`) are hardcoded in English while every sibling Beauty screen is hardcoded in French — meaning the branch is internally inconsistent on language even before considering the ARB gap. `mode_provider.dart`/`mode_selector.dart` hardcode all app-mode names/descriptions in French with no English variant at all.
- The single new Deno edge function (`complete-beauty-onboarding`) has the outer ENTRY/EXIT/catch-all skeleton but never calls the mandated `logRLSCheck`/`logQueryResult` helpers around its actual DB write.

**This is not a matter of individual missed spots — it is a systemic, branch-wide pattern.** Any implementation plan should treat "add logging" and "add l10n" as their own dedicated, mechanical passes across every touched file, not as an afterthought bundled into functional fixes.

---

## Area J — Test Coverage & Validity

- **`beauty_log_test.dart` does not compile** against the current model (see Executive Summary #9) — the single clearest falsification of the "243-245/245" narrative.
- **Zero SQL/RPC test coverage exists anywhere** for the payout engine, the fan-mode boost, plan generation, or virtue masking — confirmed via `supabase/tests/` containing no beauty-related file at all. The highest-risk logic (money, recommendations) has the least scrutiny.
- Several tests are **misleading rather than just shallow** — they pass specifically *because* they assert a buggy component's own output against itself, rather than the real integration point where the bug lives:
  - `beauty_checkin_sheet_test.dart` — asserts the sheet's own (wrong) key names; cannot catch the camelCase/snake_case bug.
  - `today_beauty_routines_widget_test.dart` — its mock fixture sets `dayNumber: now.day`, artificially satisfying the buggy day filter.
  - `color_set_modal_test.dart` — tests a modal that isn't wired into the app anywhere; the "applies app-wide" narrative has no code path to even test.
  - `beauty_onboarding_page_test.dart` — never taps the final submit button, so the one meaningfully risky code path (actual onboarding completion + plan generation) is never exercised.
- The architecture log's own Flutter test-count claims (`243` → `245` → `244`) are never reconciled to a stable final number across successive entries — it reads as a repeated incantation, not a verified fact. (The Python count of 24 is at least numerically accurate.)
- Where tests do assert real values (`beauty_analytics_page_test.dart`, `nutrition_page_beauty_test.dart`, `beauty_log_test.dart`'s JSON round-trip logic itself, `meal_planner_view_toggle_test.dart`), they're genuinely solid — the problem is inconsistency, not universal shallowness.

---

## Suggested next step

This is far too much to fix in one pass. Before writing the implementation plan, we should agree on scope and sequencing — see the questions in chat.
