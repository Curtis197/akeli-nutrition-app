# Multi-Source Price Scraper — Design Spec
**Date:** 2026-07-01
**Status:** Approved

## Problem

The current `scrape_prices.py` has three critical flaws:
1. **Single source**: only searches Carrefour.fr; GB/CA/US prices are fabricated via flat currency multipliers.
2. **No validation**: bad matches (cat food, razor blades, cleaning products) are silently persisted to the DB.
3. **Fragile matching**: English ingredient names searched against French product titles produce wrong or zero matches.

## Goals

- Real local prices for all four markets: FR (Carrefour), GB (Tesco), US (Walmart), CA (Walmart.ca).
- Automatic reject gate that flags bad matches before any DB write.
- Google → ecommerce fallback for specialty African ingredients that never appear on mainstream retailers.
- Modular, one file per retailer, independently testable.

---

## Module Structure

```
python/
  scrapers/
    __init__.py
    base.py              # ScrapeResult dataclass + BaseScraper interface
    carrefour_fr.py      # Carrefour.fr  →  FR / EUR
    tesco_gb.py          # Tesco.com     →  GB / GBP
    walmart_us.py        # Walmart.com   →  US / USD
    walmart_ca.py        # Walmart.ca    →  CA / CAD
    openfoodfacts.py     # Open Food Facts Prices API pre-check (no browser)
    google_fallback.py   # Google Shopping → first ecommerce hit (browser)
  validator.py           # Coherence gate
  orchestrator.py        # Main entry point — replaces scrape_prices.py
  check_price_coherence.py   # Existing audit tool — keep unchanged
  scraped_prices.json        # Output: PASS/WARN results
  review_queue.json          # Output: REJECT/unfound items for manual fix
```

---

## Data Model

```python
# scrapers/base.py

@dataclass
class ScrapeResult:
    ingredient_id: str
    ingredient_name: str
    country_code: str        # 'FR' | 'GB' | 'US' | 'CA'
    currency: str            # 'EUR' | 'GBP' | 'USD' | 'CAD'
    scraped_title: str
    price_per_100g: float
    package_size: float
    package_unit: str        # 'g' | 'ml' | 'unit'
    source: str              # which module produced the result
    confidence: float        # 0.0–1.0 assigned by validator

class BaseScraper:
    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        raise NotImplementedError
```

Every scraper returns a `ScrapeResult` or `None`. The orchestrator never reads scraper internals.

---

## Per-Retailer Scrapers

Each module exposes `scrape(page, name_en, name_fr) -> ScrapeResult | None`.

| Module | Site | Search lang | Currency |
|---|---|---|---|
| `carrefour_fr` | carrefour.fr/s?q= | French (`name_fr`) | EUR |
| `tesco_gb` | tesco.com/groceries/en-GB/search | English (`name`) | GBP |
| `walmart_us` | walmart.com/search | English (`name`) | USD |
| `walmart_ca` | walmart.ca/search | English (`name`) | CAD |

**Shared price-parsing rules (applied in every scraper):**
- Extract price from an explicit `per kg` / `per 100g` / `per unit` label — no more hardcoded `/10.0`.
- Unit detection: parse weight/volume from the product title first; fall back to ingredient category default (`g` for solids, `ml` for liquids, `unit` for countables).
- Package size: parse from title; fall back to category defaults (1000g / 1000ml / 1 unit).

**`openfoodfacts.py`** — pure HTTP GET to `prices.openfoodfacts.org/api/v1/prices`. Takes the median of the top 5 results when ≥ 3 results exist. No Playwright dependency. Tried first for every ingredient × country before any browser is opened.

**`google_fallback.py`** — searches `"<ingredient_name> price buy <country>"` on Google Shopping via Playwright. Takes the first result that passes the validator's non-food blacklist and keyword check.

---

## Validator

`validator.validate(result, ingredient_name, ingredient_category) -> ValidationResult(verdict, reason)`

Verdicts: `PASS | WARN | REJECT`

### Check 1 — Non-food blacklist
Exact keyword match against: cleaning products, cosmetics, pet food, pest control, pharmaceuticals, alcohol brand names. Any hit → immediate `REJECT`.

### Check 2 — Keyword overlap score
Tokenise ingredient name + scraped title, normalise accents, strip stop-words. Compare using a built-in EN→FR translation table defined in `validator.py` covering ~30 common roots (carrot/carotte, chicken/poulet, beef/bœuf, rice/riz, onion/oignon, etc.).

- Score ≥ 0.3 → `PASS`
- 0.1–0.3 → `WARN`
- < 0.1 → `REJECT`

### Check 3 — Price range per category
The validator normalises the scraped price to EUR using hardcoded conversion rates (same rates used by the orchestrator) before comparing against thresholds. Thresholds are always expressed in EUR.

| Category | Min (€/100g) | Max (€/100g) |
|---|---|---|
| spice | 0.50 | 20.00 |
| meat | 0.50 | 8.00 |
| fish | 0.50 | 10.00 |
| vegetable | 0.05 | 4.00 |
| grain | 0.05 | 2.00 |
| oil | 0.20 | 3.00 |
| dairy | 0.10 | 3.00 |
| default | 0.03 | 25.00 |

Price > max×5 or < min÷5 → `REJECT`. Price outside range but within ×5 → `WARN`.

### Check 4 — Unit sanity
Solid ingredient with `package_unit = 'ml'` → auto-correct to `g` + add `WARN`. Package size outside {1, 6, 50, 100, 250, 500, 1000} → `WARN`, raw value preserved.

`PASS` and `WARN` results are saved to DB. `REJECT` results go to `review_queue.json` with verdict, reason, and last attempted source.

---

## Orchestrator

`orchestrator.py` is the sole entry point, replacing `scrape_prices.py`.

### Per-ingredient loop

```
for each ingredient:
  for each country in target_countries:
    1. Try openfoodfacts.py        (HTTP, no browser)
    2. If None → try retailer scraper for that country
    3. If None or REJECT → try google_fallback.py
    4. If still None or REJECT → append to review_queue.json
    5. On PASS or WARN → save to DB
```

### Browser management
One Playwright `browser` instance, four persistent `browser_context` objects (one per country) created at startup with country-appropriate `Accept-Language` headers. Reused across all ingredients.

### Output files
- `scraped_prices.json` — all PASS/WARN results (same schema as current)
- `review_queue.json` — REJECT/unfound entries: `{ ingredient_id, ingredient_name, country_code, last_source, reject_reason }`

### CLI

```
python orchestrator.py [options]

--countries FR,GB,US,CA     default: all four
--filter "dried crayfish"   scrape only ingredients matching this name
--retry-review              only process entries in review_queue.json
--dry-run                   validate and print, do not write to DB
--delay 2.0                 seconds between requests per country
```

### Post-run
After all countries complete, `recalculate_recipe_costs()` is called once per country.

---

## Migration

`scrape_prices.py` is **not deleted** — kept as a reference during the transition. `orchestrator.py` is the new entry point. Once all four country scrapers are validated on a full run, `scrape_prices.py` can be archived.

---

## What is NOT in scope

- Scheduling / cron automation (run manually for now)
- Price history tracking (only latest price per ingredient × country is stored)
- Currency exchange rate fetching (hardcoded rates acceptable for now; rates change slowly)
