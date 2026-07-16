-- Exclude pending-unpublish recipes from NEW meal plans and personalized feed.
-- Bodies dumped from prod 2026-07-16 via pg_get_functiondef (repo migration files
-- had drifted from prod) with one added predicate per recipe-selection site.

CREATE OR REPLACE FUNCTION public.generate_meal_plan(p_user_id uuid, p_days integer, p_meals_per_day integer, p_start_date date, p_max_recipe_repeat integer DEFAULT 3)
 RETURNS TABLE(meal_plan_id uuid, entry_id uuid, component_id uuid, scheduled_date date, meal_type text, recipe_id uuid, recipe_title text, cover_image_url text, calories numeric, protein_g numeric, score double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_vector            vector(50);
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
  v_random_order           boolean := false;
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
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
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
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

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
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
      AND e.scheduled_date >= CURRENT_DATE;

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
    AND mpe.scheduled_date < CURRENT_DATE
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
    total_weight_g    numeric
  ) ON COMMIT DROP;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    IF v_current_date < CURRENT_DATE THEN
      CONTINUE;
    END IF;

    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_protein_density := (v_slot_rec->>'protein_pct')::numeric;
        v_target_fat_density     := (v_slot_rec->>'fat_pct')::numeric;
      ELSE
        v_target_protein_density := 7.5;
        v_target_fat_density     := 3.3;
      END IF;

      -- Pass 1: with blacklist
      v_recipe := NULL;
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                                THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001), 1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001), 1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN public.recipe_market_cost rmc 
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
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
        ORDER BY score DESC
        LIMIT 1;
      ELSE
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
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        LEFT JOIN public.recipe_market_cost rmc 
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
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
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- Pass 2: fallback — retry without blacklist if pool exhausted
      IF v_recipe.id IS NULL THEN
        IF v_user_vector IS NOT NULL THEN
          SELECT r.id, r.title, r.cover_image_url,
                 rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g, r.creator_id,
                 (
                   0.50 * (1 - (rv.vector <=> v_user_vector))
                          * CASE WHEN v_fan_creator_id IS NOT NULL
                                      AND r.creator_id = v_fan_creator_id
                                 THEN 1.5 ELSE 1.0 END
                   + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                           - v_target_protein_density)
                       / NULLIF(v_target_protein_density, 0.001), 1.0))
                   + 0.15 * CASE
                       WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                       WHEN r.preferred_meal_type = 'any'       THEN 0.5
                       ELSE 0.0
                     END
                   + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                           - v_target_fat_density)
                       / NULLIF(v_target_fat_density, 0.001), 1.0))
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_vector rv ON r.id = rv.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          LEFT JOIN public.recipe_market_cost rmc 
            ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
          WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
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
          ORDER BY score DESC
          LIMIT 1;
        ELSE
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
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
          LEFT JOIN public.recipe_market_cost rmc 
            ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
          WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
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
          GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                   rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                   rm.total_weight_g
          ORDER BY score DESC, COUNT(rl.recipe_id) DESC
          LIMIT 1;
        END IF;
      END IF;

      IF v_recipe.id IS NULL THEN
        IF v_weekly_budget > 0 AND EXISTS (
          SELECT 1
          FROM recipe r
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
            AND v_meal_type = ANY(r.meal_types)
            AND rm.kcal_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
        ) THEN
          RAISE EXCEPTION 'insufficient_budget';
        ELSE
          RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
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
        slot_nickname, slot_sort_order, total_weight_g
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
        v_recipe.total_weight_g
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

  -- 5. Pair dates with (potentially shuffled) meals and perform real DB inserts
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
           sm.slot_nickname, sm.slot_sort_order, sm.total_weight_g
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
      NULL::double precision;

  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_feed_personalized(p_user_id uuid, p_limit integer DEFAULT 140, p_exclude uuid[] DEFAULT '{}'::uuid[], p_region_id text DEFAULT NULL::text, p_difficulty text DEFAULT NULL::text, p_max_time_min integer DEFAULT NULL::integer, p_min_cal numeric DEFAULT NULL::numeric, p_max_cal numeric DEFAULT NULL::numeric, p_order_by text DEFAULT NULL::text, p_meal_type text DEFAULT NULL::text)
 RETURNS TABLE(recipe_id uuid, score numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_order_by IS NOT NULL AND p_order_by NOT IN ('rating', 'likes', 'created_at') THEN
    RAISE EXCEPTION 'Invalid p_order_by value: %. Valid values: rating, likes, created_at', p_order_by;
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN QUERY
    WITH user_allergens AS (
      SELECT COALESCE(array_agg(a.slug), '{}') AS tags
      FROM user_allergy ua
      JOIN allergen a ON a.id = ua.allergen_id
      WHERE ua.user_id = p_user_id
    )
    SELECT
      r.id AS recipe_id,
      CASE p_order_by
        WHEN 'rating'     THEN COALESCE(r.average_rating, 0)::numeric
        WHEN 'likes'      THEN COALESCE(r.like_count, 0)::numeric
        WHEN 'created_at' THEN (EXTRACT(EPOCH FROM r.created_at) / 1e9)::numeric
        ELSE              COALESCE(r.like_count, 0)::numeric
      END AS score
    FROM recipe r
    LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
    WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      AND (p_region_id    IS NULL OR r.region         = p_region_id)
      AND (p_difficulty   IS NULL OR r.difficulty     = p_difficulty)
      AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
      AND (p_min_cal IS NULL OR rm.calories_per_100g IS NULL OR rm.calories_per_100g >= p_min_cal)
      AND (p_max_cal IS NULL OR rm.calories_per_100g IS NULL OR rm.calories_per_100g <= p_max_cal)
      AND (p_meal_type IS NULL OR p_meal_type = ANY(r.meal_types))
      AND NOT EXISTS (
        SELECT 1 FROM recipe_performance_metrics rpm
        WHERE rpm.recipe_id = r.id
          AND rpm.drop_off_rate > 0.20
      )
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
    RETURN;
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id AS recipe_id,
    CASE p_order_by
      WHEN 'rating'     THEN COALESCE(r.average_rating, 0)::numeric
      WHEN 'likes'      THEN COALESCE(r.like_count, 0)::numeric
      WHEN 'created_at' THEN (EXTRACT(EPOCH FROM r.created_at) / 1e9)::numeric
      ELSE              (1 - (rv.vector <=> v_user_vector))::numeric
    END AS score
  FROM recipe r
  JOIN  recipe_vector rv ON rv.recipe_id = r.id
  LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
  WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND (p_region_id    IS NULL OR r.region         = p_region_id)
    AND (p_difficulty   IS NULL OR r.difficulty     = p_difficulty)
    AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
    AND (p_min_cal IS NULL OR rm.calories_per_100g IS NULL OR rm.calories_per_100g >= p_min_cal)
    AND (p_max_cal IS NULL OR rm.calories_per_100g IS NULL OR rm.calories_per_100g <= p_max_cal)
    AND (p_meal_type IS NULL OR p_meal_type = ANY(r.meal_types))
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.drop_off_rate > 0.20
    )
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  ORDER BY score DESC
  LIMIT LEAST(p_limit, 200);
END;
$function$
;
