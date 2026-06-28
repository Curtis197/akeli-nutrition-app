-- supabase/migrations/20260628000003_generate_meal_plan_from_saved_distribution.sql
-- Description: Apply same slot-distribution changes to generate_meal_plan_from_saved.
-- Replaces v_meal_types text[] with v_slots JSONB[] read from meal_distribution.
-- Adds nickname and sort_order to meal_plan_entry INSERT.
-- Preserves service_role-only access (no auth.uid() guard, REVOKE from authenticated).

CREATE OR REPLACE FUNCTION public.generate_meal_plan_from_saved(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,   -- kept for backward compat; ignored when distribution exists
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  component_id    uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  score           double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
  -- Replaced: v_meal_types text[]
  v_slots                  JSONB[];
  v_slot_rec               JSONB;
  v_slot_nickname          text;
  v_slot_sort_order        integer;
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_target_meal_cal        numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  -- NOTE: no auth.uid() guard here — this function is called by the batch cron
  -- edge function as service_role (auth.uid() = NULL in that context).
  -- Access control is handled by REVOKE grants below + INTERNAL_SECRET in the edge function.

  -- ── Read slot structure from user's active distribution ────────────────────
  SELECT array_agg(
    jsonb_build_object(
      'meal_type',      md.meal_type,
      'calorie_target', COALESCE(md.calorie_target, 0),
      'protein_pct',    COALESCE(md.protein_pct, 25.0),
      'fat_pct',        COALESCE(md.fat_pct, 25.0),
      'nickname',       md.nickname,
      'sort_order',     md.sort_order
    ) ORDER BY md.sort_order
  ) INTO v_slots
  FROM meal_distribution md
  JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE np.user_id = p_user_id AND np.is_active = true;

  -- Fallback: default 3-meal structure if no distribution is saved
  IF v_slots IS NULL THEN
    v_slots := ARRAY[
      jsonb_build_object('meal_type','breakfast','calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',0),
      jsonb_build_object('meal_type','lunch',    'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',1),
      jsonb_build_object('meal_type','dinner',   'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',2)
    ];
  END IF;

  v_total_slots     := p_days * array_length(v_slots, 1);
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT id INTO v_existing_plan_id
  FROM public.meal_plan
  WHERE user_id    =  p_user_id
    AND start_date <= (p_start_date + (p_days - 1))
    AND end_date   >=  p_start_date
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_plan_id IS NOT NULL THEN
    DELETE FROM meal_plan_entry AS e
    WHERE e.meal_plan_id    = v_existing_plan_id
      AND e.scheduled_date >= p_start_date;

    UPDATE public.meal_plan
    SET end_date = GREATEST(end_date, p_start_date + (p_days - 1))
    WHERE id = v_existing_plan_id;

    v_plan_id := v_existing_plan_id;
  ELSE
    INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
    RETURNING id INTO v_plan_id;
  END IF;

  SELECT COALESCE(array_agg(mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_used_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  WHERE mpe.meal_plan_id   = v_plan_id
    AND mpe.scheduled_date < p_start_date
    AND mpec.role = 'base';

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    -- ── Iterate over user-defined slots ──────────────────────────────────────
    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      -- Per-slot calorie target (fall back to equal split)
      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      -- Select randomly from saved recipes, matching constraints
      SELECT r.id, r.title, r.cover_image_url,
             rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
             rm.total_weight_g,
             r.creator_id,
             (
               0.15 * CASE
                 WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                 WHEN r.preferred_meal_type = 'any'       THEN 0.5
                 ELSE 0.0
               END
             ) AS score
      INTO v_recipe
      FROM recipe r
      INNER JOIN recipe_save rs ON r.id = rs.recipe_id
      JOIN recipe_macro rm ON r.id = rm.recipe_id
      WHERE rs.user_id = p_user_id
        AND r.is_published = true
        AND v_meal_type = ANY(r.meal_types)
        AND rm.kcal_per_100g > 0
        AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
        AND (
          v_fan_creator_id IS NULL
          OR v_other_count < v_max_other_slots
          OR r.creator_id = v_fan_creator_id
        )
        AND (
          v_target_meal_cal IS NULL
          OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500
        )
        AND NOT (r.allergen_tags && v_user_allergens)
      ORDER BY score DESC, random()
      LIMIT 1;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_saved_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      -- Insert entry with nickname + sort_order
      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
        nickname, sort_order
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_grams,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_slot_nickname,
        v_slot_sort_order
      )
      RETURNING id INTO v_entry_id;

      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        round_to_step(
          ri.quantity * v_grams / NULLIF(v_recipe.total_weight_g, 0),
          COALESCE(
            (SELECT rounding_step FROM ingredient_rounding_rule
             WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
            (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
          )
        ),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

      RETURN QUERY SELECT
        v_plan_id, v_entry_id, v_component_id,
        v_current_date, v_meal_type,
        v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        v_recipe.score::double precision;

    END LOOP; -- slots
  END LOOP; -- days

  PERFORM public.create_batch_sessions_internal(v_plan_id, p_user_id, 7);
  PERFORM public.generate_shopping_list_internal(v_plan_id, p_user_id);

END;
$$;

-- Restrict to service_role only — this is a batch-internal function, not user-facing.
-- Users access meal plan generation via generate_meal_plan (the user-facing RPC).
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM anon;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM authenticated;
