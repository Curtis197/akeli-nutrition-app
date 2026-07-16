# Deferred Recipe Unpublish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Creators unpublishing a recipe no longer break users' meal plans — unpublish is deferred to Monday 00:30 UTC (just before batch plan regeneration), the wizard stops silently unpublishing recipes on auto-save, and step syncing becomes transactional.

**Architecture:** A nullable `recipe.unpublish_requested_at` flag means "pending unpublish" while `is_published` stays `true` (RLS untouched, no Flutter changes). A pg_cron job finalizes flags Monday 00:30 UTC. `generate_meal_plan` and `generate_feed_personalized` exclude flagged recipes from *new* selections immediately. The landing-page RecipeWizard writes work-in-progress to `draft_data` only and materializes everything at publish time via the `replace_recipe_steps` RPC.

**Tech Stack:** Supabase Postgres 17 (project `njzqcftjzskwcpforwzf` "Akeli V1"), pg_cron, pgTAP, Next.js + supabase-js (akeli_landing_page repo).

**Spec:** `docs/superpowers/specs/2026-07-16-deferred-unpublish-design.md`

## Global Constraints

- Two repos: `akeli-nutrition-app` (all DB migrations — Tasks 1–3, 6) and `akeli_landing_page` (wizard — Tasks 4–5). Both target the same remote DB: project `njzqcftjzskwcpforwzf`.
- **Rollout order (corrected from spec):** DB migrations (Tasks 1–3) → wizard deploy (Tasks 4–5) → remediation (Task 6). The column must exist before the wizard writes it; migrations are inert until the wizard uses them. Task 6 MUST NOT run before the wizard fix is deployed, or the next edit session re-unpublishes the recipes.
- **Prod drift:** the live definitions of `generate_meal_plan` / `generate_feed_personalized` do NOT match the latest repo migration files (verified 2026-07-16 via md5). New function migrations MUST start from `pg_get_functiondef()` dumps of prod, never from repo copies.
- Remote apply: use Supabase MCP `apply_migration` (name = migration filename without `.sql`) per migration, NOT `supabase db push` — the repo has unpushed historical migrations and a blanket push is out of scope.
- pgTAP tests run locally: `cd "C:\Users\DELL LATITUDE 7480\akeli-nutrition-app"; supabase db reset; supabase test db` (PowerShell). Local reset seeds ~103 published recipes and a `creator` row.
- No Dart/Flutter changes anywhere in this plan, so the CLAUDE.md logging/l10n standards don't apply; TypeScript changes must match existing wizard style (no new dependencies).

---

### Task 1: Migration — `unpublish_requested_at` column, finalizer function, Monday cron

**Files:**
- Create: `supabase/migrations/20260716200000_deferred_unpublish.sql`
- Test: `supabase/tests/deferred_unpublish_test.sql`

**Interfaces:**
- Produces: `recipe.unpublish_requested_at timestamptz NULL`; `public.finalize_pending_unpublish() RETURNS integer` (count of finalized recipes); cron job `finalize-pending-unpublish-weekly` at `30 0 * * 1`. Tasks 2, 4, 5, 6 rely on the column; the cron relies on the function.

- [ ] **Step 1: Write the migration**

```sql
-- supabase/migrations/20260716200000_deferred_unpublish.sql
-- Deferred unpublish: creators' unpublish requests are held until Monday 00:30 UTC
-- (30 min before batch-generate-meal-plans-weekly at 01:00) so existing meal plans
-- keep working through the week. See docs/superpowers/specs/2026-07-16-deferred-unpublish-design.md

ALTER TABLE recipe ADD COLUMN IF NOT EXISTS unpublish_requested_at timestamptz NULL;

COMMENT ON COLUMN recipe.unpublish_requested_at IS
  'Non-null = pending unpublish. Recipe stays is_published=true (readable) until the Monday finalizer cron flips it. Cleared on re-publish.';

CREATE OR REPLACE FUNCTION public.finalize_pending_unpublish()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE recipe
  SET is_published = false,
      unpublish_requested_at = NULL
  WHERE unpublish_requested_at IS NOT NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Only cron (runs as postgres) may call this — it mass-unpublishes flagged recipes.
REVOKE EXECUTE ON FUNCTION public.finalize_pending_unpublish() FROM PUBLIC, anon, authenticated;

-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'finalize-pending-unpublish-weekly';

    PERFORM cron.schedule(
      'finalize-pending-unpublish-weekly',
      '30 0 * * 1',
      $cmd$ SELECT public.finalize_pending_unpublish(); $cmd$
    );
  END IF;
END;
$$;
```

- [ ] **Step 2: Write the pgTAP test**

```sql
-- supabase/tests/deferred_unpublish_test.sql
BEGIN;
SELECT plan(7);

SELECT has_column('public', 'recipe', 'unpublish_requested_at', 'recipe.unpublish_requested_at exists');
SELECT has_function('public', 'finalize_pending_unpublish', 'finalize_pending_unpublish() exists');

-- Flag one seeded published recipe as pending-unpublish
UPDATE recipe SET unpublish_requested_at = now()
WHERE id = (SELECT id FROM recipe WHERE is_published = true LIMIT 1);

SELECT is(
  (SELECT count(*)::int FROM recipe WHERE unpublish_requested_at IS NOT NULL),
  1, 'exactly one recipe flagged');

-- Flagged recipe is still readable (is_published untouched by flagging)
SELECT is(
  (SELECT is_published FROM recipe WHERE unpublish_requested_at IS NOT NULL),
  true, 'pending recipe stays published until finalizer runs');

SELECT is((SELECT public.finalize_pending_unpublish()), 1, 'finalizer reports 1 recipe flipped');

SELECT is(
  (SELECT count(*)::int FROM recipe WHERE unpublish_requested_at IS NOT NULL),
  0, 'flag cleared after finalize');

SELECT is((SELECT public.finalize_pending_unpublish()), 0, 'finalizer is a no-op when nothing pending');

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 3: Run locally — reset applies the migration, then run tests**

Run (PowerShell): `supabase db reset; supabase test db`
Expected: all existing test files PASS plus `deferred_unpublish_test.sql` 7/7 PASS.
(If `db reset` fails on an unrelated older migration, note it and validate this migration in isolation: `docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -f /dev/stdin < supabase/migrations/20260716200000_deferred_unpublish.sql` — container name may be `supabase_db_akeli_nutrition_app`, check `docker ps`.)

- [ ] **Step 4: Apply to prod**

Use Supabase MCP `apply_migration` with `project_id: njzqcftjzskwcpforwzf`, `name: 20260716200000_deferred_unpublish`, and the exact file contents as the query.

- [ ] **Step 5: Verify prod**

Run via MCP `execute_sql`:
```sql
SELECT
  (SELECT count(*) FROM information_schema.columns
   WHERE table_name='recipe' AND column_name='unpublish_requested_at') AS col,
  (SELECT count(*) FROM pg_proc WHERE proname='finalize_pending_unpublish') AS fn,
  (SELECT count(*) FROM cron.job WHERE jobname='finalize-pending-unpublish-weekly'
     AND schedule='30 0 * * 1') AS job;
```
Expected: `col=1, fn=1, job=1`.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260716200000_deferred_unpublish.sql supabase/tests/deferred_unpublish_test.sql
git commit -m "feat(db): deferred unpublish column, finalizer fn, Monday cron"
```

---

### Task 2: Migration — exclude pending-unpublish recipes from new plans and feed

**Files:**
- Create: `supabase/migrations/20260716210000_exclude_pending_unpublish.sql`
- Modify: `supabase/tests/deferred_unpublish_test.sql` (append 3 assertions; bump `plan(7)` → `plan(10)`)

**Interfaces:**
- Consumes: `recipe.unpublish_requested_at` (Task 1).
- Produces: `generate_meal_plan` (5 selection sites) and `generate_feed_personalized` (2 sites) each gain `AND r.unpublish_requested_at IS NULL`. Signatures unchanged.

- [ ] **Step 1: Dump the LIVE prod definitions into the migration file**

Run via MCP `execute_sql` (prod is the source of truth — repo files have drifted):
```sql
SELECT pg_get_functiondef(p.oid) || ';'
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'generate_meal_plan';
```
and the same for `generate_feed_personalized`. Save both outputs verbatim (meal plan first) into `supabase/migrations/20260716210000_exclude_pending_unpublish.sql`, with this header comment:
```sql
-- Exclude pending-unpublish recipes from NEW meal plans and personalized feed.
-- Bodies dumped from prod 2026-07-16 via pg_get_functiondef (repo migration files
-- had drifted from prod) with one added predicate per recipe-selection site.
```

- [ ] **Step 2: Add the exclusion predicate at every selection site**

In the new migration file, replace **all** occurrences of the exact string:
`r.is_published = true`
with:
`r.is_published = true AND r.unpublish_requested_at IS NULL`

Expected replacement count: **7** (5 in `generate_meal_plan`, 2 in `generate_feed_personalized` — the feed's sites also carry `AND r.is_private = false`, which is untouched). If the count differs, STOP: the prod functions changed since this plan was written — recount the `is_published` sites manually and update this step's expectation before proceeding.

- [ ] **Step 3: Verify the edit**

Run: `grep -c "unpublish_requested_at IS NULL" supabase/migrations/20260716210000_exclude_pending_unpublish.sql`
Expected: `7`

- [ ] **Step 4: Append structural + behavioral tests**

Append to `supabase/tests/deferred_unpublish_test.sql` before `SELECT * FROM finish();`, and change `SELECT plan(7);` to `SELECT plan(10);`:

```sql
-- Exclusion filters present at every selection site
SELECT is(
  (SELECT count(*)::int FROM regexp_matches(
     (SELECT prosrc FROM pg_proc WHERE proname = 'generate_meal_plan' LIMIT 1),
     'unpublish_requested_at IS NULL', 'g')),
  5, 'generate_meal_plan: 5 selection sites exclude pending recipes');

SELECT is(
  (SELECT count(*)::int FROM regexp_matches(
     (SELECT prosrc FROM pg_proc WHERE proname = 'generate_feed_personalized' LIMIT 1),
     'unpublish_requested_at IS NULL', 'g')),
  2, 'generate_feed_personalized: 2 selection sites exclude pending recipes');

-- Behavioral: a flagged recipe never appears in a fresh feed
UPDATE recipe SET unpublish_requested_at = now()
WHERE id = (SELECT id FROM recipe WHERE is_published = true LIMIT 1);

SELECT is(
  (SELECT count(*)::int
   FROM generate_feed_personalized(
     '00000000-0000-0000-0000-000000000001'::uuid, 500, '{}'::uuid[])
   WHERE recipe_id IN (SELECT id FROM recipe WHERE unpublish_requested_at IS NOT NULL)),
  0, 'feed never returns a pending-unpublish recipe');
```

Note: the behavioral test flags a recipe AFTER the earlier finalizer assertions cleared all flags, so the counts don't interfere. `00000000-…-01` is the seeded pgTAP test user (see `generate_meal_plan_custom_schedule_test.sql`). If `generate_feed_personalized`'s local signature rejects the 3-arg call, check its defaults with `\df generate_feed_personalized` and pass the minimal required args.

- [ ] **Step 5: Run locally**

Run (PowerShell): `supabase db reset; supabase test db`
Expected: `deferred_unpublish_test.sql` 10/10 PASS.
Caveat: the migration bodies come from prod; if local reset errors because prod functions reference an object missing locally, record the error, skip local validation for this migration only (comment it out for reset, restore after), and rely on Step 7 prod verification.

- [ ] **Step 6: Apply to prod**

MCP `apply_migration`, `project_id: njzqcftjzskwcpforwzf`, `name: 20260716210000_exclude_pending_unpublish`, query = file contents.

- [ ] **Step 7: Verify prod**

```sql
SELECT proname,
  (SELECT count(*) FROM regexp_matches(prosrc, 'unpublish_requested_at IS NULL', 'g')) AS sites
FROM pg_proc WHERE proname IN ('generate_meal_plan','generate_feed_personalized');
```
Expected: `generate_meal_plan → 5`, `generate_feed_personalized → 2`.

- [ ] **Step 8: Commit**

```bash
git add supabase/migrations/20260716210000_exclude_pending_unpublish.sql supabase/tests/deferred_unpublish_test.sql
git commit -m "feat(db): exclude pending-unpublish recipes from meal plan and feed selection"
```

---

### Task 3: Migration — harden `replace_recipe_steps` (missing columns + ownership check)

The prod RPC `replace_recipe_steps(p_recipe_id uuid, p_steps jsonb)` exists but (a) drops `image_url` and `ingredient_ids` on insert — calling it from the wizard would silently lose step images and ingredient links — and (b) has no authorization check despite SECURITY DEFINER, letting any authenticated user rewrite any recipe's steps.

**Files:**
- Create: `supabase/migrations/20260716220000_replace_recipe_steps_v2.sql`
- Modify: `supabase/tests/deferred_unpublish_test.sql` (append 2 assertions; bump `plan(10)` → `plan(12)`)

**Interfaces:**
- Produces: `public.replace_recipe_steps(p_recipe_id uuid, p_steps jsonb) RETURNS integer` — same signature, now inserts `image_url` + `ingredient_ids`, and raises `insufficient_privilege` unless the caller is the recipe's creator (or a non-JWT/service context). Task 4's wizard calls it with step objects shaped `{step_number, sort_order, title, content, image_url, timer_seconds, is_section_header, ingredient_ids}`.

- [ ] **Step 1: Write the migration**

```sql
-- supabase/migrations/20260716220000_replace_recipe_steps_v2.sql
-- replace_recipe_steps v2: carry image_url + ingredient_ids (v1 silently dropped them),
-- and add an ownership check (v1 was SECURITY DEFINER with no authorization at all).

CREATE OR REPLACE FUNCTION public.replace_recipe_steps(p_recipe_id uuid, p_steps jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
  v_role  text := COALESCE(auth.jwt() ->> 'role', 'none'); -- 'none' = direct DB connection (psql, cron, tests)
BEGIN
  IF v_role NOT IN ('service_role', 'none') THEN
    IF NOT EXISTS (
      SELECT 1 FROM recipe r
      JOIN creator c ON c.id = r.creator_id
      WHERE r.id = p_recipe_id AND c.user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'replace_recipe_steps: caller does not own recipe %', p_recipe_id
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  IF p_steps IS NULL OR jsonb_typeof(p_steps) <> 'array' OR jsonb_array_length(p_steps) = 0 THEN
    RAISE EXCEPTION 'replace_recipe_steps: p_steps must be a non-empty JSON array';
  END IF;

  DELETE FROM public.recipe_step WHERE recipe_id = p_recipe_id;

  INSERT INTO public.recipe_step
    (recipe_id, step_number, sort_order, title, content, image_url, timer_seconds, is_section_header, ingredient_ids)
  SELECT
    p_recipe_id,
    (s->>'step_number')::int,
    (s->>'sort_order')::int,
    NULLIF(s->>'title', ''),
    NULLIF(s->>'content', ''),
    NULLIF(s->>'image_url', ''),
    NULLIF(s->>'timer_seconds', '')::int,
    COALESCE((s->>'is_section_header')::boolean, false),
    COALESCE(
      (SELECT array_agg(x::uuid) FROM jsonb_array_elements_text(s->'ingredient_ids') AS x),
      '{}'::uuid[]
    )
  FROM jsonb_array_elements(p_steps) AS s;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;
```

- [ ] **Step 2: Append tests**

Append before `SELECT * FROM finish();`, bump `SELECT plan(10);` to `SELECT plan(12);`:

```sql
-- replace_recipe_steps v2 carries image_url and ingredient_ids
SELECT is(
  (SELECT public.replace_recipe_steps(
     (SELECT id FROM recipe LIMIT 1),
     '[{"step_number":1,"sort_order":1,"content":"Test étape","image_url":"https://x/img.jpg","ingredient_ids":[],"is_section_header":false}]'::jsonb)),
  1, 'replace_recipe_steps inserts one step');

SELECT is(
  (SELECT image_url FROM recipe_step
   WHERE recipe_id = (SELECT id FROM recipe LIMIT 1) AND content = 'Test étape'),
  'https://x/img.jpg', 'image_url is persisted');
```

(The test runs as a direct DB connection → `v_role = 'none'` → ownership check is bypassed by design; ownership denial is covered by the manual prod check in Step 5.)

- [ ] **Step 3: Run locally**

Run (PowerShell): `supabase db reset; supabase test db`
Expected: 12/12 PASS in `deferred_unpublish_test.sql`, all other files PASS.

- [ ] **Step 4: Apply to prod**

MCP `apply_migration`, `name: 20260716220000_replace_recipe_steps_v2`, query = file contents.

- [ ] **Step 5: Verify prod**

```sql
SELECT prosrc ~ 'insufficient_privilege' AS has_ownership_check,
       prosrc ~ 'image_url'              AS has_image_url,
       prosrc ~ 'ingredient_ids'         AS has_ingredient_ids
FROM pg_proc WHERE proname = 'replace_recipe_steps';
```
Expected: all `true`.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260716220000_replace_recipe_steps_v2.sql supabase/tests/deferred_unpublish_test.sql
git commit -m "fix(db): replace_recipe_steps carries image_url/ingredient_ids and checks ownership"
```

---

### Task 4: Wizard — draft-only editing of published recipes + transactional publish

**Repo: `C:\Users\DELL LATITUDE 7480\akeli_landing_page`** (separate git repo — commit there).

**Files:**
- Modify: `components/creator/recipe-form/RecipeWizard.tsx` (saveRecipeRow ~118-157, syncSteps ~182-201, saveDraft ~241-274, handlePublish ~311-358, props ~82-110)
- Modify: `app/[locale]/(creator)/dashboard/recipes/[id]/edit/page.tsx` (select + initialData mapping ~23-130, wizard instantiation ~169)
- Modify: `lib/supabase/database.types.ts` (recipe Row/Insert/Update)

**Interfaces:**
- Consumes: `recipe.unpublish_requested_at` (Task 1), `replace_recipe_steps(p_recipe_id, p_steps)` v2 (Task 3).
- Produces: `RecipeWizardProps` gains `initialIsPublished?: boolean` and `initialUnpublishRequestedAt?: string | null` (Task 5 renders UI from these). `handlePublish(true)` sets `is_published: true, unpublish_requested_at: null`.

- [ ] **Step 1: Add `unpublish_requested_at` to the generated types**

In `lib/supabase/database.types.ts`, locate the `recipe` table block and add to each of `Row`, `Insert`, `Update`:
```ts
unpublish_requested_at: string | null   // Row
unpublish_requested_at?: string | null  // Insert and Update
```

- [ ] **Step 2: Wizard props + published-state tracking**

In `RecipeWizard.tsx`:
```ts
interface RecipeWizardProps {
  recipeId?: string;
  initialData?: Partial<RecipeFormState>;
  initialIsPublished?: boolean;
  initialUnpublishRequestedAt?: string | null;
}
```
In the component body (near the other `useState` calls), add:
```ts
const [isLivePublished] = useState<boolean>(initialIsPublished ?? false);
const [publishError, setPublishError] = useState<string | null>(null);
```
(`isLivePublished` is fixed for the session: it reflects the live row at load. The publish/unpublish actions navigate away, so it never needs updating in place.)

- [ ] **Step 3: `saveRecipeRow` — never unpublish; draft-only when live**

Replace the body of `saveRecipeRow` (keep the `useCallback` wrapper and dependency array, adding `isLivePublished`):
```ts
const saveRecipeRow = useCallback(
  async (data: RecipeFormState): Promise<string | null> => {
    if (!creator) return null;

    // Published recipes: work-in-progress goes to draft_data ONLY —
    // the live row must not change until Publish.
    if (draftId && isLivePublished) {
      const { error } = await supabase
        .from("recipe")
        .update({ draft_data: data })
        .eq("id", draftId);
      if (error) throw error;
      return draftId;
    }

    const payload = {
      creator_id: creator.id,
      title: data.title || "Brouillon",
      description: data.description || null,
      region: data.region || null,
      difficulty: data.difficulty || null,
      prep_time_min: data.prep_time_min,
      cook_time_min: data.cook_time_min || null,
      servings: data.servings,
      cover_image_url: data.cover_image_url || null,
      is_pork_free: data.is_pork_free,
      is_private: data.is_private,
      show_on_website: data.show_on_website,
      meal_types: data.meal_types,
      preferred_meal_type: data.preferred_meal_type,
      language: "fr",
      draft_data: data,
    };

    if (draftId) {
      const { error } = await supabase.from("recipe").update(payload).eq("id", draftId);
      if (error) throw error;
      return draftId;
    } else {
      const { data: newRecipe, error } = await supabase
        .from("recipe")
        .insert(payload)
        .select("id")
        .single();
      if (error) throw error;
      if (newRecipe) setDraftId(newRecipe.id);
      return newRecipe?.id ?? null;
    }
  },
  [creator, draftId, isLivePublished, supabase]
);
```
Key changes: `is_published: false` is GONE from the payload (safe: the column default is `false` — verified in prod 2026-07-16 — so new drafts are born unpublished and existing rows keep their state; published recipes are never touched), and a published recipe's auto-save writes only `draft_data`.

- [ ] **Step 4: `saveDraft` — skip live-table syncs for published recipes**

In `saveDraft`, wrap the three sync calls:
```ts
const id = await saveRecipeRow(data);
if (!id) return null;

if (!isLivePublished) {
  if (syncStep === 2) await syncIngredients(id, data);
  if (syncStep === 3) await syncSteps(id, data);
  if (syncStep === 4) await updateMacros(id, data);

  if (data.gallery_urls.length > 0) {
    await supabase.from("recipe_image").delete().eq("recipe_id", id);
    await supabase.from("recipe_image").insert(
      data.gallery_urls.map((url, i) => ({ recipe_id: id, url, sort_order: i }))
    );
  }
}
```
Add `isLivePublished` to the `useCallback` dependency array.

- [ ] **Step 5: `syncSteps` — transactional RPC with error propagation**

Replace the `syncSteps` body:
```ts
const syncSteps = useCallback(
  async (id: string, data: RecipeFormState) => {
    if (!data.steps.length) return;
    const { error } = await supabase.rpc("replace_recipe_steps", {
      p_recipe_id: id,
      p_steps: data.steps.map((step) => ({
        step_number: step.step_number,
        sort_order: step.sort_order,
        title: step.title || null,
        content: step.is_section_header ? null : step.content || null,
        image_url: step.image_url || null,
        timer_seconds: step.timer_seconds ?? null,
        is_section_header: step.is_section_header,
        ingredient_ids: step.ingredient_ids ?? [],
      })),
    });
    if (error) throw error;
  },
  [supabase]
);
```
Also add error propagation to `syncIngredients`: capture `const { error } = await …` on both the `delete` and the `insert` calls and `if (error) throw error;` after each. Same for the `update` in `updateMacros`.

- [ ] **Step 6: `handlePublish` — materialize with error checking, set/clear the flag**

Replace `handlePublish`:
```ts
const handlePublish = async (publish: boolean) => {
  setIsPublishing(true);
  setPublishError(null);
  try {
    const id = await saveRecipeRow(formState);
    if (!id) return;

    if (publish) {
      // Materialize draft → live tables. Any failure aborts before is_published flips.
      const { error: rowError } = await supabase
        .from("recipe")
        .update({
          title: formState.title,
          description: formState.description || null,
          region: formState.region || null,
          difficulty: formState.difficulty || null,
          prep_time_min: formState.prep_time_min,
          cook_time_min: formState.cook_time_min || null,
          servings: formState.servings,
          cover_image_url: formState.cover_image_url || null,
          is_pork_free: formState.is_pork_free,
          is_private: formState.is_private,
          meal_types: formState.meal_types,
          preferred_meal_type: formState.preferred_meal_type,
        })
        .eq("id", id);
      if (rowError) throw rowError;

      await syncIngredients(id, formState);
      await syncSteps(id, formState);
      await updateMacros(id, formState);

      if (formState.gallery_urls.length > 0) {
        const { error: delError } = await supabase.from("recipe_image").delete().eq("recipe_id", id);
        if (delError) throw delError;
        const { error: imgError } = await supabase.from("recipe_image").insert(
          formState.gallery_urls.map((url, i) => ({ recipe_id: id, url, sort_order: i }))
        );
        if (imgError) throw imgError;
      }

      const ingredientIds = formState.ingredients
        .filter((i) => !i.is_section_header && i.ingredient_id)
        .map((i) => i.ingredient_id!);
      const allergenSlugs = await fetchIngredientAllergens(ingredientIds);

      const { error: tagDelError } = await supabase.from("recipe_tag").delete().eq("recipe_id", id);
      if (tagDelError) throw tagDelError;
      if (formState.tags.length > 0) {
        const { error: tagError } = await supabase.from("recipe_tag").insert(
          formState.tags.map((tag_id) => ({ recipe_id: id, tag_id }))
        );
        if (tagError) throw tagError;
      }

      // translate_recipe trigger fires automatically on the publish transition
      const { error: pubError } = await supabase
        .from("recipe")
        .update({
          is_published: true,
          unpublish_requested_at: null,
          allergen_tags: allergenSlugs,
          show_on_website: formState.show_on_website,
        })
        .eq("id", id);
      if (pubError) throw pubError;

      updateForm({ allergen_tags: allergenSlugs });
    }
    // publish === false: draft already saved by saveRecipeRow above — nothing
    // else to do. Publication state is NEVER changed here anymore.

    router.push("/dashboard/recipes");
  } catch (err) {
    console.error("Publish failed:", err);
    setPublishError(
      "La publication a échoué — aucune donnée n'a été perdue. Réessayez ou contactez le support."
    );
  } finally {
    setIsPublishing(false);
  }
};
```
Render the error near the wizard footer (inside the `mt-8 flex …` footer div, before the buttons):
```tsx
{publishError && (
  <p className="text-sm text-red-600 mr-4">{publishError}</p>
)}
```

- [ ] **Step 7: Edit page — load draft_data first, pass publication state**

In `app/[locale]/(creator)/dashboard/recipes/[id]/edit/page.tsx`:

1. Add `is_published, unpublish_requested_at, draft_data` to the top level of the `.select(…)` column list.
2. Add state: `const [pubState, setPubState] = useState<{ isPublished: boolean; unpublishRequestedAt: string | null }>({ isPublished: false, unpublishRequestedAt: null });`
3. After the `if (err || !data)` guard, set it and prefer the draft when present:
```ts
setPubState({
  isPublished: (data as any).is_published ?? false,
  unpublishRequestedAt: (data as any).unpublish_requested_at ?? null,
});

// A saved draft holds the full RecipeFormState (the wizard stores it verbatim).
// Prefer it over live tables so in-progress edits survive page reloads.
if ((data as any).draft_data && typeof (data as any).draft_data === "object") {
  setInitialData((data as any).draft_data as Partial<RecipeFormState>);
  setLoading(false);
  return;
}
```
4. Pass the props:
```tsx
<RecipeWizard
  recipeId={id}
  initialData={initialData}
  initialIsPublished={pubState.isPublished}
  initialUnpublishRequestedAt={pubState.unpublishRequestedAt}
/>
```

- [ ] **Step 8: Typecheck**

Run in the landing repo: `npx tsc --noEmit`
Expected: no new errors (pre-existing errors, if any, are out of scope — note them).

- [ ] **Step 9: Manual verification (local dev against local Supabase, or staging)**

1. Edit a **published** recipe → change the title → wait 30 s (auto-save) → in another tab confirm `SELECT is_published, title FROM recipe WHERE id = …` shows `is_published = true` and the OLD title (draft-only save). 
2. Reload the edit page → the NEW title appears (draft_data loaded).
3. Click "🚀 Publier la recette" → row title updates, steps present in `recipe_step`, `is_published = true`.

- [ ] **Step 10: Commit (in akeli_landing_page)**

```bash
git add components/creator/recipe-form/RecipeWizard.tsx "app/[locale]/(creator)/dashboard/recipes/[id]/edit/page.tsx" lib/supabase/database.types.ts
git commit -m "fix(wizard): draft-only editing keeps published recipes live; transactional publish"
```

---

### Task 5: Wizard — explicit deferred-unpublish button

**Repo: `akeli_landing_page`.**

**Files:**
- Modify: `components/creator/recipe-form/RecipeWizard.tsx` (Step6Tags instantiation ~413-421)
- Modify: `components/creator/recipe-form/Step6Tags.tsx` (props ~11-20, footer buttons ~245-261)

**Interfaces:**
- Consumes: `isLivePublished`, `initialUnpublishRequestedAt`, `draftId` (Task 4); `recipe.unpublish_requested_at` (Task 1).
- Produces: `Step6TagsProps` gains `onUnpublish?: () => void`, `isPublished: boolean`, `pendingUnpublish: boolean`.

- [ ] **Step 1: Unpublish handler in RecipeWizard**

Add next to `handlePublish`:
```ts
const handleRequestUnpublish = async () => {
  if (!draftId) return;
  setIsPublishing(true);
  setPublishError(null);
  try {
    const { error } = await supabase
      .from("recipe")
      .update({ unpublish_requested_at: new Date().toISOString() })
      .eq("id", draftId);
    if (error) throw error;
    router.push("/dashboard/recipes");
  } catch (err) {
    console.error("Unpublish request failed:", err);
    setPublishError("La demande de retrait a échoué. Réessayez.");
  } finally {
    setIsPublishing(false);
  }
};
```
Pass to Step6Tags:
```tsx
<Step6Tags
  data={formState}
  onChange={updateForm}
  onSaveDraft={() => handlePublish(false)}
  onPublish={() => handlePublish(true)}
  onUnpublish={handleRequestUnpublish}
  isPublished={isLivePublished}
  pendingUnpublish={!!initialUnpublishRequestedAt}
  isPublishing={isPublishing}
/>
```

- [ ] **Step 2: Step6Tags UI**

Add to the props interface and destructuring: `onUnpublish?: () => void; isPublished: boolean; pendingUnpublish: boolean;`

In the footer button row (next to the existing save-draft and publish buttons):
```tsx
{isPublished && !pendingUnpublish && (
  <button
    onClick={onUnpublish}
    disabled={isPublishing}
    className="px-5 py-2 rounded-lg border border-red-300 text-sm font-medium text-red-600 hover:bg-red-50 transition-colors disabled:opacity-40"
  >
    Retirer la recette (effectif lundi)
  </button>
)}
{pendingUnpublish && (
  <p className="text-xs text-amber-600">
    Retrait programmé lundi matin — publiez à nouveau pour annuler.
  </p>
)}
```
(French copy matches the wizard's existing hardcoded-French convention — this repo does not use the Flutter l10n system.)

- [ ] **Step 3: Typecheck**

Run: `npx tsc --noEmit` — no new errors.

- [ ] **Step 4: Manual verification**

1. Open a published recipe → Step 6 shows "Retirer la recette (effectif lundi)".
2. Click it → redirected to the list; `SELECT is_published, unpublish_requested_at FROM recipe WHERE id = …` → `true, <timestamp>`.
3. Reopen the recipe in the wizard → amber "Retrait programmé lundi matin" notice shows instead of the button.
4. Click "🚀 Publier la recette" → `unpublish_requested_at` back to NULL.
5. In the Flutter app (or SQL): recipe still readable while pending.

- [ ] **Step 5: Commit (in akeli_landing_page), then deploy the landing page**

```bash
git add components/creator/recipe-form/RecipeWizard.tsx components/creator/recipe-form/Step6Tags.tsx
git commit -m "feat(wizard): explicit deferred unpublish (effective Monday) replaces silent unpublish"
```
Deploy via the repo's usual pipeline. **Task 6 is blocked until this deploy is live.**

---

### Task 6: One-time remediation — republish the 11 complete recipes

**Precondition:** Tasks 1–5 applied AND the landing page deploy from Task 5 is live (otherwise the next wizard edit re-unpublishes these).

**Files:** none (production data operation, run via MCP `execute_sql` on `njzqcftjzskwcpforwzf`).

- [ ] **Step 1: Pre-check — all 11 still unpublished and step-complete**

```sql
SELECT r.id, r.title, r.is_published,
       (SELECT count(*) FROM recipe_step s WHERE s.recipe_id = r.id) AS steps
FROM recipe r
WHERE r.id IN (
  '996ad252-cb32-43c6-9386-dc60c67dde2b','dd836fa5-2cea-4004-a201-e038ab2f92e1',
  'b0f85653-e3a8-4d71-b5fb-45bf21aa0396','cee1528f-8396-408f-bfda-6b335bf0365a',
  'a003c0c9-70ad-4f94-9507-898a16e13b38','93307b94-65d0-44bd-b358-9da08da2c039',
  '0a846b28-5329-4c85-b207-96f21c6bbcf5','29ea827d-6727-4281-9fbe-487099110bba',
  '4798f868-d3a5-4d8a-bc54-59a4de2a7e62','d1000009-aaaa-4bbb-8ccc-333333333333',
  '382ea613-7889-49e0-bfc6-d2071db96737'
);
```
Expected: 11 rows, every `steps > 0`. Any recipe already `is_published = true` (someone republished manually) is fine — the UPDATE is idempotent. A recipe with `steps = 0` must be EXCLUDED from Step 2 and reported.

- [ ] **Step 2: Republish**

```sql
UPDATE recipe
SET is_published = true, unpublish_requested_at = NULL
WHERE id IN (
  '996ad252-cb32-43c6-9386-dc60c67dde2b','dd836fa5-2cea-4004-a201-e038ab2f92e1',
  'b0f85653-e3a8-4d71-b5fb-45bf21aa0396','cee1528f-8396-408f-bfda-6b335bf0365a',
  'a003c0c9-70ad-4f94-9507-898a16e13b38','93307b94-65d0-44bd-b358-9da08da2c039',
  '0a846b28-5329-4c85-b207-96f21c6bbcf5','29ea827d-6727-4281-9fbe-487099110bba',
  '4798f868-d3a5-4d8a-bc54-59a4de2a7e62','d1000009-aaaa-4bbb-8ccc-333333333333',
  '382ea613-7889-49e0-bfc6-d2071db96737'
)
RETURNING id, title;
```
Expected: 11 rows returned. The `false → true` transition fires `trg_recipe_auto_translate_pg_net` per recipe, regenerating step translations (async via pg_net — allow a few minutes).

- [ ] **Step 3: Verify**

```sql
-- Everything a user's meal plan references is readable again
SELECT count(*) AS still_broken
FROM meal_plan_entry_component c
JOIN recipe r ON r.id = c.recipe_id
WHERE r.is_published = false;
```
Expected: `0` (only Bawoin and Sauce Graine — Foutou remain unpublished, and they should not be referenced; if `still_broken > 0`, list the offending recipes and report — do not force-publish step-less recipes).

Then spot-check in the Flutter app: open "Soupe du Pêcheur — Atiéké" from a meal plan → title + 22 steps visible.

- [ ] **Step 4: Record completion**

Add a dated note to the spec's remediation section (`docs/superpowers/specs/2026-07-16-deferred-unpublish-design.md`): "Remediation executed YYYY-MM-DD — 11 recipes republished." Commit:
```bash
git add docs/superpowers/specs/2026-07-16-deferred-unpublish-design.md
git commit -m "docs: record deferred-unpublish remediation execution"
```
