# US Imperial Recipe Units — Design Spec

**Date:** 2026-06-28
**Scope:** fr / en / en-US pipeline only (es, pt, wo, bm, ln, ar deferred)

## Goal

African recipes authored in metric (g, ml, kg, l) are automatically converted to imperial (oz, lb, fl oz) for US users. US creators can author recipes in imperial; the app stores metric as canonical and preserves the imperial original. A single `user_profile.locale = 'en-US'` flag drives both the English text and the imperial quantity display.

---

## 1. Data Layer

### 1.1 `measurement_unit` — seed imperial units

Add 3 new rows (migration):

| code   | name_fr      | name_en       |
|--------|--------------|---------------|
| `oz`   | `oz`         | `oz`          |
| `lb`   | `lb`         | `lb`          |
| `fl_oz`| `fl oz`      | `fl oz`       |

Add matching `unit_rounding_config` rows:

| unit    | rounding_step |
|---------|--------------|
| `oz`    | 0.25         |
| `lb`    | 0.25         |
| `fl_oz` | 0.5          |

### 1.2 `user_profile.locale`

Already `text DEFAULT 'fr'` with no CHECK constraint. `'en-US'` is valid with no migration.

### 1.3 `recipe_translation`

Locale constraint stays unchanged (`fr/en/es/pt/wo/bm/ln/ar`). US users reuse the `'en'` text row — no `'en-US'` text row needed.

### 1.4 `recipe_ingredient_translation`

Exists on remote with `unit` column (indexed). Imperial ingredient rows are stored here with `locale = 'en-US'`.

If the table lacks a `quantity numeric` column, add it via migration:

```sql
ALTER TABLE recipe_ingredient_translation
  ADD COLUMN IF NOT EXISTS quantity numeric;
```

**Row shape for imperial:** `(recipe_ingredient_id, locale='en-US', quantity=<imperial_value>, unit='oz'|'lb'|'fl_oz'|'cup'|'tbsp'|'tsp', title=NULL)`

Countable units that are already US-compatible (`tsp`, `tbsp`, `cup`, `piece`, `clove`, `bunch`, `can`, `pot`, `pinch`) pass through unchanged — the `quantity` is copied and `unit` is unchanged.

---

## 2. Conversion Table (backend + Flutter)

Pure math, no AI needed for units.

| Metric unit | Imperial unit | Factor             | Notes                          |
|-------------|---------------|--------------------|--------------------------------|
| `g`         | `oz`          | ÷ 28.3495          | < 500g → oz; ≥ 500g → lb      |
| `kg`        | `lb`          | × 2.20462          |                                |
| `ml`        | `fl_oz`       | ÷ 29.5735          | < 60ml → tbsp (÷15); < 15ml → tsp (÷5) |
| `l`         | `fl_oz`       | × 33.814           | > 0.5l → cups (× 4.227)       |
| `tsp`, `tbsp`, `cup`, `piece`, `clove`, `bunch`, `can`, `pot`, `pinch` | same | 1.0 | pass-through |

Threshold logic for `g`:
- `qty_g < 500` → convert to oz, round to nearest 0.25
- `qty_g >= 500` → convert to lb, round to nearest 0.25

Threshold logic for `ml`:
- `qty_ml < 15` → tsp (`qty / 5`), round to nearest 0.25
- `15 ≤ qty_ml < 60` → tbsp (`qty / 15`), round to nearest 0.5
- `qty_ml ≥ 60` → fl oz (`qty / 29.5735`), round to nearest 0.5

---

## 3. Auto-Translation Pipeline

### 3.1 New edge function: `translate-recipe`

**Internal only** — gated by `INTERNAL_SECRET`. Not called from Flutter directly.

**Input body:**
```json
{ "recipe_id": "<uuid>" }
```

**Steps:**

1. `[STEP 1]` Fetch recipe: `title`, `description`, `recipe_step[]` (id, content, title), `recipe_ingredient[]` (id, quantity, unit, is_section_header, sort_order)
2. `[STEP 2]` For locale `en`: call `translate-content` for `title + description` → upsert `recipe_translation(recipe_id, locale='en', title, description, instructions='', is_auto=true)`
3. `[STEP 3]` For each step with locale `en`: call `translate-content` for step `content` (and `title` if present) → upsert `recipe_step_translation(step_id, locale='en', content, title)`
4. `[STEP 4]` For each `recipe_ingredient` row:
   - If `is_section_header = true`: call `translate-content` for section `title` → upsert `recipe_ingredient_translation(recipe_ingredient_id, locale='en-US', title=<translated>, quantity=NULL, unit=NULL)`
   - If `is_section_header = false`: apply conversion table → upsert `recipe_ingredient_translation(recipe_ingredient_id, locale='en-US', quantity=<imperial>, unit=<imperial_unit>, title=NULL)`
5. `[STEP 5]` Mark `recipe.translation_status = 'done'` (add column if needed — see §3.3)

**Error handling:** each step is wrapped independently; a failed step logs and continues (partial translations are better than none). Unhandled outer catch → `serverError`.

### 3.2 Postgres trigger — fires on publish

```sql
CREATE OR REPLACE FUNCTION trg_recipe_auto_translate()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.is_published = false AND NEW.is_published = true THEN
    PERFORM pg_net.http_post(
      url := current_setting('app.supabase_functions_url') || '/translate-recipe',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-internal-secret', current_setting('app.internal_secret')
      ),
      body := jsonb_build_object('recipe_id', NEW.id)::text
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recipe_publish_translate
  AFTER UPDATE OF is_published ON recipe
  FOR EACH ROW EXECUTE FUNCTION trg_recipe_auto_translate();
```

### 3.3 `recipe.translation_status` column (optional, deferred)

Can be added later to track `pending | done | failed` per recipe. Not required for V1.

---

## 4. US Creator Recipe Entry Flow

When creator's `locale = 'en-US'`:

1. **Recipe ingredient form** — unit picker shows imperial options: `oz`, `lb`, `fl_oz`, plus pass-through countables (`cup`, `tbsp`, `tsp`, `piece`, etc.)
2. **On save** — Flutter converts imperial → metric before writing `recipe_ingredient`:
   - `oz → g` (× 28.3495)
   - `lb → g` (× 453.592)
   - `fl_oz → ml` (× 29.5735)
   - Pass-throughs stored as-is
3. **Simultaneously** — Flutter upserts `recipe_ingredient_translation` rows with `locale='en-US'`, original imperial `quantity` + `unit` (no conversion needed — already imperial)
4. **On publish** — `translate-recipe` fires via trigger; it runs Steps 1–3 (text translation to `en`) and skips Step 4 for non-header ingredients where a `locale='en-US'` row already exists (upsert is idempotent anyway)

---

## 5. Flutter Layer

### 5.1 Locale detection

In `localeProvider` (or derived provider), expose:

```dart
bool get isUsLocale => locale == 'en-US';
String get textLocale => isUsLocale ? 'en' : locale;
```

### 5.2 Recipe text fetch

`recipe_provider.dart` — `_applyDetailTranslations` already maps locale to `recipe_translation`. Change the query to use `textLocale` instead of raw `locale`:

```dart
// BEFORE:
.eq('locale', locale)
// AFTER:
.eq('locale', ref.read(localeProvider).textLocale)
```

### 5.3 Ingredient quantity overlay

After loading `recipe.ingredients`, if `isUsLocale`, fetch:

```dart
recipe_ingredient_translation
  .select('recipe_ingredient_id, quantity, unit, title')
  .eq('locale', 'en-US')
  .inFilter('recipe_ingredient_id', ingIds)
```

Overlay: for each ingredient, if a matching row exists:
- Non-header: replace `quantity` + `unit`
- Header: replace `sectionTitle` with translated `title`

### 5.4 `quantity_formatter.dart` — locale-aware formatting

`formatQuantity` gains a `locale` parameter (`String locale = 'fr'`).

**French branch (existing behaviour, unchanged):** `_unitTranslations` applies (`tsp → c.à.c`, `clove → gousse`, etc.), plurals applied.

**English / en-US branch (`locale != 'fr'`):** unit codes rendered as-is in English (`tsp`, `tbsp`, `cup`, `clove`, `bunch`, `can`, `pot`, `pinch`). No French label mapping.

**Imperial units (`oz`, `fl_oz`):** added to `_countableUnits` — fraction display applies (`¼ oz`, `½ fl oz`). Rendered as-is (no translation needed).

**`lb`:** decimal branch — whole + `.25`/`.5`/`.75` suffix, not fractions.

All call sites of `formatQuantity` that are inside a widget `build()` pass `AppLocalizations.of(context).localeName` as `locale`.

### 5.5 Settings — locale picker

Add `'en-US'` option in `PreferencesPage` locale selector:
- `'fr'` → Français
- `'en'` → English
- `'en-US'` → English (US · Imperial)

When user switches to `'en-US'`, update `user_profile.locale = 'en-US'`. Invalidate recipe providers so quantities reload.

### 5.6 US creator unit picker

In the recipe ingredient form, if `locale == 'en-US'`, the unit `DropdownButton` shows imperial options first:
`[oz, lb, fl_oz, cup, tbsp, tsp, piece, clove, bunch, can, pot, pinch]`

Otherwise shows metric-first:
`[g, ml, kg, l, tsp, tbsp, cup, piece, clove, bunch, can, pot, pinch]`

---

## 6. L10n

Add ARB keys for the new locale label and any new settings strings:

```json
"preferencesLocaleUsImperial": "English (US · Imperial)",
"@preferencesLocaleUsImperial": {}
```

Both `app_en.arb` and `app_fr.arb` updated before any Dart reference.

---

## 7. Out of Scope (deferred)

- Locales: `es`, `pt`, `wo`, `bm`, `ln`, `ar`
- `recipe.translation_status` tracking column
- Shopping list quantity display in imperial
- Meal plan entry macro display in imperial
- Batch backfill for existing published recipes (separate one-off job)
