# Deferred Recipe Unpublish — Design Spec

**Date:** 2026-07-16
**Status:** Approved
**Scope:** akeli-nutrition-app (V1 DB, project `njzqcftjzskwcpforwzf`) + akeli_landing_page (creator RecipeWizard)

## Problem

Users found recipes in their meal plans with no title and no steps (e.g. "Soupe du
Pêcheur — Atiéké"). Investigation on 2026-07-16 found two causes:

1. **Wizard unpublishes on every save.** `RecipeWizard.tsx` (akeli_landing_page,
   `components/creator/recipe-form/`) sets `is_published: false` in `saveRecipeRow`
   on every save, and an auto-save fires every 30 s while the form is dirty. Opening
   a published recipe in the wizard takes it offline in production within 30 s;
   abandoning the wizard leaves it offline permanently. RLS on `recipe` and
   `recipe_step` gates SELECT on `is_published = true`, so the recipe becomes fully
   invisible (title and steps) to every real user — but existing meal plans still
   reference it via `meal_plan_entry_component.recipe_id`, producing dead
   "Recette introuvable" pages.
2. **Steps lost by unsafe sync.** The wizard's `syncSteps` does delete-then-insert
   on `recipe_step` with no error check and no transaction. Four published recipes
   (Basbousa, Biryani de Maurice, Kitcha Fit-Fit, Sauce Arachide — Riz Blanc) had
   their steps wiped while staying published; steps survived only in the
   `recipe.draft_data` JSON. (Remediated 2026-07-16: 91 steps materialized from
   `draft_data` back into `recipe_step`.)

## Decisions (user-approved)

- The wizard must **keep a published recipe live while editing** — work-in-progress
  goes to `draft_data` only; live tables change only at publish time.
- Deliberate unpublish is **deferred**: the recipe stays readable until the Monday
  batch meal-plan generation, then goes dark. (Chosen over meal-plan-scoped RLS and
  over snapshotting recipe content into meal plans.)
- Pending-unpublish recipes are **excluded immediately** from new meal plans and
  personalized feed.
- The 11 accidentally-unpublished but complete recipes are **republished** as a
  one-time remediation.

## Design

### 1. Schema (V1 DB migration)

```sql
ALTER TABLE recipe ADD COLUMN unpublish_requested_at timestamptz NULL;
```

Semantics: non-null means "pending unpublish". The recipe keeps
`is_published = true`, so all existing RLS policies keep it readable — no Flutter
app changes are needed.

### 2. Wizard changes (akeli_landing_page — `RecipeWizard.tsx`)

- `saveRecipeRow` no longer sets `is_published: false`. Auto-save and step
  navigation write **only** `draft_data` (plus `updated_at`) for recipes that are
  currently published; they must not modify live row fields, `recipe_ingredient`,
  `recipe_step`, or `recipe_macro`. (For never-published drafts, syncing live
  tables remains harmless, but the single "materialize at publish" path is
  preferred for both.)
- **Publish** (`handlePublish(true)`): materialize `draft_data` → live tables
  (row fields, ingredients, steps, macros, tags) **with error checking** — abort
  and surface an error if any sync fails, rather than today's silent partial
  state — then set `is_published = true, unpublish_requested_at = NULL`.
  Step replacement should be transactional (single RPC such as
  `replace_recipe_steps`, which already has a test scaffold in the landing repo,
  or equivalent) instead of unchecked delete-then-insert.
- **Unpublish** (`handlePublish(false)`): set `unpublish_requested_at = now()`
  instead of `is_published = false`. Publishing again during the grace week clears
  the flag.

### 3. Monday finalizer (pg_cron, plain SQL)

New job `finalize-pending-unpublish`, schedule `30 0 * * 1` (Monday 00:30 UTC —
30 minutes before the existing `batch-generate-meal-plans-weekly` job at
`0 1 * * 1`):

```sql
UPDATE recipe
SET is_published = false,
    unpublish_requested_at = NULL
WHERE unpublish_requested_at IS NOT NULL;
```

A pulled recipe therefore disappears exactly when the new weekly plans (generated
without it) replace the old ones. Failure mode is fail-open: if the job doesn't
run, pending recipes stay visible one more week. Run history is observable in
`cron.job_run_details`.

### 4. Exclusion from new recommendations

Add `AND r.unpublish_requested_at IS NULL` to every recipe-selection query in:

- `generate_meal_plan` (5 selection sites currently filter `is_published = true`)
- `generate_feed_personalized` (2 sites)

Effect: users who already have the recipe keep full access until Monday; it stops
entering new plans and feeds immediately. Title search (`ilike` on `recipe`) will
still find it until Monday — accepted, search is not a recommendation surface.

### 5. One-time remediation (production data)

After the wizard fix is deployed (order matters — republishing first would let the
next edit re-unpublish them):

```sql
UPDATE recipe SET is_published = true
WHERE id IN (
  -- complete recipes accidentally unpublished by the wizard bug
  '996ad252-cb32-43c6-9386-dc60c67dde2b', -- Soupe du Pêcheur — Atiéké
  'dd836fa5-2cea-4004-a201-e038ab2f92e1', -- Shiro Wat
  'b0f85653-e3a8-4d71-b5fb-45bf21aa0396', -- Riz Jollof
  'cee1528f-8396-408f-bfda-6b335bf0365a', -- Poulet Yassa
  'a003c0c9-70ad-4f94-9507-898a16e13b38', -- Doro Wat
  '93307b94-65d0-44bd-b358-9da08da2c039', -- Injera
  '0a846b28-5329-4c85-b207-96f21c6bbcf5', -- Maafé
  '29ea827d-6727-4281-9fbe-487099110bba', -- Couscous Royal
  '4798f868-d3a5-4d8a-bc54-59a4de2a7e62', -- Koshary
  'd1000009-aaaa-4bbb-8ccc-333333333333', -- Akara
  '382ea613-7889-49e0-bfc6-d2071db96737'  -- Sauce Noix de Cajou — Riz Blanc
);
```

Republishing fires the `trg_recipe_auto_translate_pg_net` trigger per recipe,
regenerating the step translations that were cascade-deleted when steps were wiped.
Bawoin — Riz Blanc and Sauce Graine — Foutou stay unpublished: they have no steps
in `recipe_step` or `draft_data` and are genuinely unfinished.

**Remediation executed 2026-07-17** — all 11 recipes republished (Akara was already
republished independently before this ran). Post-check confirmed zero rows in
`meal_plan_entry_component` joined to an unpublished recipe.

## Rollout order

1. Deploy wizard changes (akeli_landing_page).
2. Apply V1 DB migration: column + function updates (`generate_meal_plan`,
   `generate_feed_personalized`) + cron job.
3. Run remediation UPDATE.

## Testing

- **pgTAP (V1 repo):** finalizer flips flagged recipes to unpublished and clears
  the flag; unflagged recipes untouched. `generate_meal_plan` /
  `generate_feed_personalized` exclude a recipe with `unpublish_requested_at` set.
- **Wizard manual test:** edit a published recipe → stays published, live steps
  untouched while editing; Unpublish → flag set, recipe gone from feed/planner
  generation but still openable from an existing meal plan; Publish again → flag
  cleared. Publish with a failing step sync → visible error, no partial state.
- **Post-remediation check:** all 11 recipes readable in the app with title +
  steps; translations regenerate within the trigger's normal delay.

## Out of scope

- Immediate hard takedown ("unpublish now") for legal/safety reasons — can be
  added later as a direct `is_published = false` escape hatch.
- Recipe deletion during the grace week (FK behavior unchanged).
- Hiding pending-unpublish recipes from title search before Monday.
