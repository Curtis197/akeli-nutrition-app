# Ingredient Quantity Rounding Design

## Goal

Round scaled ingredient quantities to human-usable values in a cooking context. A 0.7-scaled fish should display as "1/2 fish", not "0.7 fish". A 237g flour should display as "235g", not "236.7g".

## Scope

Rounding applies only at **write time when quantities are scaled by servings**. It never touches `recipe_ingredient` (the author's original values). The three write points are:

1. `generate_meal_plan` → inserts into `meal_ingredient`
2. `swap_meal_plan_entry` → inserts into `meal_ingredient`
3. `create_batch_sessions` → inserts into `cooking_session_ingredient`

## Architecture

### Layer 1 — `unit_rounding_config` table (unit defaults)

```sql
CREATE TABLE unit_rounding_config (
  unit          text PRIMARY KEY,
  rounding_step numeric NOT NULL
);
```

Seeded with:

| unit    | rounding_step | rationale |
|---------|--------------|-----------|
| unit    | 0.5          | halves only — 1/2 onion, 1/2 lemon |
| piece   | 0.5          | halves only — 1/2 chicken breast |
| tsp     | 0.25         | quarter tsp is the standard minimum |
| tbsp    | 0.5          | half tbsp |
| clove   | 1            | whole cloves only |
| bunch   | 1            | whole bunches only |
| can     | 1            | whole cans only |
| pot     | 1            | whole pots only |
| pinch   | 0.5          | half pinch at most |
| g       | 5            | nearest 5g |
| ml      | 5            | nearest 5ml |
| kg      | 0.1          | nearest 100g |
| l       | 0.1          | nearest 100ml |

### Layer 2 — `ingredient_rounding_rule` table (per-ingredient overrides)

```sql
CREATE TABLE ingredient_rounding_rule (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id   uuid NOT NULL REFERENCES ingredient(id) ON DELETE CASCADE,
  unit            text NOT NULL,
  rounding_step   numeric,         -- NULL = no rounding (raw value)
  UNIQUE (ingredient_id, unit)
);
```

Supports the same ingredient appearing in multiple units with different rules (e.g. milk in `ml` → step 50, milk in `l` → step 0.1). A `NULL` step means "keep raw value — no rounding".

### Layer 3 — `round_to_step` SQL function

```sql
CREATE OR REPLACE FUNCTION round_to_step(qty numeric, step numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN step IS NULL OR step = 0 THEN qty
    WHEN qty = 0               THEN 0
    ELSE GREATEST(step, ROUND(qty / step) * step)
  END;
$$;
```

`GREATEST(step, ...)` ensures any non-zero quantity always produces at least 1 step — preventing a scaled 0.4 fish from rounding to 0.

### Lookup at write time

```sql
-- Effective step for a given (ingredient_id, unit):
COALESCE(
  (SELECT rounding_step FROM ingredient_rounding_rule
   WHERE ingredient_id = $1 AND unit = $2),
  (SELECT rounding_step FROM unit_rounding_config WHERE unit = $2),
  NULL  -- no rounding if unit not in config
)
```

## Fraction Display (Flutter — not DB)

The DB stores the rounded decimal. Flutter renders countable units as fractions using a display helper:

```dart
const _fractionMap = {
  0.25:  '1/4',
  0.333: '1/3',
  0.5:   '1/2',
  0.667: '2/3',
  0.75:  '3/4',
};

// Countable units: unit, piece, clove, bunch, can, pot, tsp, tbsp, pinch
String formatQuantity(double qty, String unit) {
  if (!isCountableUnit(unit)) return '$qty $unit';
  final whole = qty.floor();
  final decimal = qty - whole;
  final fraction = _fractionMap.entries
      .firstWhereOrNull((e) => (e.key - decimal).abs() < 0.01);
  if (decimal < 0.01) return '$whole $unit';
  if (whole == 0)    return '${fraction?.value ?? qty} $unit';
  return '$whole ${fraction?.value ?? decimal} $unit';
}
```

Examples: `0.5 unit` → "1/2 fish", `1.5 unit` → "1 1/2 fish", `0.25 tsp` → "1/4 tsp".

## Key Examples

| ingredient | unit | scaled qty | step | DB stores | displays |
|-----------|------|-----------|------|-----------|---------|
| fish (fractionable) | unit | 0.7 | 0.5 | 0.5 | 1/2 fish |
| fish (fractionable) | unit | 1.4 | 0.5 | 1.5 | 1 1/2 fish |
| fish (fractionable) | unit | 0.4 | 0.5 | 0.5 | 1/2 fish |
| egg (whole only) | unit | 0.7 | 1 | 1 | 1 egg |
| onion | unit | 0.8 | 0.5 | 1.0 | 1 onion |
| lemon | unit | 0.4 | 0.5 | 0.5 | 1/2 lemon |
| milk | ml | 237 | 50 | 250 | 250ml |
| milk | l | 0.237 | 0.1 | 0.2 | 0.2l |
| cumin | tsp | 0.6 | 0.25 | 0.75 | 3/4 tsp |
| flour | g | 237 | 5 | 235 | 235g |
| chicken | g | 423 | 25 | 425 | 425g |

## What Changes

### DB migrations
1. Create `unit_rounding_config` + seed with 13 unit defaults
2. Create `ingredient_rounding_rule` table
3. Create `round_to_step` function
4. Update `generate_meal_plan` — apply rounding in `meal_ingredient` INSERT
5. Update `swap_meal_plan_entry` — apply rounding in `meal_ingredient` INSERT
6. Update `create_batch_sessions` — apply rounding in `cooking_session_ingredient` INSERT

### Flutter
- Add `formatQuantity(qty, unit)` display helper
- Apply it wherever ingredient quantities are shown (shopping list, batch session, meal detail)

## What Does NOT Change

- `recipe_ingredient.quantity` — author's original values, never touched
- `meal_plan_entry.servings` — stays `numeric(4,1)`, rounding issue there is acceptable (±25 kcal)
- `shopping_list_item.quantity` — generated from already-rounded `cooking_session_ingredient`, so correct by derivation
