# Allergy Workflow — Full Implementation Design

**Date:** 2026-06-01
**Status:** Approved

---

## Overview

Users can currently set allergies during onboarding and in preferences, but those values have zero effect on the feed, meal plan generator, or recipe search. This spec closes that gap end-to-end: structured allergen tags, autocomplete picker in UI, denormalized tags on recipes, and SQL-level filtering in every RPC.

**Out of scope:** dietary lifestyle restrictions (`no_pork`, `no_meat`, `no_gluten`, `no_lactose`) remain a separate system and are not touched.

---

## 1. Database Schema

### New tables

```sql
-- Master allergen list
CREATE TABLE allergen (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug       text UNIQUE NOT NULL,
  label      text NOT NULL,
  is_active  boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Ingredient → allergen mapping (normalized source of truth)
CREATE TABLE ingredient_allergen (
  ingredient_id uuid REFERENCES ingredient(id) ON DELETE CASCADE,
  allergen_id   uuid REFERENCES allergen(id) ON DELETE CASCADE,
  PRIMARY KEY (ingredient_id, allergen_id)
);

-- User allergen selections (replaces freeform allergy strings)
CREATE TABLE user_allergy (
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  allergen_id uuid REFERENCES allergen(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, allergen_id)
);

-- User-submitted allergen suggestions (pending admin review)
CREATE TABLE allergen_suggestion (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid REFERENCES user_profile(id),
  label      text NOT NULL,
  status     text DEFAULT 'pending', -- 'pending' | 'approved' | 'rejected'
  created_at timestamptz DEFAULT now()
);
```

### Column added to `recipe`

```sql
ALTER TABLE recipe ADD COLUMN allergen_tags text[] DEFAULT '{}';
CREATE INDEX idx_recipe_allergen_tags ON recipe USING GIN (allergen_tags);
```

### RLS policies

- `allergen` — public read (`SELECT` for all authenticated), no write
- `ingredient_allergen` — public read
- `user_allergy` — owner only (same pattern as `user_dietary_restriction`)
- `allergen_suggestion` — insert for authenticated users, read own rows only

---

## 2. Allergen Seed List

Initial curated list inserted into `allergen` at migration time:

| slug | label |
|------|-------|
| `nuts` | Tree Nuts |
| `peanuts` | Peanuts |
| `dairy` | Dairy & Lactose |
| `gluten` | Gluten |
| `eggs` | Eggs |
| `shellfish` | Shellfish |
| `fish` | Fish |
| `soy` | Soy & Soya |
| `sesame` | Sesame |
| `berries` | Berries |
| `citrus` | Citrus |
| `nightshades` | Nightshades |
| `stone_fruits` | Stone Fruits |
| `legumes` | Legumes |
| `corn` | Corn & Maize |
| `sulfites` | Sulfites |
| `mustard` | Mustard |
| `celery` | Celery |
| `lupin` | Lupin |
| `molluscs` | Molluscs |

---

## 3. Trigger — Auto-update `recipe.allergen_tags`

When `ingredient_allergen` rows are inserted or deleted, the trigger recomputes `allergen_tags` for all recipes that use the affected ingredient.

```sql
CREATE OR REPLACE FUNCTION refresh_recipe_allergen_tags()
RETURNS TRIGGER AS $$
DECLARE
  affected_ingredient_id uuid;
BEGIN
  affected_ingredient_id := COALESCE(NEW.ingredient_id, OLD.ingredient_id);

  UPDATE recipe r
  SET allergen_tags = (
    SELECT COALESCE(array_agg(DISTINCT a.slug), '{}')
    FROM recipe_ingredient ri
    JOIN ingredient_allergen ia ON ia.ingredient_id = ri.ingredient_id
    JOIN allergen a ON a.id = ia.allergen_id
    WHERE ri.recipe_id = r.id
  )
  WHERE r.id IN (
    SELECT DISTINCT ri.recipe_id
    FROM recipe_ingredient ri
    WHERE ri.ingredient_id = affected_ingredient_id
  );

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_refresh_recipe_allergen_tags
AFTER INSERT OR DELETE ON ingredient_allergen
FOR EACH ROW EXECUTE FUNCTION refresh_recipe_allergen_tags();
```

### One-time backfill

After seeding `ingredient_allergen`, run once to populate all existing recipes:

```sql
UPDATE recipe r
SET allergen_tags = (
  SELECT COALESCE(array_agg(DISTINCT a.slug), '{}')
  FROM recipe_ingredient ri
  JOIN ingredient_allergen ia ON ia.ingredient_id = ri.ingredient_id
  JOIN allergen a ON a.id = ia.allergen_id
  WHERE ri.recipe_id = r.id
);
```

---

## 4. New RPC — `search_allergens`

Powers the autocomplete in onboarding and preferences:

```sql
CREATE OR REPLACE FUNCTION search_allergens(p_query text)
RETURNS TABLE(id uuid, slug text, label text) AS $$
  SELECT id, slug, label
  FROM allergen
  WHERE is_active = true
    AND label ILIKE '%' || p_query || '%'
  ORDER BY label
  LIMIT 10;
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

---

## 5. RPC Allergen Filter Pattern

All feed and meal plan RPCs apply the same filter. A CTE fetches the user's allergen slugs once; recipes with any tag overlap are excluded.

```sql
WITH user_allergens AS (
  SELECT COALESCE(array_agg(a.slug), '{}') AS tags
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id
)
-- Added to every recipe WHERE clause:
AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
```

The `&&` array overlap operator combined with the GIN index makes this O(1) per recipe row.

### RPCs updated

| RPC | Change |
|-----|--------|
| `generate_feed_personalized` | Add `user_allergens` CTE + overlap filter |
| `generate_feed_exploration` | Same |
| `generate_feed_fresh` | Same |
| `recommend_recipes` | Same |
| `generate_meal_plan` | Same |
| `search_recipes` | Add filter (always active when user has allergies) |

The `generate-meal-plan` edge function requires no change — the RPC handles filtering internally.

---

## 6. Flutter Changes

### New provider: `userAllergyProvider`

- Reads `user_allergy` joined with `allergen` for the current user
- Exposes `List<AllergenModel>` (id, slug, label)
- Write methods: `addAllergy(allergenId)`, `removeAllergy(allergenId)`

### New provider: `searchAllergenProvider(query)`

- Calls `search_allergens` RPC with debounce (300ms)
- Returns `List<AllergenModel>` for autocomplete dropdown

### New widget: `AllergenPickerWidget`

Reusable, used in both `onboarding_page.dart` (step 4) and `preferences_page.dart`:

- Search field with debounced autocomplete dropdown
- Selected allergens shown as removable chips
- "Don't see your allergen? Submit it" link → inline text field → calls `submit-allergen-suggestion` edge function
- Reads initial state from `userAllergyProvider`

### `onboarding_page.dart` — Step 4

- Replace current freeform allergy text field + chip list with `AllergenPickerWidget`
- `OnboardingData` model: replace `allergies: List<String>` with `selectedAllergenIds: List<String>`

### `complete-onboarding` edge function

- After existing DB writes, insert selected allergen IDs into `user_allergy`:
  ```typescript
  // Delete existing then re-insert (same pattern as dietary restrictions)
  await client.from('user_allergy').delete().eq('user_id', user.id);
  if (allergenIds.length > 0) {
    await client.from('user_allergy').insert(
      allergenIds.map((id: string) => ({ user_id: user.id, allergen_id: id }))
    );
  }
  ```

### `preferences_page.dart`

- Replace existing allergy section with `AllergenPickerWidget`
- Backed directly by `userAllergyProvider` (real-time add/remove, no batch save needed)

---

## 7. New Edge Function — `submit-allergen-suggestion`

Simple, authenticated, minimal:

```typescript
// POST { label: string }
// Inserts into allergen_suggestion with status 'pending'
// Returns { success: true }
```

Admin reviews suggestions via Supabase dashboard and manually promotes approved ones to the `allergen` table.

---

## 8. Data Migration

Existing `user_dietary_restriction` rows that are freeform allergy strings (not `no_pork`, `no_meat`, `no_gluten`, `no_lactose`) cannot be reliably mapped to the new structured allergen IDs — they are freeform text. These rows are left in place but are effectively superseded by `user_allergy`. The app layer already distinguishes between known restrictions and custom strings, so no data loss occurs; users simply re-select allergens via the new picker.

---

## 9. Implementation Sequence

1. Migration: `allergen`, `ingredient_allergen`, `user_allergy`, `allergen_suggestion` tables + `recipe.allergen_tags` column + GIN index + seed data + trigger
2. Backfill `recipe.allergen_tags` for existing recipes
3. `search_allergens` RPC
4. Update all feed/meal plan RPCs with allergen filter
5. Flutter: `AllergenModel`, `userAllergyProvider`, `searchAllergenProvider`
6. Flutter: `AllergenPickerWidget`
7. Flutter: update onboarding step 4
8. Flutter: update preferences page
9. Update `complete-onboarding` edge function
10. New `submit-allergen-suggestion` edge function
