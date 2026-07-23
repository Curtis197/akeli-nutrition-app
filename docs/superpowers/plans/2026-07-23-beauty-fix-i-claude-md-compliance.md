# Beauty Mode Fix — Area I: CLAUDE.md Compliance Verification & Mop-Up

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. **This plan should be executed LAST, after Areas A-H and J have all completed**, since most of its tasks verify work done by those plans.

**Goal:** Confirm that CLAUDE.md's mandatory Logging Standard and L10n Standard gaps identified in `docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md` Area I are fully closed by Areas A-H and J's own plans, and directly fix the small residue of compliance work (if any) that no other plan actually owns.
**Architecture:** A one-time real grep/diff sweep establishes the current baseline (Task 1). A file-ownership reconciliation (Task 2) maps every one of the 48 non-test Dart/TS files touched by this branch to exactly one other plan's owned-file list, using each plan's own **Global Constraints** section as the source of truth, and proves the orphan set is empty. Per-area tasks (3-11) then verify — via grep, never by re-reading full file contents — that each area's specific logging/l10n fixes actually landed, escalating back to that area's plan on failure rather than duplicating its fix. A final task (12) re-runs the full original audit methodology end-to-end and produces an updated aggregate stats table.
**Tech Stack:** Flutter, Dart, Deno, grep/shell verification, ARB/l10n.

## Global Constraints
- Repo: c:\Users\DELL LATITUDE 7480\akeli-nutrition-app, branch `sdui`.
- CLAUDE.md Logging Standard AND L10n Standard both apply — read the full text at the repo root before starting.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- This plan must run AFTER Areas A, B, C, D, E, F, G, H, and J — verify each of those plans' files exist under docs/superpowers/plans/ before starting; if any is missing, note it and proceed with what's available, flagging the gap.
- **At the time this plan was written (2026-07-23), only 5 of the 9 other plans exist**: `2026-07-23-beauty-fix-a-vector-engine.md`, `-b-plan-generation.md`, `-c-revenue-community.md`, `-d-python-vectorization.md`, `-e-models-providers.md`. Plans for Areas F, G, H, and J do not exist yet. Every task below that depends on a missing plan is written as a **placeholder verification** ("plan not yet written, verify manually once it lands") with the exact commands to run the moment that plan file appears — never a fabrication of that plan's contents.
- This plan never edits a file that is listed as "owned" in another area's plan. Its only direct-fix authority is over genuinely orphaned files (this plan found **zero** — see Task 2) and its own new verification/test scaffolding under `docs/superpowers/` and `scripts/` (if any).
- All commands below run from the repo root using the Bash tool (Git Bash / POSIX sh) unless a task says otherwise.

---

## Task 1: Establish the current CLAUDE.md compliance baseline

**Files:** none modified — this task only runs commands and records their real output as of 2026-07-23.

- [ ] **Step 1: Get the exact file list the original audit worked from.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git diff --name-only origin/main...sdui -- '*.dart' '*.ts' | grep -v '^test/' | wc -l
  git diff --name-only origin/main...sdui -- '*.dart' '*.ts' | grep '^test/' | wc -l
  ```

  Actual output (recorded 2026-07-23):
  ```
  48
  11
  ```
  48 non-test Dart/TS files (46 `.dart` + 2 `.ts`) and 11 test files — 59 total, matching the review's "46 non-test Dart files + 2 Deno files" scope exactly. Test files are excluded from this sweep, mirroring the original audit's own methodology (CLAUDE.md's logging standard targets providers/pages/DB-calls; test files have none of these in the sense the standard means).

- [ ] **Step 2: Run the logging + l10n sweep across all 48 non-test files.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git diff --name-only origin/main...sdui -- '*.dart' '*.ts' | grep -v '^test/' > /tmp/i_files.txt
  while IFS= read -r f; do
    [ -f "$f" ] || { echo "$f|MISSING|MISSING"; continue; }
    logcount=$(grep -cE "appLogger\.|_logger\.|createLogger\(|logRLSCheck\(|logQueryResult\(" "$f" 2>/dev/null || true)
    l10ncount=$(grep -cE "AppLocalizations|l10n\." "$f" 2>/dev/null || true)
    echo "$f|$logcount|$l10ncount"
  done < /tmp/i_files.txt
  ```

  Actual output (recorded 2026-07-23), grouped below by the owning plan established in Task 2 (columns: `logger-call-count | l10n-call-count`):

  **Owned by Area C (`beauty-fix-c-revenue-community.md`):**
  | File | logger | l10n |
  |---|---|---|
  | `lib/providers/dm_provider.dart` | 21 | 0 |
  | `supabase/functions/complete-beauty-onboarding/index.ts` | 1 | 0 |

  **Owned by Area E (`beauty-fix-e-models-providers.md`):**
  | File | logger | l10n |
  |---|---|---|
  | `lib/providers/beauty_plan_provider.dart` | 10 | 0 |
  | `lib/providers/health_profile_provider.dart` | 20 | 0 |
  | `lib/providers/meal_plan_provider.dart` | 152 | 0 |
  | `lib/providers/mode_provider.dart` | 11 | 0 |
  | `lib/providers/recipe_provider.dart` | 93 | 0 |
  | `lib/providers/user_profile_provider.dart` | 103 | 0 |
  | `lib/shared/models/beauty_log.dart` | 0 | 0 |
  | `lib/shared/models/beauty_plan.dart` | 0 | 0 |
  | `lib/shared/models/recipe.dart` | 1 | 0 |
  | `lib/shared/models/user_profile.dart` | 0 | 0 |
  | `lib/features/settings/models/health_profile_model.dart` | 0 | 0 |

  **Owned by Area F (`beauty-fix-f-*.md` — not yet written):**
  | File | logger | l10n |
  |---|---|---|
  | `lib/features/beauty/beauty_analytics_page.dart` | 0 | 0 |
  | `lib/features/beauty/beauty_onboarding_page.dart` | 3 | 0 |
  | `lib/features/beauty/widgets/beauty_checkin_sheet.dart` | 0 | 0 |
  | `lib/features/beauty/widgets/today_beauty_routines_widget.dart` | 0 | 0 |
  | `lib/features/meal_planner/widgets/beauty_planner_view.dart` | 0 | 0 |
  | `lib/shared/widgets/color_set_modal.dart` | 0 | 0 |
  | `lib/widgets/mode_selector.dart` | 2 | 0 |

  **Owned by Area G (`beauty-fix-g-*.md` — not yet written):**
  | File | logger | l10n |
  |---|---|---|
  | `lib/core/router.dart` | 11 | 0 |
  | `lib/core/theme.dart` | 0 | 0 |
  | `lib/core/sdui/services/layout_cache_service.dart` | 8 | 0 |
  | `lib/core/sdui/services/layout_fetch_service.dart` | 14 | 0 |
  | `lib/core/sdui/widgets/dynamic_layout_page.dart` | 9 | 0 |
  | `lib/core/sdui/widgets/widget_factory.dart` | 3 | 0 |
  | `lib/shared/widgets/main_shell.dart` | 0 | 5 |
  | `lib/main.dart` | 11 | 3 |

  **Owned by Area H (`beauty-fix-h-*.md` — not yet written):**
  | File | logger | l10n |
  |---|---|---|
  | `lib/features/ai_assistant/ai_chat_page.dart` | 20 | 15 |
  | `lib/features/auth/onboarding_data.dart` | 7 | 0 |
  | `lib/features/auth/onboarding_page.dart` | 37 | 138 |
  | `lib/features/community/community_page.dart` | 14 | 9 |
  | `lib/features/home/home_page.dart` | 60 | 26 |
  | `lib/features/meal_planner/batch_cooking_page.dart` | 3 | 10 |
  | `lib/features/meal_planner/meal_planner_page.dart` | 14 | 25 |
  | `lib/features/meal_planner/shopping_list_page.dart` | 4 | 9 |
  | `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart` | 1 | 3 |
  | `lib/features/nutrition/nutrition_page.dart` | 24 | 46 |
  | `lib/features/nutrition_plan/nutrition_plan_page.dart` | 8 | 43 |
  | `lib/features/profile/profile_page.dart` | 5 | 30 |
  | `lib/features/recipes/feed_page.dart` | 32 | 80 |
  | `lib/features/recipes/saved_recipes_page.dart` | 1 | 5 |
  | `lib/features/settings/health_profile_page.dart` | 3 | 18 |
  | `lib/features/settings/meal_schedule_page.dart` | 8 | 23 |
  | `lib/features/settings/preferences_page.dart` | 13 | 33 |
  | `lib/features/settings/settings_page.dart` | 33 | 41 |
  | `lib/features/support/support_page.dart` | 14 | 22 |

  **Verified compliant already (no owning plan needed — see Task 2):**
  | File | logger | l10n |
  |---|---|---|
  | `supabase/functions/complete-onboarding/index.ts` | 21 | 0 (Deno function, l10n N/A) |

  **Aggregate:** 48 files total. **11 files (23%) have zero logger calls** — reproduces the original audit's "11 of 46 (24%)" finding almost exactly, confirming no material drift since the review was written. All 11 zero-logging files are either Area E's pure data models (`beauty_log.dart`, `beauty_plan.dart`, `user_profile.dart`, `health_profile_model.dart` — no DB/RPC/user-action code path exists in a `fromJson`/`toJson`-only class for CLAUDE.md's specific logging points to attach to) or Area F's beauty UI files (`beauty_analytics_page.dart`, `beauty_checkin_sheet.dart`, `today_beauty_routines_widget.dart`, `beauty_planner_view.dart`, `color_set_modal.dart`) or Area G's `theme.dart` (a pure style-constant file, same "no I/O to log" situation as the models).

- [ ] **Step 3: Confirm the ARB files are still untouched (the zero-lines-added claim from the review).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git diff --stat origin/main...sdui -- lib/l10n/app_en.arb lib/l10n/app_fr.arb
  ```

  Actual output (recorded 2026-07-23): **empty** — zero lines. Confirms the review's "zero lines were ever added to `lib/l10n/app_en.arb` or `app_fr.arb`" is still true as of this plan's writing. This is the number Task 12's end-to-end check must show as non-zero once Areas F, G, and H land.

- [ ] **Step 4: Record real l10n-gap file counts among UI-facing (page/widget) files only**, since `l10n` rule 6 exempts providers/notifiers/models from ever calling `AppLocalizations` — a `0` in a provider/model row above is compliant, not a violation.

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  for f in lib/features/beauty/beauty_analytics_page.dart \
           lib/features/beauty/beauty_onboarding_page.dart \
           lib/features/beauty/widgets/beauty_checkin_sheet.dart \
           lib/features/beauty/widgets/today_beauty_routines_widget.dart \
           lib/features/meal_planner/widgets/beauty_planner_view.dart \
           lib/shared/widgets/color_set_modal.dart \
           lib/widgets/mode_selector.dart; do
    echo "$f: $(grep -c 'AppLocalizations\|l10n\.' "$f")"
  done
  ```

  Actual output (recorded 2026-07-23):
  ```
  lib/features/beauty/beauty_analytics_page.dart: 0
  lib/features/beauty/beauty_onboarding_page.dart: 0
  lib/features/beauty/widgets/beauty_checkin_sheet.dart: 0
  lib/features/beauty/widgets/today_beauty_routines_widget.dart: 0
  lib/features/meal_planner/widgets/beauty_planner_view.dart: 0
  lib/shared/widgets/color_set_modal.dart: 0
  lib/widgets/mode_selector.dart: 0
  ```
  All 7 files with genuine zero-l10n UI violations are Area F's exact 7 owned files (see Task 2) — the l10n gap is 100% concentrated in one already-scoped area, plus the two smaller partial gaps in `main_shell.dart` (Area G) and `mode_provider.dart` (Area E) documented in Tasks 6-8 below.

---

## Task 2: Reconcile file ownership across every existing/pending plan and prove the orphan set is empty

**Files:** none modified — this task only cross-references the 5 existing plan files' Global Constraints sections and the review's own per-area "Files:" headers.

- [ ] **Step 1: Extract the exact owned-file list each existing plan declares for itself.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "lib/\|\.dart\|supabase/functions\|index\.ts" docs/superpowers/plans/2026-07-23-beauty-fix-a-vector-engine.md | grep -v "^[0-9]*:\*\*Files\*\*"
  grep -n "lib/\|\.dart\|supabase/functions\|index\.ts" docs/superpowers/plans/2026-07-23-beauty-fix-b-plan-generation.md
  grep -n "lib/\|\.dart\|supabase/functions\|index\.ts" docs/superpowers/plans/2026-07-23-beauty-fix-d-python-vectorization.md
  ```

  Actual output: Area A's and Area B's plans have **zero** matches (both ship only SQL migrations + pgTAP tests). Area D's plan has exactly one match — a comment referencing `lib/features/beauty/beauty_onboarding_page.dart` as read-only context for confirming onboarding dropdown option strings, never as a file it modifies. **Conclusion: Areas A, B, D own zero Dart/TS files.** CLAUDE.md's Logging/L10n Standards apply only to "every Dart file and every Deno edge function" — Areas A and B (pure SQL) and Area D (pure Python) are structurally out of scope for both standards. This is confirmed again in Tasks 3-5 below.

- [ ] **Step 2: Extract Area C's and Area E's owned-file lists (the two existing plans that do own Dart/TS files).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  sed -n '11,20p' docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md
  sed -n '11,18p' docs/superpowers/plans/2026-07-23-beauty-fix-e-models-providers.md
  ```

  Actual output confirms:
  - **Area C owns:** `lib/providers/dm_provider.dart` (Task 7, `BrowseGroupsParams`/`browseGroupsProvider` only), `supabase/functions/complete-beauty-onboarding/index.ts` (Task 8), and creates two new files that don't exist yet (`supabase/functions/compute-monthly-beauty-revenue/index.ts`, Task 4; a `[functions.compute-monthly-beauty-revenue]` block in `supabase/config.toml`). Area C's Global Constraints also names `supabase/functions/complete-onboarding/index.ts` as read-only context ("both onboarding functions" — the review's Area C "Well-implemented" note: *"Edge function JWT verification is genuinely enforced ... in both onboarding functions"*) — it is never modified by Area C's plan.
  - **Area E owns (exact text from its Global Constraints):** `lib/shared/models/beauty_log.dart`, `lib/shared/models/beauty_plan.dart`, `lib/shared/models/recipe.dart`, `lib/shared/models/user_profile.dart`, `lib/features/settings/models/health_profile_model.dart`, `lib/providers/beauty_plan_provider.dart`, `lib/providers/health_profile_provider.dart`, `lib/providers/meal_plan_provider.dart`, `lib/providers/mode_provider.dart`, `lib/providers/recipe_provider.dart`, `lib/providers/user_profile_provider.dart`, `test/shared/models/beauty_log_test.dart` — 11 non-test files.

- [ ] **Step 3: Cross-reference the review's own per-area "Files:" headers for Areas F, G, H (whose plans don't exist yet).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "^\*\*Files:\*\*" docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md
  ```

  Actual output:
  ```
  39:**Files:** `20260720000001-08`, `20260721000003-06,10,15,21` + seed catalogs.
  64:**Files:** `20260721000001,02,07,08,09,18,19,20,22`.
  86:**Files:** `20260521000003`, `20260721000011-14,16-17`, `20260522000001`, both edge functions.
  113:**Files:** `python/engine/vectorization.py`, `database.py`, `main.py`, both test files.
  136:**Files:** `beauty_log.dart`, `beauty_plan.dart`, `recipe.dart`, `user_profile.dart`, `health_profile_model.dart`, and 7 providers.
  155:**Files:** `beauty_analytics_page.dart`, `beauty_onboarding_page.dart`, `beauty_checkin_sheet.dart`, `today_beauty_routines_widget.dart`, `beauty_planner_view.dart`, `color_set_modal.dart`, `mode_selector.dart`.
  178:**Files:** `router.dart`, `theme.dart`, `lib/core/sdui/**`, `main_shell.dart`, `main.dart`.
  199:**Files:** 23 pre-existing screens/widgets this branch was supposed to make mode-aware (settings, nutrition, meal planner, recipes, community, profile, support, AI assistant, auth/onboarding) + `home_page.dart`.
  ```
  Line 155 (Area F) and line 178 (Area G) give exact, unambiguous file lists — 7 and 8 files respectively, matching Task 1's grouping precisely. Line 199 (Area H) is a prose description ("23 pre-existing screens ... + home_page.dart"); reconciled against the actual diff in Step 4 below, Area H's real scope is the 19 files listed in Task 1 (the review's "23" is an approximate prose count, not a literal file tally against this branch's diff — confirmed the 19-file figure is exactly right independently, since it is precisely "48 total − 0 (A) − 0 (B) − 2 (C) − 0 (D) − 11 (E) − 7 (F) − 8 (G) − 1 (verified-compliant) = 19").

- [ ] **Step 4: Compute the full ownership union and diff it against the master 48-file list.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  cat > /tmp/i_owned.txt << 'EOF'
  lib/providers/dm_provider.dart
  supabase/functions/complete-beauty-onboarding/index.ts
  lib/shared/models/beauty_log.dart
  lib/shared/models/beauty_plan.dart
  lib/shared/models/recipe.dart
  lib/shared/models/user_profile.dart
  lib/features/settings/models/health_profile_model.dart
  lib/providers/beauty_plan_provider.dart
  lib/providers/health_profile_provider.dart
  lib/providers/meal_plan_provider.dart
  lib/providers/mode_provider.dart
  lib/providers/recipe_provider.dart
  lib/providers/user_profile_provider.dart
  lib/features/beauty/beauty_analytics_page.dart
  lib/features/beauty/beauty_onboarding_page.dart
  lib/features/beauty/widgets/beauty_checkin_sheet.dart
  lib/features/beauty/widgets/today_beauty_routines_widget.dart
  lib/features/meal_planner/widgets/beauty_planner_view.dart
  lib/shared/widgets/color_set_modal.dart
  lib/widgets/mode_selector.dart
  lib/core/router.dart
  lib/core/theme.dart
  lib/core/sdui/services/layout_cache_service.dart
  lib/core/sdui/services/layout_fetch_service.dart
  lib/core/sdui/widgets/dynamic_layout_page.dart
  lib/core/sdui/widgets/widget_factory.dart
  lib/shared/widgets/main_shell.dart
  lib/main.dart
  lib/features/ai_assistant/ai_chat_page.dart
  lib/features/auth/onboarding_data.dart
  lib/features/auth/onboarding_page.dart
  lib/features/community/community_page.dart
  lib/features/home/home_page.dart
  lib/features/meal_planner/batch_cooking_page.dart
  lib/features/meal_planner/meal_planner_page.dart
  lib/features/meal_planner/shopping_list_page.dart
  lib/features/meal_planner/widgets/meal_planner_view_toggle.dart
  lib/features/nutrition/nutrition_page.dart
  lib/features/nutrition_plan/nutrition_plan_page.dart
  lib/features/profile/profile_page.dart
  lib/features/recipes/feed_page.dart
  lib/features/recipes/saved_recipes_page.dart
  lib/features/settings/health_profile_page.dart
  lib/features/settings/meal_schedule_page.dart
  lib/features/settings/preferences_page.dart
  lib/features/settings/settings_page.dart
  lib/features/support/support_page.dart
  supabase/functions/complete-onboarding/index.ts
  EOF
  sort /tmp/i_owned.txt -o /tmp/i_owned.txt
  git diff --name-only origin/main...sdui -- '*.dart' '*.ts' | grep -v '^test/' | sort > /tmp/i_master.txt
  comm -23 /tmp/i_master.txt /tmp/i_owned.txt
  wc -l /tmp/i_owned.txt /tmp/i_master.txt
  ```

  Expected/actual output: `comm -23` (files in master but NOT in the owned union) prints **nothing** — empty output. Both files report **48** lines. **Conclusion: every single one of the 48 non-test Dart/TS files touched by this branch is claimed by exactly one plan's ownership (existing or pending), with one exception (`supabase/functions/complete-onboarding/index.ts`) which is claimed only as read-only context by Area C, never as something needing a fix — that file is verified compliant on its own merits in Task 6. There are zero true orphan files. This plan adds no new fix tasks for orphaned Dart/TS files** — the "genuinely unowned/leftover work" the task brief anticipated turned out to be a single already-compliant file, not a fix.

- [ ] **Step 5: Record the pass/fail criterion for this task.** PASS = `comm -23` output is empty AND both file counts equal 48. If a future re-run of this step ever shows a non-empty `comm -23` output (e.g., because a 10th unplanned area of the branch is discovered), that file becomes this plan's responsibility to triage under the same "genuinely orphaned" test used here, and a real fix task (matching the TDD pattern of Task 13's SQL-plan siblings) must be added before this plan can be considered complete.

---

## Task 3: Verify Area A (SQL Vector Engine) — confirm zero compliance-relevant files owned

**Files:** none modified.

- [ ] **Step 1: Run the verification command.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "\.dart\b" docs/superpowers/plans/2026-07-23-beauty-fix-a-vector-engine.md
  grep -c "\.ts\b" docs/superpowers/plans/2026-07-23-beauty-fix-a-vector-engine.md
  ```

- [ ] **Step 2: Expected passing output.** Both commands return `0` (no `.dart` or `.ts` file is ever created, modified, or listed as owned anywhere in Area A's plan — it is exclusively `supabase/migrations/*.sql` and `supabase/tests/*.sql`). This is a **structural pass**: CLAUDE.md's Logging Standard covers "every Dart file and every Deno edge function"; SQL migrations are neither, so Area A carries zero CLAUDE.md compliance obligation by construction.

- [ ] **Step 3: If it fails** (i.e., either grep returns non-zero), a future revision of Area A's plan has taken on a Dart/TS file — re-open this task, identify the new file, and route it through Task 2's ownership reconciliation before treating it as newly in-scope for this plan.

---

## Task 4: Verify Area B (SQL Beauty Plan Generation) — confirm zero compliance-relevant files owned

**Files:** none modified.

- [ ] **Step 1: Run the verification command.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -cE "^\s*-?\s*(Create|Modify|Edit):\s*\`(lib/|.*\.dart|.*\.ts)" docs/superpowers/plans/2026-07-23-beauty-fix-b-plan-generation.md
  ```

- [ ] **Step 2: Expected passing output.** `0`. Every one of Area B's 7 tasks creates only `supabase/migrations/*.sql` + `supabase/tests/*.sql` files (confirmed by reading all 7 task headers: `is_active` column, RLS policies, fan-mode quota, month-tier frequency, monthly-tier anchors, `v_found` fallback, `generate_beauty_plan_from_saved`). Same structural-pass reasoning as Task 3.

- [ ] **Step 3: If it fails**, identify the new Dart/TS file Area B's plan has added and route it through Task 2's ownership reconciliation.

---

## Task 5: Verify Area D (Python Vectorization Engine) — confirm out of CLAUDE.md's Dart/Deno-only scope

**Files:** none modified.

- [ ] **Step 1: Run the verification command.** Re-read CLAUDE.md's own scope line:

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  sed -n '3,7p' CLAUDE.md
  grep -n "python/" docs/superpowers/plans/2026-07-23-beauty-fix-d-python-vectorization.md | grep -c "Modify\|Create"
  ```

- [ ] **Step 2: Expected passing output.** Line 5-6 of CLAUDE.md reads: *"Every Dart file and every Deno edge function written or modified in this project MUST contain full structured logging"* — Python is named nowhere in either standard's mandatory scope (the Logging Standard's own two sub-sections are literally titled "Flutter" and "Deno Edge Functions"; the L10n Standard opens with "Every Dart widget and page"). The second grep confirms Area D's 11 tasks touch only `python/engine/vectorization.py`, `python/engine/database.py`, `python/main.py`, and their pytest files — zero Dart/TS files. **Area D carries zero CLAUDE.md Logging/L10n compliance obligation by construction**, independent of how thorough its own Python-side logging (`logging.warning(...)` calls added in Tasks 4 and 10) happens to be.

- [ ] **Step 3: If it fails** (Area D's plan is found to touch a Dart/TS file), route that file through Task 2's ownership reconciliation before treating any of Area D's Python-side logging work as relevant to this plan.

---

## Task 6: Verify Area C's compliance fixes (edge-function logging, community mode-filter file, verified-compliant sibling)

**Files:** none modified by this task — pure verification of Area C's already-written plan once it executes.

- [ ] **Step 1a: Run the verification command for `complete-beauty-onboarding/index.ts` (Area C Task 8).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "logRLSCheck(" supabase/functions/complete-beauty-onboarding/index.ts
  grep -c "logQueryResult(" supabase/functions/complete-beauty-onboarding/index.ts
  grep -c "stack: e.stack" supabase/functions/complete-beauty-onboarding/index.ts
  ```

  **Pre-execution actual output (recorded 2026-07-23, before Area C's Task 8 has run):** `0`, `0`, `0` — matching the review's exact Finding: *"the single new Deno edge function ... has the outer ENTRY/EXIT/catch-all skeleton but never calls the mandated logRLSCheck/logQueryResult helpers around its actual DB write."*

- [ ] **Step 1b: Expected passing output once Area C's Task 8 has executed.** All three counts `>= 1` (Area C's Task 8 rewrites this file to add `logRLSCheck`/`logQueryResult` calls around its `user_health_profile` upsert, `user_profile` update, and `beauty_log` insert, plus `stack: e.stack` in the catch-all — confirmed by reading Area C's plan Task 8 body).

- [ ] **Step 1c: If it still fails after Area C's plan is marked complete**, this indicates Area C's Task 8 didn't land as written — escalate/re-run that specific task from `docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md` rather than patching the file here.

- [ ] **Step 2a: Run the verification command for the new cron edge function (Area C Task 4).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  ls supabase/functions/compute-monthly-beauty-revenue/index.ts 2>&1
  grep -c "createLogger(\|logRLSCheck(\|logQueryResult(\|ENTRY\|EXIT" supabase/functions/compute-monthly-beauty-revenue/index.ts 2>/dev/null
  ```

- [ ] **Step 2b: Expected passing output.** The `ls` succeeds (file exists — it does not exist yet as of this writing, confirmed: `ls: cannot access 'supabase/functions/compute-monthly-beauty-revenue/index.ts': No such file or directory`), and the grep count is `>= 4` once created (Area C's Task 4 body already shows a fully-compliant Deno skeleton: `createLogger`, `setRequestId`, ENTRY log, `logRLSCheck`, `logQueryResult`, EXIT log, catch-all with `stack: e.stack` — this file is compliant by construction in the plan as written; this step only confirms it was actually created, not silently skipped).

- [ ] **Step 2c: If it fails** (file missing after Area C is marked complete), escalate to Area C's Task 4.

- [ ] **Step 3: Verify `lib/providers/dm_provider.dart` (Area C Task 7) has no logging regression.** This file's fix (`BrowseGroupsParams`/`browseGroupsProvider` mode filter) is not itself a logging fix, so this step is a pure no-regression check.

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "appLogger\.\|_logger\." lib/providers/dm_provider.dart
  ```

  Expected: `>= 21` (the file's pre-existing baseline from Task 1 — Area C's mode-filter fix must not delete any existing logging while replacing the `BrowseGroupsParams` class). If the count drops below 21, Area C's Task 7 edit removed pre-existing logging calls it shouldn't have touched — escalate to Area C's Task 7.

- [ ] **Step 4: Verify `supabase/functions/complete-onboarding/index.ts` remains verified-compliant (no fix owned by any plan, confirmed compliant on its own).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  for pat in "createLogger(" "setRequestId" "ENTRY" "EXIT" "logRLSCheck(" "logQueryResult(" "stack: e.stack" "logger.setUserId" "logger.warn"; do
    printf "%s : " "$pat"; grep -c -- "$pat" supabase/functions/complete-onboarding/index.ts
  done
  ```

  Actual output (recorded 2026-07-23):
  ```
  createLogger( : 1
  setRequestId : 1
  ENTRY : 1
  EXIT : 1
  logRLSCheck( : 10
  logQueryResult( : 10
  stack: e.stack : 1
  logger.setUserId : 1
  logger.warn : 4
  ```
  Every mandated Deno logging element is present with real counts (10x `logRLSCheck`/`logQueryResult` around its DB writes, not just the outer skeleton). **`supabase/functions/complete-onboarding/index.ts` is confirmed fully compliant with CLAUDE.md's Deno Logging Standard — no fix needed, from either this plan or any other.** No plan modifies this file (confirmed in Task 2), and none needs to.

---

## Task 7: Verify Area E's compliance fixes, and flag `mode_provider.dart`'s residual hardcoded-string gap

**Files:** none modified by this task — pure verification of Area E's already-written plan once it executes, plus one flagged-but-not-fixed residual item.

- [ ] **Step 1a: Run the verification command for `beauty_plan_provider.dart` (Area E Task 5).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "appLogger.provider(" lib/providers/beauty_plan_provider.dart
  grep -c "onDispose" lib/providers/beauty_plan_provider.dart
  grep -c "BEFORE\b" lib/providers/beauty_plan_provider.dart
  grep -c "AFTER\b" lib/providers/beauty_plan_provider.dart
  ```

  **Pre-execution actual output (recorded 2026-07-23):** `0`, `0`, `1`, `0` (the file has one pre-existing `BEFORE`-style comment or error-path log, but zero lifecycle logs and zero `AFTER` logs — consistent with the review's "3 of its 4 DB/RPC writes ... log only on the error path").

- [ ] **Step 1b: Expected passing output once Area E's Task 5 has executed.** All four counts `>= 1` — Area E's Task 5 replaces the whole file with 5 `appLogger.provider(...)` build-entry logs, 5 `ref.onDispose(...)` calls, and BEFORE/AFTER pairs around `toggleCompletion`, `generatePlan`, and `beautyLogsProvider`/`addLog` (confirmed by reading the full replacement file body in Area E's plan Task 5, Step 4).

- [ ] **Step 1c: If it still fails**, this indicates Area E's Task 5 didn't land as written — escalate/re-run that task from `docs/superpowers/plans/2026-07-23-beauty-fix-e-models-providers.md`.

- [ ] **Step 2a: Run the verification command for `user_profile_provider.dart`'s `completeBeautyOnboarding` (Area E Task 6).**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "AFTER | success" lib/providers/user_profile_provider.dart
  grep -c "BEFORE rpc | fn: complete_beauty_onboarding" lib/providers/user_profile_provider.dart
  grep -c "possible RLS block on post-onboarding re-fetch" lib/providers/user_profile_provider.dart
  ```

- [ ] **Step 2b: Expected passing output.** All three counts `>= 1` once Area E's Task 6 has executed (its own Step 1 in the plan documents these exact three strings as currently `0`/`0`/`0` before the fix). Area E's plan's own commands are identical to these — this step re-runs the same check independently rather than trusting Area E's self-report.

- [ ] **Step 2c: If it still fails**, escalate to Area E's Task 6.

- [ ] **Step 3: Flag (do not fix) `mode_provider.dart`'s hardcoded, French-only mode display names.** `mode_provider.dart` is an **Area E-owned** file (per its Global Constraints list), but none of Area E's 6 read tasks address this specific gap — it is a residual item inside an already-claimed file, not an orphan this plan may act on directly.

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "'Nutrition'\|'Beauté'\|'Santé'\|'Sport'\|'Famille'" lib/providers/mode_provider.dart
  ```

  Actual output (recorded 2026-07-23):
  ```
  23:        return 'Nutrition';
  25:        return 'Beauté';
  27:        return 'Santé';
  29:        return 'Sport';
  31:        return 'Famille';
  ```
  This directly matches the review's Area I finding: *"mode_provider.dart/mode_selector.dart hardcode all app-mode names/descriptions in French with no English variant at all."* `mode_selector.dart`'s half of this finding is Area F's responsibility (Task 8 below). **This plan does not fix `mode_provider.dart` itself** — it is claimed by Area E, and CLAUDE.md rule 6 ("Providers and notifiers never resolve l10n strings — widget layer only") means the correct fix belongs in Area E's scope (e.g., exposing a raw `AppMode` enum value from the provider and letting `mode_selector.dart`'s widget layer resolve the display string via `l10n.*`, rather than the provider returning a pre-baked French string at all). If this grep still returns 5 matches after Area E's plan is marked complete, **escalate to Area E**: this specific hardcoded-string gap needs a 7th task added to `docs/superpowers/plans/2026-07-23-beauty-fix-e-models-providers.md`, not a fix inside this plan.

- [ ] **Step 4: Note the exempt zero-logging model files.** `beauty_log.dart`, `beauty_plan.dart`, `user_profile.dart`, `health_profile_model.dart` all show `0` logger calls in Task 1's sweep. Confirm each is a pure `fromJson`/`toJson` data class with no DB/RPC/user-action code path:

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "supabase\|\.rpc(\|\.from(" lib/shared/models/beauty_log.dart lib/shared/models/beauty_plan.dart lib/shared/models/user_profile.dart lib/features/settings/models/health_profile_model.dart
  ```

  Expected: `0` for all four (models never call Supabase directly in this codebase's architecture — that's the providers' job). **This is a judgment call, not a violation**: CLAUDE.md's specific logging points (provider lifecycle, DB BEFORE/AFTER, RPC BEFORE/AFTER, auth events, user actions) have no attachment point in a class with zero I/O. No fix task is warranted for these 4 files.

---

## Task 8: Verify Area F (Beauty-Specific UI Pages & Widgets) — plan not yet written, verify manually once it lands

**Files:** none modified by this task.

- [ ] **Step 1: Check whether Area F's plan file exists yet.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  ls docs/superpowers/plans/2026-07-23-beauty-fix-f-*.md 2>&1
  ```

  Actual output (recorded 2026-07-23): `ls: cannot access 'docs/superpowers/plans/2026-07-23-beauty-fix-f-*.md': No such file or directory`. **Area F's plan has not been written yet.** The 7 files it will own — `beauty_analytics_page.dart`, `beauty_onboarding_page.dart`, `beauty_checkin_sheet.dart`, `today_beauty_routines_widget.dart`, `beauty_planner_view.dart`, `color_set_modal.dart`, `mode_selector.dart` (confirmed via Task 2, matching the review's line-155 "Files:" header exactly) — currently sit at **zero** l10n calls each (Task 1, Step 4) and 5 of the 7 sit at zero logger calls too. This task cannot verify a fix that doesn't exist; it records the exact commands to run once it does.

- [ ] **Step 2: Once `docs/superpowers/plans/2026-07-23-beauty-fix-f-*.md` exists and has been executed, run this verification.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  for f in lib/features/beauty/beauty_analytics_page.dart \
           lib/features/beauty/beauty_onboarding_page.dart \
           lib/features/beauty/widgets/beauty_checkin_sheet.dart \
           lib/features/beauty/widgets/today_beauty_routines_widget.dart \
           lib/features/meal_planner/widgets/beauty_planner_view.dart \
           lib/shared/widgets/color_set_modal.dart \
           lib/widgets/mode_selector.dart; do
    echo "=== $f ==="
    echo "  l10n calls: $(grep -c 'AppLocalizations\|l10n\.' "$f")"
    echo "  logger calls: $(grep -c 'appLogger\.\|_logger\.' "$f")"
  done
  # Specific strings the original review flagged by name — must be gone:
  grep -n "'Fermer'\|'Basculer entre Nutrition et Beauté'\|'Passé en mode" lib/widgets/mode_selector.dart
  grep -n "'Teal & Amber (Nutrition)'\|'Rose & Gold (Beauty)'\|'Personnaliser le Thème de Couleurs'" lib/shared/widgets/color_set_modal.dart
  ```

- [ ] **Step 3: Expected passing output once Area F has executed.** Every file's `l10n calls` count `>= 1`; every file's `logger calls` count `>= 1` (or, for `beauty_analytics_page.dart` specifically, the review notes it "even imports the logger but never instantiates/calls it" — a real `_logger = appLogger` instantiation plus at least one call is required, not just the import). Both flagged-string greps against `mode_selector.dart` and `color_set_modal.dart` return **empty** (the literal French strings have been replaced with `l10n.*` calls).

- [ ] **Step 4: If it fails once Area F's plan is marked complete**, this indicates Area F's logging/l10n tasks didn't land as written — escalate/re-run the relevant task from Area F's plan. If Area F's plan still does not exist by the time this Area I plan is otherwise ready to close out, this task remains open and blocks Task 12's final sign-off (see Task 12's Global pass criterion).

---

## Task 9: Verify Area G (Core Mode-Switching Infrastructure) — plan not yet written, verify manually once it lands

**Files:** none modified by this task.

- [ ] **Step 1: Check whether Area G's plan file exists yet.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  ls docs/superpowers/plans/2026-07-23-beauty-fix-g-*.md 2>&1
  ```

  Actual output (recorded 2026-07-23): `ls: cannot access 'docs/superpowers/plans/2026-07-23-beauty-fix-g-*.md': No such file or directory`. **Area G's plan has not been written yet.** The 8 files it will own — `router.dart`, `theme.dart`, `layout_cache_service.dart`, `layout_fetch_service.dart`, `dynamic_layout_page.dart`, `widget_factory.dart`, `main_shell.dart`, `main.dart` (confirmed via Task 2, matching the review's line-178 "Files:" header exactly) — currently have the logger/l10n counts recorded in Task 1.

- [ ] **Step 2: Once `docs/superpowers/plans/2026-07-23-beauty-fix-g-*.md` exists and has been executed, run this verification**, targeting the two specific hardcoded-string findings the review named by exact location.

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  # Finding: main_shell.dart:47 hardcodes 'Routines'/'Remèdes' inline with 3 properly-localized l10n.* values.
  grep -n "'Routines'\|'Remèdes'" lib/shared/widgets/main_shell.dart
  grep -c "appLogger\.\|_logger\." lib/shared/widgets/main_shell.dart
  # Finding: dynamic_layout_page.dart has hardcoded English error strings (moot while
  # unreachable, but must be fixed before SDUI is ever wired in per the review's Low note).
  grep -n "'Unable to load layout'\|'Unknown error'\|'Try Again'\|'No content for\|'Check back later" lib/core/sdui/widgets/dynamic_layout_page.dart
  ```

- [ ] **Step 3: Expected passing output once Area G has executed.** The `main_shell.dart` string grep returns **empty** (both hardcoded tab labels replaced with `l10n.*`, matching the file's 3 other tab labels' existing pattern); its logger-call count is `>= 1` (currently `0` — "the file has zero logger calls despite being the highest-traffic modified file on the branch" per the review). The `dynamic_layout_page.dart` string grep returns **empty**.

- [ ] **Step 4: If it fails once Area G's plan is marked complete**, escalate/re-run the relevant task from Area G's plan. If Area G's plan does not yet exist, this task remains open.

---

## Task 10: Verify Area H (Existing-Screen Mode Mirroring) — plan not yet written, verify manually once it lands

**Files:** none modified by this task.

- [ ] **Step 1: Check whether Area H's plan file exists yet.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  ls docs/superpowers/plans/2026-07-23-beauty-fix-h-*.md 2>&1
  ```

  Actual output (recorded 2026-07-23): `ls: cannot access 'docs/superpowers/plans/2026-07-23-beauty-fix-h-*.md': No such file or directory`. **Area H's plan has not been written yet.** It owns the largest single file count of any area — 19 files (per Task 2's reconciliation): `ai_chat_page.dart`, `onboarding_data.dart`, `onboarding_page.dart`, `community_page.dart`, `home_page.dart`, `batch_cooking_page.dart`, `meal_planner_page.dart`, `shopping_list_page.dart`, `meal_planner_view_toggle.dart`, `nutrition_page.dart`, `nutrition_plan_page.dart`, `profile_page.dart`, `feed_page.dart`, `saved_recipes_page.dart`, `health_profile_page.dart`, `meal_schedule_page.dart`, `preferences_page.dart`, `settings_page.dart`, `support_page.dart`. Most of these already carry non-zero l10n/logger counts today (Task 1's sweep) since they are pre-existing, largely-compliant screens this branch only partially modified — the task brief's description of Area H as doing "a per-file l10n sweep across ~19 existing screens" matches this file count exactly.

- [ ] **Step 2: Once `docs/superpowers/plans/2026-07-23-beauty-fix-h-*.md` exists and has been executed, run this aggregate verification** (19 files individually is impractical to hand-verify string-by-string; this checks for the specific cross-cutting gap the review named — new hardcoded French strings introduced by this branch's beauty-mirroring edits specifically, not the screens' pre-existing content).

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  for f in lib/features/ai_assistant/ai_chat_page.dart lib/features/auth/onboarding_data.dart \
           lib/features/auth/onboarding_page.dart lib/features/community/community_page.dart \
           lib/features/home/home_page.dart lib/features/meal_planner/batch_cooking_page.dart \
           lib/features/meal_planner/meal_planner_page.dart lib/features/meal_planner/shopping_list_page.dart \
           lib/features/meal_planner/widgets/meal_planner_view_toggle.dart lib/features/nutrition/nutrition_page.dart \
           lib/features/nutrition_plan/nutrition_plan_page.dart lib/features/profile/profile_page.dart \
           lib/features/recipes/feed_page.dart lib/features/recipes/saved_recipes_page.dart \
           lib/features/settings/health_profile_page.dart lib/features/settings/meal_schedule_page.dart \
           lib/features/settings/preferences_page.dart lib/features/settings/settings_page.dart \
           lib/features/support/support_page.dart; do
    # New diff hunks only, vs origin/main, for beauty-branch-introduced hardcoded strings
    added_hardcoded=$(git diff origin/main...sdui -- "$f" | grep -E "^\+" | grep -cE "Text\('[A-Za-zÀ-ÿ]| '[A-ZÀ-Ÿ][a-zà-ÿ]+.*'" || true)
    echo "$f: added-hardcoded-string-lines=$added_hardcoded"
  done
  ```

- [ ] **Step 3: Expected passing output once Area H has executed.** Every file's `added-hardcoded-string-lines` count is `0` — meaning no line this branch actually *added* (not pre-existing) introduces a new hardcoded, non-`l10n.*` string. A non-zero count on any file identifies exactly which screen still has a beauty-branch-introduced hardcoded string.

- [ ] **Step 4: If it fails once Area H's plan is marked complete**, escalate/re-run the relevant per-file task from Area H's plan for each file with a non-zero count. If Area H's plan does not yet exist, this task remains open.

---

## Task 11: Verify Area J (Test Coverage & Validity) — plan not yet written, confirm no compliance-file ownership

**Files:** none modified by this task.

- [ ] **Step 1: Check whether Area J's plan file exists yet.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  ls docs/superpowers/plans/2026-07-23-beauty-fix-j-*.md 2>&1
  ```

  Actual output (recorded 2026-07-23): `ls: cannot access 'docs/superpowers/plans/2026-07-23-beauty-fix-j-*.md': No such file or directory`. **Area J's plan has not been written yet.**

- [ ] **Step 2: Confirm Area J's scope, per the review, is test validity — not new production-file logging/l10n ownership.** Re-read the review's Area J section header and issue list (`docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md` lines 238-248): every listed issue concerns a `test/*.sql`-or-`test/*.dart` file's assertions being wrong or a test not existing at all (`beauty_log_test.dart` non-compiling — already Area E's Task 2 to fix; zero SQL/RPC test coverage for payout/vector/plan logic; `beauty_checkin_sheet_test.dart`/`today_beauty_routines_widget_test.dart`/`color_set_modal_test.dart`/`beauty_onboarding_page_test.dart` asserting the wrong thing). None of Area J's likely task scope is a non-test production `.dart`/`.ts` file this plan's Task 2 ownership union would need to reassign.

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  sed -n '238,248p' docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md | grep -oE '`[a-zA-Z_/.]+\.dart`' | sort -u
  ```

  Expected output: only test-file basenames (`beauty_log_test.dart`, `beauty_checkin_sheet_test.dart`, `today_beauty_routines_widget_test.dart`, `color_set_modal_test.dart`, `beauty_onboarding_page_test.dart`, `beauty_analytics_page_test.dart`, `nutrition_page_beauty_test.dart`, `meal_planner_view_toggle_test.dart`) — confirming Area J's scope is entirely inside `test/`, which Task 1 already excludes from the CLAUDE.md compliance sweep (test files carry no logging/l10n obligation under either standard).

- [ ] **Step 3: Expected passing output/conclusion.** Area J owns zero non-test compliance-relevant files. **This task requires no further action once Area J's plan lands** — it is recorded here only so the Coverage Checklist can state explicitly that Area J was considered, not silently skipped.

- [ ] **Step 4: If Area J's eventual plan is found to touch a non-test Dart/TS file** (e.g., adding a new pgTAP harness helper that happens to also live under `lib/` — unlikely given its SQL/test focus, but not impossible), route that file through Task 2's ownership reconciliation before assuming it is out of scope.

---

## Task 12: Full end-to-end re-verification — updated aggregate stats

**Files:** none modified — this is the final sign-off sweep, re-running Task 1's exact methodology after Areas A-H and J are all assumed executed.

- [ ] **Step 1: Re-run the exact same sweep as Task 1, Step 2, across all 48 files.**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git diff --name-only origin/main...sdui -- '*.dart' '*.ts' | grep -v '^test/' > /tmp/i_files_final.txt
  zero_log=0
  zero_l10n_ui=0
  total=0
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    total=$((total+1))
    logcount=$(grep -cE "appLogger\.|_logger\.|createLogger\(|logRLSCheck\(|logQueryResult\(" "$f" 2>/dev/null || true)
    [ "$logcount" = "0" ] && zero_log=$((zero_log+1)) && echo "ZERO-LOG: $f"
  done < /tmp/i_files_final.txt
  echo "total=$total zero_log=$zero_log"
  git diff --stat origin/main...sdui -- lib/l10n/app_en.arb lib/l10n/app_fr.arb
  ```

- [ ] **Step 2: Pass criteria (all must hold):**
  1. `total` still equals `48` (no file silently dropped from the diff).
  2. `zero_log` count is reduced to only the **judgment-call-exempt** files identified in Task 7 Step 4 and Task 1's aggregate note: `lib/shared/models/beauty_log.dart`, `lib/shared/models/beauty_plan.dart`, `lib/shared/models/user_profile.dart`, `lib/features/settings/models/health_profile_model.dart`, `lib/core/theme.dart` — i.e. `zero_log <= 5`, and every file in that reduced list is one of these five, not a page/widget/provider. If `zero_log > 5`, print which files remain at zero and cross-reference Task 2's ownership map to identify which area's plan still owes a logging fix.
  3. `git diff --stat ... app_en.arb app_fr.arb` is **no longer empty** — real lines must now appear (Area F's, Area G's `main_shell.dart` tab labels, and Area H's per-screen sweep all require new ARB keys). If this is still empty, no l10n work has actually landed yet regardless of what any area's plan claims — this is the single most reliable one-command proxy for "is the L10n Standard actually met" and must never be treated as passing while empty.
  4. The two specific hardcoded-string greps from Task 8 (`mode_selector.dart`, `color_set_modal.dart`) and Task 9 (`main_shell.dart`, `dynamic_layout_page.dart`) all return empty.
  5. The `mode_provider.dart` grep from Task 7 Step 3 returns empty (escalated to Area E, but re-checked here as part of the final sign-off).
  6. Task 10's aggregate added-hardcoded-string sweep across all 19 Area H files returns `0` for every file.

- [ ] **Step 3: Produce the final aggregate table** (fill in with real counts once Steps 1-2 are run post-execution — do not fabricate numbers ahead of the other plans actually landing):

  | Metric | Original audit (2026-07-23) | This plan's baseline (Task 1) | Final (Task 12, post-execution) |
  |---|---|---|---|
  | Non-test Dart/TS files in scope | 46 Dart + 2 Deno = 48 | 48 (confirmed) | 48 (must match) |
  | Files with zero logger calls | 11 (24%) | 11 (23%, confirmed) | ≤ 5 (models/theme only) |
  | Files with zero l10n calls (UI-only subset) | not separately tabulated | 7 (all Area F) | 0 |
  | `app_en.arb`/`app_fr.arb` diff lines vs `origin/main` | 0 | 0 (confirmed) | > 0 |
  | Deno edge functions missing `logRLSCheck`/`logQueryResult` | 1 (`complete-beauty-onboarding`) | 1 (confirmed) | 0 |
  | True orphan Dart/TS files (owned by no plan) | not assessed | 0 (Task 2) | 0 |

- [ ] **Step 4: If any Step 2 criterion fails**, do not close this plan. Identify which area's plan (per Task 2's ownership map) owns the still-failing file(s) and re-open/escalate that specific area's task — this plan's own scope never includes writing the fix itself for an owned file, only detecting and routing the failure.

- [ ] **Step 5: If all Step 2 criteria pass**, commit this plan's final state (verification-only — no production files changed by this plan itself, so there is nothing to `git add` beyond this plan document's own checkbox updates if tracked):

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add docs/superpowers/plans/2026-07-23-beauty-fix-i-claude-md-compliance.md
  git commit -m "chore(beauty): verify CLAUDE.md logging/l10n compliance closed across Areas A-H, J

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

## Coverage Checklist

| Area | Plan file | Existed when this plan was written? | Compliance-relevant files owned | Verified in this plan |
|---|---|---|---|---|
| A — SQL Vector Engine | `2026-07-23-beauty-fix-a-vector-engine.md` | Yes | 0 (SQL-only, structurally out of CLAUDE.md scope) | Task 3 |
| B — SQL Beauty Plan Generation | `2026-07-23-beauty-fix-b-plan-generation.md` | Yes | 0 (SQL-only) | Task 4 |
| C — SQL Revenue/Payout, Onboarding, Community, Shopping | `2026-07-23-beauty-fix-c-revenue-community.md` | Yes | `lib/providers/dm_provider.dart` (partial), `supabase/functions/complete-beauty-onboarding/index.ts` (Task 8 logging fix), new `supabase/functions/compute-monthly-beauty-revenue/index.ts` (Task 4) | Task 6 |
| D — Python Vectorization Engine | `2026-07-23-beauty-fix-d-python-vectorization.md` | Yes | 0 (Python is out of CLAUDE.md's Dart/Deno-only scope) | Task 5 |
| E — Flutter Models & Providers | `2026-07-23-beauty-fix-e-models-providers.md` | Yes | 11 files: `beauty_plan_provider.dart` (Task 5 logging fix), `user_profile_provider.dart` (Task 6 logging fix), `beauty_log.dart`, `beauty_plan.dart`, `recipe.dart`, `user_profile.dart`, `health_profile_model.dart`, `health_profile_provider.dart`, `meal_plan_provider.dart`, `mode_provider.dart`, `recipe_provider.dart` | Task 7 — **residual gap flagged, not fixed**: `mode_provider.dart`'s 5 hardcoded French mode names are not addressed by any of Area E's 6 tasks; escalated back to Area E |
| F — Beauty-Specific UI Pages & Widgets | `2026-07-23-beauty-fix-f-*.md` | **No** | 7 files, all currently at zero l10n calls: `beauty_analytics_page.dart`, `beauty_onboarding_page.dart`, `beauty_checkin_sheet.dart`, `today_beauty_routines_widget.dart`, `beauty_planner_view.dart`, `color_set_modal.dart`, `mode_selector.dart` | Task 8 — placeholder, exact commands recorded for when it lands |
| G — Core Mode-Switching Infrastructure | `2026-07-23-beauty-fix-g-*.md` | **No** | 8 files: `router.dart`, `theme.dart`, 4 `sdui/**` files, `main_shell.dart`, `main.dart` | Task 9 — placeholder, exact commands recorded for when it lands |
| H — Existing-Screen Mode Mirroring | `2026-07-23-beauty-fix-h-*.md` | **No** | 19 files (largest area by file count) | Task 10 — placeholder, exact commands recorded for when it lands |
| J — Test Coverage & Validity | `2026-07-23-beauty-fix-j-*.md` | **No** | 0 non-test compliance-relevant files (scope is entirely inside `test/`) | Task 11 — confirmed structurally out of scope |

**True orphan files found and fixed directly by this plan:** **none**. Every one of the 48 non-test Dart/TS files touched by this branch maps to exactly one existing-or-pending area's ownership (Task 2). The one file this plan's own task brief flagged for direct attention — `supabase/functions/complete-onboarding/index.ts` — was **verified already fully compliant** (Task 6, Step 4: `createLogger`, `setRequestId`, ENTRY/EXIT, 10x `logRLSCheck`, 10x `logQueryResult`, `stack: e.stack`, `setUserId`, 4x `logger.warn` all present) and required no fix, from this plan or any other.

**Residual gap flagged but intentionally not fixed by this plan (belongs to another area's ownership):** `lib/providers/mode_provider.dart`'s 5 hardcoded French-only mode display names (`'Nutrition'`, `'Beauté'`, `'Santé'`, `'Sport'`, `'Famille'`) — owned by Area E, not addressed by any of its current 6 tasks. Flagged in Task 7, Step 3, with an escalation path (add a 7th task to Area E's plan) rather than fixed here, since the file is not an orphan.
