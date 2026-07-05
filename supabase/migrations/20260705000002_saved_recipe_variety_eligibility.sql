-- Migration: 20260705000002_saved_recipe_variety_eligibility
-- Description: Part 1 — generate_meal_plan_from_saved skips the recency
-- blacklist per meal type when the user's saved pool for that type can't
-- sustain meal_variety_days, instead of reactively discovering this via a
-- failed Pass-1 query on every slot.

DROP FUNCTION IF EXISTS public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer);

CREATE OR REPLACE FUNCTION public.generate_meal_plan_from_saved(p_user_id uuid, p_days integer, p_meals_per_day integer, p_start_date date, p_max_recipe_repeat integer DEFAULT 3)
 RETURNS TABLE(meal_plan_id uuid, entry_id uuid, component_id uuid, scheduled_date date, meal_type text, recipe_id uuid, recipe_title text, cover_image_url text, calories numeric, protein_g numeric, score double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
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
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_variety_days           int    := 7;
  v_variety_eligible_types text[] := ARRAY[]::text[];
  v_pool_count             int;
  v_type                   text;
  v_recipe_found           boolean := false;
  v_random_order           boolean := false;
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_target_meal_cal        numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
  v_entry                  record;
  v_weekly_budget          numeric(10,2);
  v_country_code           text;
  v_target_meal_cost       numeric(10,2);
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() AND auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

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

  SELECT COALESCE(meal_variety_days, 7), COALESCE(meal_schedule_random, false), COALESCE(weekly_budget, 0), COALESCE(country_code, 'FR')
  INTO v_variety_days, v_random_order, v_weekly_budget, v_country_code
  FROM public.user_profile WHERE id = p_user_id;

  IF v_weekly_budget > 0 THEN
    v_target_meal_cost := v_weekly_budget / NULLIF(v_total_slots, 0);
  END IF;

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

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - v_variety_days)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  -- Part 1: pool-size precheck — only apply the recency blacklist for a meal
  -- type if the saved pool for that type is at least as large as the variety
  -- window. Otherwise Pass 1 could never succeed anyway, so skip straight to
  -- the no-blacklist query below instead of burning a doomed query per slot.
  FOR v_type IN SELECT DISTINCT (s->>'meal_type') FROM unnest(v_slots) AS s LOOP
    SELECT count(DISTINCT r.id) INTO v_pool_count
    FROM recipe r
    INNER JOIN recipe_save rs ON r.id = rs.recipe_id
    WHERE rs.user_id = p_user_id
      AND r.is_published = true
      AND v_type = ANY(r.meal_types)
      AND NOT (r.allergen_tags && v_user_allergens);

    IF v_variety_days = 0 OR v_pool_count >= v_variety_days THEN
      v_variety_eligible_types := v_variety_eligible_types || v_type;
    END IF;
  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
  CREATE TEMP TABLE temp_dates (
    id             serial,
    scheduled_date date,
    meal_type      text
  ) ON COMMIT DROP;

  CREATE TEMP TABLE temp_meals (
    id                serial,
    meal_type         text,
    recipe_id         uuid,
    recipe_title      text,
    cover_image_url   text,
    calories          numeric,
    protein_g         numeric,
    carbs_g           numeric,
    fat_g             numeric,
    grams             integer,
    slot_nickname     text,
    slot_sort_order   integer,
    total_weight_g    numeric,
    score             double precision
  ) ON COMMIT DROP;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      -- Pass 1: with blacklist — only attempted when the pool-size precheck
      -- flagged this meal type as able to sustain the variety window.
      v_recipe := NULL;
      v_recipe_found := false;
      IF v_meal_type = ANY(v_variety_eligible_types) THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
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
        LEFT JOIN public.recipe_market_cost rmc
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.kcal_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC, random()
        LIMIT 1;

        IF FOUND THEN
          v_recipe_found := true;
        END IF;
      END IF;

      -- Pass 2: fallback — no blacklist. Runs whenever Pass 1 was skipped
      -- (pool too small) or ran but found nothing.
      IF NOT v_recipe_found THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
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
        LEFT JOIN public.recipe_market_cost rmc
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.kcal_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC, random()
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        IF v_weekly_budget > 0 AND EXISTS (
          SELECT 1
          FROM recipe r
          INNER JOIN recipe_save rs ON r.id = rs.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE rs.user_id = p_user_id
            AND r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.kcal_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
        ) THEN
          RAISE EXCEPTION 'insufficient_budget';
        ELSE
          RAISE EXCEPTION 'insufficient_saved_recipes' USING DETAIL = v_meal_type;
        END IF;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      INSERT INTO temp_dates (scheduled_date, meal_type)
      VALUES (v_current_date, v_meal_type);

      INSERT INTO temp_meals (
        meal_type, recipe_id, recipe_title, cover_image_url,
        calories, protein_g, carbs_g, fat_g, grams,
        slot_nickname, slot_sort_order, total_weight_g, score
      )
      VALUES (
        v_meal_type, v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_grams,
        v_slot_nickname,
        v_slot_sort_order,
        v_recipe.total_weight_g,
        v_recipe.score
      );

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

    END LOOP;
  END LOOP;

  FOR v_entry IN (
    WITH shuffled_meals AS (
      SELECT t.*, row_number() OVER (PARTITION BY t.meal_type ORDER BY CASE WHEN v_random_order THEN random() ELSE t.id::double precision END) as rn
      FROM temp_meals t
    ),
    ordered_dates AS (
      SELECT d.*, row_number() OVER (PARTITION BY d.meal_type ORDER BY d.scheduled_date) as rn
      FROM temp_dates d
    )
    SELECT od.scheduled_date, sm.meal_type, sm.recipe_id, sm.recipe_title, sm.cover_image_url,
           sm.calories, sm.protein_g, sm.carbs_g, sm.fat_g, sm.grams,
           sm.slot_nickname, sm.slot_sort_order, sm.total_weight_g, sm.score
    FROM ordered_dates od
    JOIN shuffled_meals sm ON od.meal_type = sm.meal_type AND od.rn = sm.rn
    ORDER BY od.scheduled_date, sm.slot_sort_order
  ) LOOP

    INSERT INTO meal_plan_entry (
      meal_plan_id, scheduled_date, meal_type, servings,
      calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
      nickname, sort_order
    )
    VALUES (
      v_plan_id, v_entry.scheduled_date, v_entry.meal_type, v_entry.grams,
      v_entry.calories, v_entry.protein_g, v_entry.carbs_g, v_entry.fat_g,
      v_entry.slot_nickname, v_entry.slot_sort_order
    )
    RETURNING id INTO v_entry_id;

    INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
    VALUES (v_entry_id, v_entry.recipe_id, 'base', 1.0)
    RETURNING id INTO v_component_id;

    INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
    SELECT
      v_entry_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_entry.grams / NULLIF(v_entry.total_weight_g, 0),
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_entry.recipe_id
      AND ri.is_optional = false;

    RETURN QUERY SELECT
      v_plan_id, v_entry_id, v_component_id,
      v_entry.scheduled_date, v_entry.meal_type,
      v_entry.recipe_id, v_entry.recipe_title, v_entry.cover_image_url,
      v_entry.calories, v_entry.protein_g,
      v_entry.score::double precision;

  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;

  PERFORM public.create_batch_sessions_internal(v_plan_id, p_user_id, 7);
  PERFORM public.generate_shopping_list_internal(v_plan_id, p_user_id);

END;
$function$;

REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM anon;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- Part 2: couple the eligibility threshold to meal_variety_days.
-- 0 -> 7 (unchanged baseline), 7 -> 14, 15 -> 30.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.evaluate_saved_recipe_eligibility(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_was_eligible boolean;
  v_now_eligible boolean;
  v_variety_days int;
  v_target_count int;
BEGIN
  SELECT is_saved_recipe_eligible, COALESCE(meal_variety_days, 7)
  INTO v_was_eligible, v_variety_days
  FROM user_profile WHERE id = p_user_id;

  v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  IF v_breakfast_count >= v_target_count AND v_lunch_count >= v_target_count AND v_dinner_count >= v_target_count THEN
    v_now_eligible := true;
  ELSE
    v_now_eligible := false;
  END IF;

  IF v_now_eligible != COALESCE(v_was_eligible, false) THEN
    IF v_now_eligible = false THEN
      UPDATE user_profile
      SET is_saved_recipe_eligible = false, use_saved_recipes_only = false
      WHERE id = p_user_id;
    ELSE
      UPDATE user_profile
      SET is_saved_recipe_eligible = true
      WHERE id = p_user_id;
    END IF;
  END IF;
END;
$$;

DROP FUNCTION IF EXISTS public.get_saved_recipe_eligibility_progress(uuid);

CREATE OR REPLACE FUNCTION public.get_saved_recipe_eligibility_progress(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_is_eligible boolean;
  v_variety_days int;
  v_target_count int;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT is_saved_recipe_eligible, COALESCE(meal_variety_days, 7)
  INTO v_is_eligible, v_variety_days
  FROM user_profile WHERE id = p_user_id;

  v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  RETURN json_build_object(
    'is_eligible', COALESCE(v_is_eligible, false),
    'progress', json_build_array(
      json_build_object('meal_type', 'breakfast', 'saved_count', v_breakfast_count, 'target_count', v_target_count),
      json_build_object('meal_type', 'lunch', 'saved_count', v_lunch_count, 'target_count', v_target_count),
      json_build_object('meal_type', 'dinner', 'saved_count', v_dinner_count, 'target_count', v_target_count)
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION get_saved_recipe_eligibility_progress(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_saved_recipe_eligibility_progress(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION get_saved_recipe_eligibility_progress(uuid) TO authenticated;
