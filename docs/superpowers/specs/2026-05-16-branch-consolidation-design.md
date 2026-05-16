# Branch Consolidation Design — Akeli V1 UI

**Date:** 2026-05-16
**Author:** Curtis — Fondateur Akeli
**Status:** Approved — ready for implementation

---

## Context

The Akeli repo has accumulated 6 branches across multiple AI assistants (Claude, Gemini, Kilo, Qwen). Each branch contributed something valuable but no single branch contains everything cleanly. This document specifies how to consolidate the best of all branches into one authoritative `main`.

**Goal:** A clean UI prototype branch that builds, navigates all 22 pages with mock data, and carries all documentation — with no AI tool artifacts or legacy code.

---

## Approved Approach: New `v1-ui` → force-push to `main`

Create `v1-ui` from `gemini-version` (the best current UI state), add the audit docs from `hallowed-serpent`, remove all noise, then replace `main` with it via force-push. Old branches stay on the remote as an archive.

---

## What Goes Into `v1-ui`

### Kept from `gemini-version` (base)

- All Flutter pages: Home, MealPlanner, Recipes, Community, AI Chat, Profile, Fan Mode, Subscription, Diet Plan, Notifications, Group Chat, Group Detail, Auth, Onboarding
- Full design system: `lib/core/theme.dart`, `AkeliColors`, `AkeliRadius`, `AkeliShadows`, all shared widgets
- Recipe tracking schema: migration `20260314000001_recipe_tracking_schema.sql`
- All 14 Supabase Edge Functions
- All 6 Supabase migrations (in order)
- All `akeli_docs/` documentation (30+ docs)
- `lib/providers/_examples/` — reference provider templates, keep
- `supabase/functions/_examples/` — reference edge function templates, keep

### Added from `hallowed-serpent`

- `audit/pages/` — 20 markdown files covering gap analysis for all 21 pages (ai_assistant, auth, cgu, chat_page, community, create_edit_profil, diet_plan, edit_info, home_dashboard, meal_planner, notification_settings, onboarding, payment_subscription, profile, recipe_detail, recipe_search, referral, rgpd, shopping_list, support)

### Removed (cleanup)

| Item | Reason |
|---|---|
| `.kilo/` | Worktree artifacts from Kilo AI tool — not part of source |
| `.qwen/` | Worktree artifacts from Qwen AI tool — not part of source |
| `flutterflow_application/` | V0 FlutterFlow legacy app — belongs in a separate archive repo |
| `PROJECT_PLAN.md` (root) | Moved into `akeli_docs/` |
| `LOGGING_INSTRUCTIONS.md` (root) | Moved into `akeli_docs/` |
| `LOGGING_QUICK_REFERENCE.md` (root) | Moved into `akeli_docs/` |
| `LOGGING_README.md` (root) | Moved into `akeli_docs/` |

### Left behind (on old branches only)

- `lib/core/supabase_client.dart` from `claude/akeli-nutrition-v1-eDrPn` — not needed yet (UI prototype phase)
- Real Supabase providers from `claude/akeli-nutrition-v1-eDrPn` — picked up when Supabase wiring begins
- Python engine source (`python/engine/`) from `claude/akeli-nutrition-v1-eDrPn` — picked up when recommendation engine work begins

---

## Git Execution Plan

| Step | Command / Action | Commit message |
|---|---|---|
| 1 | `git checkout -b v1-ui` from `gemini-version` | — |
| 2 | Cherry-pick audit files from `hallowed-serpent` | `docs(audit): add 20-page UI audit from hallowed-serpent` |
| 3 | Delete `.kilo/`, `.qwen/`, `flutterflow_application/` | `chore: remove AI tool artifacts and FlutterFlow legacy app` |
| 4 | Move 4 loose root files → `akeli_docs/` | `chore: move root planning files into akeli_docs` |
| 5 | `git push origin v1-ui:main --force` | Replaces `main` with clean branch |
| 6 | Archive old branches on remote | No deletion — kept as safety net |
| 7 | Clean up local worktree branches (`hallowed-serpent`, `spice-peak`) | — |

---

## Branch Archive Map

| Branch | Status after consolidation | What it preserves |
|---|---|---|
| `main` | Replaced by `v1-ui` | — |
| `v1-ui` | New `main` | Best of all branches |
| `gemini-version` | Archived on remote | UI baseline |
| `hallowed-serpent` | Archived on remote | Audit docs + gemini-version |
| `claude/akeli-nutrition-v1-eDrPn` | Archived on remote | Real Supabase client + Python engine |
| `spice-peak` | Archived on remote | Identical to gemini-version |
| `projet-akeli-nutrition-app-26744` | Archived on remote | FlutterFlow app + gemini-version |

---

## Success Criteria

- [ ] `flutter build apk` passes with no errors on `v1-ui`
- [ ] All 22 pages navigable via mock auth
- [ ] `audit/pages/` contains 20 markdown files
- [ ] All `akeli_docs/` intact (30+ docs)
- [ ] No `.kilo/`, `.qwen/`, or `flutterflow_application/` directories
- [ ] Root contains no loose planning markdown files
- [ ] All old branches still accessible on the remote

---

## Out of Scope

- Code changes to any page or widget
- Supabase wiring (any provider)
- Python recommendation engine
- New features of any kind
