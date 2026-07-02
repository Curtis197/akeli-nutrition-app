# Multi-Source Price Scraper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-source `scrape_prices.py` with a modular, validated, multi-country scraper covering FR/GB/US/CA with an Open Food Facts pre-check and Google Shopping fallback.

**Architecture:** 6 scraper modules behind a shared validator, orchestrated by `orchestrator.py`. Per ingredient × country: OFF API → retailer scraper → Google fallback. Results that fail validation go to `review_queue.json` instead of the DB.

**Tech Stack:** Python 3.14, Playwright (existing), psycopg2 (existing), python-dotenv (existing), pytest (add to venv), unittest.mock (stdlib)

## Global Constraints

- Venv at `python/venv/` — activate before any command: `python\venv\Scripts\Activate.ps1` (Windows)
- Install pytest once: `cd python && venv\Scripts\pip install pytest`
- Run all tests from project root: `python -m pytest python/tests/ -v`
- All scrapers return `ScrapeResult | None` — never raise exceptions to caller
- DB writes only on `PASS` or `WARN` verdict — never on `REJECT`
- `scrape_prices.py` is NOT deleted — kept as reference
- Validator price thresholds are in EUR; validator normalises local currency before comparing
- All `sys.path` inserts in test files use `os.path.join(os.path.dirname(__file__), '..')` to resolve `python/`

---

### Task 1: Scaffold — `scrapers/base.py` + `db.py`

**Files:**
- Create: `python/scrapers/__init__.py`
- Create: `python/scrapers/base.py`
- Create: `python/db.py`
- Create: `python/tests/__init__.py`
- Create: `python/tests/test_base.py`

**Interfaces:**
- Produces: `ScrapeResult` dataclass, `BaseScraper` class, `parse_price_per_100g(price_str, title) -> (float, float, str)`, `parse_package_info(title) -> (float|None, str|None)`, `get_ingredients()`, `save_market_price()`, `trigger_recipe_recalc()`

- [ ] **Step 1: Create empty init files**

Create `python/scrapers/__init__.py` — empty file.
Create `python/tests/__init__.py` — empty file.

- [ ] **Step 2: Write failing tests for base.py**

Create `python/tests/test_base.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from scrapers.base import ScrapeResult, parse_price_per_100g, parse_package_info

def test_scrape_result_fields():
    r = ScrapeResult(
        ingredient_id='abc', ingredient_name='Chicken', country_code='FR',
        currency='EUR', scraped_title='Filets de Poulet', price_per_100g=1.19,
        package_size=1000.0, package_unit='g', source='carrefour_fr'
    )
    assert r.ingredient_id == 'abc'
    assert r.package_unit == 'g'
    assert r.confidence == 0.0

def test_parse_price_per_kg():
    price, pkg_size, pkg_unit = parse_price_per_100g('3.49 / kg', 'Carottes vrac')
    assert abs(price - 0.349) < 0.001
    assert pkg_size == 1000.0
    assert pkg_unit == 'g'

def test_parse_price_per_100g_label():
    price, pkg_size, pkg_unit = parse_price_per_100g('£2.50 per 100g', 'Butter')
    assert abs(price - 2.50) < 0.001
    assert pkg_size == 100.0
    assert pkg_unit == 'g'

def test_parse_price_per_lb():
    price, pkg_size, pkg_unit = parse_price_per_100g('$3.98/lb', 'Beef')
    assert abs(price - 0.877) < 0.01
    assert pkg_unit == 'g'

def test_parse_price_per_unit():
    price, pkg_size, pkg_unit = parse_price_per_100g('1.30 each', 'Egg')
    assert abs(price - 1.30) < 0.001
    assert pkg_unit == 'unit'

def test_parse_price_per_litre():
    price, pkg_size, pkg_unit = parse_price_per_100g('1.20 / l', 'Coconut milk')
    assert abs(price - 0.12) < 0.001
    assert pkg_unit == 'ml'

def test_parse_package_info_kg():
    size, unit = parse_package_info('Riz Grain Long 1kg CARREFOUR')
    assert size == 1000.0
    assert unit == 'g'

def test_parse_package_info_ml():
    size, unit = parse_package_info('Lait de Coco 400ml KARA')
    assert size == 400.0
    assert unit == 'ml'

def test_parse_package_info_unit():
    size, unit = parse_package_info('Chou vert à la pièce')
    assert size == 1.0
    assert unit == 'unit'
```

- [ ] **Step 3: Run tests — expect FAIL**

```
python -m pytest python/tests/test_base.py -v
```
Expected: 9 FAILED with ImportError (module does not exist yet)

- [ ] **Step 4: Create `python/scrapers/base.py`**

```python
import re
from dataclasses import dataclass, field

@dataclass
class ScrapeResult:
    ingredient_id: str
    ingredient_name: str
    country_code: str
    currency: str
    scraped_title: str
    price_per_100g: float
    package_size: float
    package_unit: str       # 'g' | 'ml' | 'unit'
    source: str
    confidence: float = 0.0

class BaseScraper:
    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> 'ScrapeResult | None':
        raise NotImplementedError

def parse_package_info(title: str) -> tuple:
    """Return (package_size, package_unit) parsed from a product title, or (None, None)."""
    t = title.lower()
    m = re.search(r'([0-9]+[.,]?[0-9]*)\s*(g|kg|ml|l|cl|oz|lb)(?!\w)', t)
    if m:
        val = float(m.group(1).replace(',', '.'))
        unit = m.group(2)
        if unit == 'kg': return val * 1000.0, 'g'
        if unit == 'l':  return val * 1000.0, 'ml'
        if unit == 'cl': return val * 10.0,   'ml'
        if unit in ('g', 'oz', 'lb'): return val, 'g'
        return val, 'ml'
    if any(kw in t for kw in ('à la pièce', 'a la piece', 'each', 'per unit', 'unité', 'each')):
        return 1.0, 'unit'
    return None, None

def parse_price_per_100g(price_str: str, title: str) -> tuple:
    """
    Parse a retailer price label into (price_per_100g, package_size, package_unit).
    Raises ValueError if no numeric value found.
    price_str examples: '3,49 € / kg', '£2.50 per 100g', '$3.98/lb', '1.30 each'
    """
    s = price_str.lower().strip()
    m = re.search(r'([0-9]+[.,][0-9]+|[0-9]+)', s)
    if not m:
        raise ValueError(f"No numeric price in: {price_str!r}")
    val = float(m.group(1).replace(',', '.'))

    if '100g' in s or '100 g' in s:
        return val, 100.0, 'g'
    if '100ml' in s or '100 ml' in s:
        return val, 100.0, 'ml'
    if '/kg' in s or '/ kg' in s or 'per kg' in s or 'le kg' in s:
        return val / 10.0, 1000.0, 'g'
    if '/lb' in s or '/ lb' in s or 'per lb' in s:
        return val / 4.536, 1000.0, 'g'
    if '/oz' in s or '/ oz' in s or 'per oz' in s:
        return val / 0.2835, 1000.0, 'g'
    if '/l' in s or '/ l' in s or 'per litre' in s or 'per liter' in s or 'le litre' in s:
        return val / 10.0, 1000.0, 'ml'
    if '100ml' in s or '/ 100 ml' in s:
        return val, 100.0, 'ml'
    if 'each' in s or 'per unit' in s or '/ u' in s or '/ pce' in s:
        return val, 1.0, 'unit'

    # Fallback: infer from title package info
    pkg_size, pkg_unit = parse_package_info(title)
    if pkg_size and pkg_unit in ('g', 'ml') and pkg_size > 0:
        return val / (pkg_size / 100.0), pkg_size, pkg_unit

    # Default: assume price is per kg
    return val / 10.0, 1000.0, 'g'
```

- [ ] **Step 5: Run tests — expect PASS**

```
python -m pytest python/tests/test_base.py -v
```
Expected: 9 PASSED

- [ ] **Step 6: Create `python/db.py`**

Extract the three DB functions from `scrape_prices.py` verbatim, changing only the `source` default in `save_market_price`:

```python
import os, json, urllib.parse, urllib.request
from datetime import datetime
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()
load_dotenv('../.env')

DATABASE_URL            = os.getenv("DATABASE_URL", "")
SUPABASE_URL            = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY       = os.getenv("SUPABASE_ANON_KEY", "")

def _headers(use_service_key=True):
    key = SUPABASE_SERVICE_ROLE_KEY if use_service_key else SUPABASE_ANON_KEY
    return {'apikey': key, 'Authorization': f'Bearer {key}', 'Content-Type': 'application/json'}

def get_ingredients(limit=None, name_filter=None):
    if DATABASE_URL:
        try:
            q = "SELECT id, name, name_fr, name_en, category FROM ingredient"
            params = []
            if name_filter:
                q += " WHERE name ILIKE %s OR name_fr ILIKE %s OR name_en ILIKE %s"
                params.extend([f"%{name_filter}%"] * 3)
            q += " ORDER BY name ASC"
            if limit:
                q += " LIMIT %s"; params.append(limit)
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute(q, params)
                    return cur.fetchall()
        except Exception as e:
            print(f"Postgres failed: {e}. Trying REST...")
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError("No DB credentials available.")
    url = (f"{SUPABASE_URL}/rest/v1/ingredient"
           f"?select=id,name,name_fr,name_en,category&order=name.asc")
    if name_filter:
        esc = urllib.parse.quote(f"*{name_filter}*")
        url += f"&or=(name.ilike.{esc},name_fr.ilike.{esc},name_en.ilike.{esc})"
    if limit:
        url += f"&limit={limit}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=_headers(False))) as r:
        return json.loads(r.read().decode())

def save_market_price(ing_id, country, currency, price_per_100g,
                      package_size, package_unit, source='multi_scraper_v2'):
    if DATABASE_URL:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO ingredient_market_price
                            (ingredient_id,country_code,currency,price_per_100g,
                             package_size,package_unit,source,scraped_at)
                        VALUES (%s,%s,%s,%s,%s,%s,%s,NOW())
                        ON CONFLICT (ingredient_id,country_code) DO UPDATE
                        SET price_per_100g=EXCLUDED.price_per_100g,
                            package_size=EXCLUDED.package_size,
                            package_unit=EXCLUDED.package_unit,
                            source=EXCLUDED.source,
                            scraped_at=EXCLUDED.scraped_at
                    """, (ing_id,country,currency,price_per_100g,
                          package_size,package_unit,source))
                    conn.commit()
            return True
        except Exception as e:
            print(f"  Postgres save failed: {e}")
    hdrs = _headers(); hdrs['Prefer'] = 'resolution=merge-duplicates'
    payload = json.dumps({
        'ingredient_id': ing_id, 'country_code': country, 'currency': currency,
        'price_per_100g': price_per_100g, 'package_size': package_size,
        'package_unit': package_unit, 'source': source,
        'scraped_at': datetime.utcnow().isoformat()
    }).encode()
    with urllib.request.urlopen(urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/ingredient_market_price",
            headers=hdrs, data=payload, method='POST')) as r:
        return True

def trigger_recipe_recalc(country_code):
    if DATABASE_URL:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT recalculate_recipe_costs(%s)", (country_code,))
                    conn.commit()
            print(f"  Recalculation done: {country_code}")
            return True
        except Exception as e:
            print(f"  RPC failed: {e}")
    payload = json.dumps({'p_country_code': country_code}).encode()
    with urllib.request.urlopen(urllib.request.Request(
            f"{SUPABASE_URL}/rest/v1/rpc/recalculate_recipe_costs",
            headers=_headers(), data=payload, method='POST')):
        print(f"  Recalculation done: {country_code} (REST)")
    return True
```

- [ ] **Step 7: Commit**

```
git add python/scrapers/__init__.py python/scrapers/base.py python/db.py python/tests/__init__.py python/tests/test_base.py
git commit -m "feat: add scraper base dataclasses, price parser, and db utilities"
```

---

### Task 2: `validator.py`

**Files:**
- Create: `python/validator.py`
- Create: `python/tests/test_validator.py`

**Interfaces:**
- Consumes: `ScrapeResult` from `scrapers.base`
- Produces: `validate(result: ScrapeResult, ingredient_name: str, ingredient_category: str) -> ValidationResult`; `ValidationResult(verdict: str, reason: str, corrected_unit: str|None)`; exported `NON_FOOD_BLACKLIST: list[str]`; exported `_normalise(text: str) -> str`

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_validator.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from scrapers.base import ScrapeResult
from validator import validate, ValidationResult

def _r(**kw):
    base = dict(ingredient_id='id1', ingredient_name='Chicken', country_code='FR',
                currency='EUR', scraped_title='Filets de Poulet', price_per_100g=1.19,
                package_size=1000.0, package_unit='g', source='carrefour_fr')
    base.update(kw)
    return ScrapeResult(**base)

# Check 1 — non-food blacklist
def test_rejects_cleaning_product():
    r = _r(ingredient_name='Akpi', scraped_title='Nettoyant Ménager Anti-Calcaire ANTIKAL',
            price_per_100g=0.54, package_unit='ml')
    vr = validate(r, 'Akpi', 'spice')
    assert vr.verdict == 'REJECT'
    assert 'non-food' in vr.reason.lower()

def test_rejects_cat_food():
    r = _r(ingredient_name='Kale Sukuma',
            scraped_title='Croquettes pour Chat Senior ULTIMA', price_per_100g=0.70)
    vr = validate(r, 'Kale Sukuma', 'vegetable')
    assert vr.verdict == 'REJECT'

def test_rejects_cosmetics():
    r = _r(ingredient_name='Suya spice powder',
            scraped_title='Poudre Matifiante Stay Matte RIMMEL',
            price_per_100g=67.5, package_unit='ml')
    vr = validate(r, 'Suya spice powder', 'spice')
    assert vr.verdict == 'REJECT'

# Check 2 — keyword overlap with EN→FR translation
def test_pass_english_to_french_translation():
    r = _r(ingredient_name='Chicken', scraped_title='Filets de Poulet', price_per_100g=1.19)
    vr = validate(r, 'Chicken', 'meat')
    assert vr.verdict == 'PASS'

def test_reject_zero_overlap():
    r = _r(ingredient_name='Dried crayfish',
            scraped_title='Baume Pieds Réparateur Cicabiafine',
            price_per_100g=15.3, package_unit='ml')
    vr = validate(r, 'Dried crayfish', 'fish')
    assert vr.verdict == 'REJECT'

# Check 3 — price range
def test_reject_extreme_high_price():
    r = _r(ingredient_name='Suya spice powder',
            scraped_title='Suya Spice Mix', price_per_100g=67.5)
    vr = validate(r, 'Suya spice powder', 'spice')
    assert vr.verdict == 'REJECT'

def test_warn_slightly_outside_range():
    # Ginger at 0.45 €/100g is below spice min of 0.50 but within ×5 buffer
    r = _r(ingredient_name='Ginger', scraped_title='Gingembre frais', price_per_100g=0.45)
    vr = validate(r, 'Ginger', 'spice')
    assert vr.verdict == 'WARN'

def test_pass_in_range():
    r = _r(ingredient_name='Rice', scraped_title='Riz Basmati', price_per_100g=0.255)
    vr = validate(r, 'Rice', 'grain')
    assert vr.verdict == 'PASS'

# Check 4 — unit sanity
def test_auto_correct_solid_with_ml():
    r = _r(ingredient_name='Lamb', scraped_title="Gigot d'agneau",
            price_per_100g=3.625, package_unit='ml')
    vr = validate(r, 'Lamb', 'meat')
    assert vr.corrected_unit == 'g'
    assert vr.verdict == 'WARN'

def test_no_correction_for_liquid():
    r = _r(ingredient_name='Coconut milk', scraped_title='Lait de Coco KARA',
            price_per_100g=0.625, package_unit='ml')
    vr = validate(r, 'Coconut milk', 'dairy')
    assert vr.corrected_unit is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_validator.py -v
```
Expected: 10 FAILED (ImportError)

- [ ] **Step 3: Create `python/validator.py`**

```python
import re
from dataclasses import dataclass
from scrapers.base import ScrapeResult

@dataclass
class ValidationResult:
    verdict: str                   # 'PASS' | 'WARN' | 'REJECT'
    reason: str
    corrected_unit: str | None = None

# ── Non-food keyword blacklist ────────────────────────────────────────────────
NON_FOOD_BLACKLIST = [
    'calcaire', 'anti-calcaire', 'nettoyant', 'menager', 'detartrant',
    'lessive', 'vaisselle', 'desinfectant', 'antibacterien',
    'baume', 'pieds', 'crevasses', 'cicabiafine', 'reparateur peaux',
    'rasoir', 'lame de rasoir', 'philips oneblade',
    'matifiant', 'poudre legere', 'rimmel', 'peach glow', 'stay matte',
    'fond de teint', 'mascara', 'rouge a levres',
    'anti-mites', 'mites alimentaires', 'insecticide', 'piege vegetal',
    'croquettes', 'pour chat', 'pour chien', 'senior sterilis',
    'captain morgan', 'spiced gold 0.0',
]

# ── EN→FR root word translation table ────────────────────────────────────────
EN_FR = {
    'chicken': ['poulet'], 'beef': ['boeuf', 'bovin'],
    'pork': ['porc', 'cochon'], 'lamb': ['agneau'],
    'fish': ['poisson', 'filet'], 'shrimp': ['crevette'],
    'crab': ['crabe'], 'tuna': ['thon'], 'cod': ['cabillaud', 'morue'],
    'egg': ['oeuf'], 'milk': ['lait'], 'butter': ['beurre'],
    'cream': ['creme'], 'yogurt': ['yaourt'],
    'rice': ['riz'], 'flour': ['farine'], 'pasta': ['pate'],
    'bread': ['pain'], 'sugar': ['sucre'], 'salt': ['sel'],
    'oil': ['huile'], 'vinegar': ['vinaigre'],
    'carrot': ['carotte'], 'onion': ['oignon'], 'garlic': ['ail'],
    'tomato': ['tomate'], 'potato': ['pomme de terre', 'patate'],
    'spinach': ['epinard'], 'eggplant': ['aubergine'],
    'pepper': ['poivre', 'piment', 'poivron'],
    'chili': ['piment'], 'ginger': ['gingembre'],
    'cinnamon': ['cannelle'], 'cumin': ['cumin'],
    'coriander': ['coriandre'], 'turmeric': ['curcuma'],
    'plantain': ['plantain', 'banane'], 'cassava': ['manioc'],
    'yam': ['igname'], 'okra': ['gombo'], 'taro': ['taro'],
    'beans': ['haricot'], 'lentils': ['lentille'],
    'chickpeas': ['pois chiche'], 'semolina': ['semoule'],
    'honey': ['miel'], 'coconut': ['coco'], 'palm': ['palme'],
}

# ── Price thresholds per category (EUR/100g) ──────────────────────────────────
EUR_RATES = {'EUR': 1.0, 'GBP': 1.18, 'USD': 0.93, 'CAD': 0.68}
THRESHOLDS = {
    'spice':     (0.50, 20.0),
    'meat':      (0.50,  8.0),
    'fish':      (0.50, 10.0),
    'vegetable': (0.05,  4.0),
    'grain':     (0.05,  2.0),
    'oil':       (0.20,  3.0),
    'dairy':     (0.10,  3.0),
    'default':   (0.03, 25.0),
}
SOLID_CATEGORIES = {'meat', 'grain', 'spice', 'vegetable'}
STOP_WORDS = {
    'de','en','la','les','le','au','aux','avec','sans','du','des','and',
    'with','for','the','a','of','fresh','frais','bio','organic','vrac',
    'simpl','carrefour','classic','extra','original',
}

def _normalise(text: str) -> str:
    t = text.lower()
    for src, dst in [('à','a'),('â','a'),('ä','a'),('é','e'),('è','e'),('ê','e'),
                     ('ë','e'),('î','i'),('ï','i'),('ô','o'),('ö','o'),
                     ('û','u'),('ü','u'),('ù','u'),('ç','c')]:
        t = t.replace(src, dst)
    return t

def _keyword_score(ingredient_name: str, scraped_title: str) -> float:
    ing = _normalise(ingredient_name)
    title = _normalise(scraped_title)
    ing_words = {w for w in re.findall(r'\w+', ing)
                 if w not in STOP_WORDS and len(w) > 2}
    title_words = set(re.findall(r'\w+', title))

    expanded = set(ing_words)
    for en_word, fr_words in EN_FR.items():
        if en_word in ing:
            for fw in fr_words:
                expanded.update(re.findall(r'\w+', fw))

    if not expanded:
        return 0.5  # can't assess — give benefit of doubt

    matched = sum(
        1 for ew in expanded
        if any(ew in tw or tw in ew for tw in title_words)
    )
    return matched / len(expanded)

def validate(result: ScrapeResult, ingredient_name: str,
             ingredient_category: str) -> ValidationResult:
    title_norm = _normalise(result.scraped_title)

    # Check 1: non-food blacklist
    for kw in NON_FOOD_BLACKLIST:
        if kw in title_norm:
            return ValidationResult('REJECT', f'non-food keyword matched: {kw!r}')

    # Check 2: keyword overlap
    score = _keyword_score(ingredient_name, result.scraped_title)
    if score < 0.1:
        return ValidationResult('REJECT', f'keyword overlap too low: {score:.2f}')
    kw_verdict = 'PASS' if score >= 0.3 else 'WARN'
    kw_reason = f'keyword score {score:.2f}'

    # Check 3: price range (normalise to EUR)
    rate = EUR_RATES.get(result.currency, 1.0)
    price_eur = result.price_per_100g * rate
    lo, hi = THRESHOLDS.get(ingredient_category, THRESHOLDS['default'])
    if price_eur > hi * 5 or price_eur < lo / 5:
        return ValidationResult(
            'REJECT',
            f'price {price_eur:.2f} EUR/100g extreme for {ingredient_category} (range {lo}-{hi})'
        )
    price_verdict = 'PASS' if lo <= price_eur <= hi else 'WARN'
    price_reason = f'price {price_eur:.2f} EUR/100g (range {lo}-{hi})'

    # Check 4: unit sanity
    corrected_unit = None
    unit_verdict = 'PASS'
    if ingredient_category in SOLID_CATEGORIES and result.package_unit == 'ml':
        corrected_unit = 'g'
        unit_verdict = 'WARN'

    verdicts = [kw_verdict, price_verdict, unit_verdict]
    final = 'WARN' if 'WARN' in verdicts else 'PASS'
    parts = [kw_reason, price_reason,
             'unit corrected ml->g' if corrected_unit else None]
    reason = '; '.join(p for p in parts if p)
    return ValidationResult(final, reason, corrected_unit)
```

- [ ] **Step 4: Run tests — expect PASS**

```
python -m pytest python/tests/test_validator.py -v
```
Expected: 10 PASSED

- [ ] **Step 5: Commit**

```
git add python/validator.py python/tests/test_validator.py
git commit -m "feat: add validator with non-food blacklist, EN/FR keyword scoring, price range, unit sanity"
```

---

### Task 3: `scrapers/openfoodfacts.py`

**Files:**
- Create: `python/scrapers/openfoodfacts.py`
- Create: `python/tests/test_openfoodfacts.py`

**Interfaces:**
- Consumes: `BaseScraper`, `ScrapeResult`
- Produces: `OpenFoodFactsScraper(country_code, currency).scrape(page, name_en, name_fr) -> ScrapeResult | None` (`page` param unused — interface compatibility)

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_openfoodfacts.py`:
```python
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import patch, MagicMock
from scrapers.openfoodfacts import OpenFoodFactsScraper
from scrapers.base import ScrapeResult

MOCK_RESP = {"items": [
    {"product": {"product_name": "Chicken breast"}, "price": 11.90, "currency": "EUR", "location_country": "FR"},
    {"product": {"product_name": "Chicken breast"}, "price": 12.50, "currency": "EUR", "location_country": "FR"},
    {"product": {"product_name": "Filets de poulet"}, "price": 13.00, "currency": "EUR", "location_country": "FR"},
]}

def _mock_urlopen(body):
    cm = MagicMock()
    cm.__enter__ = lambda s: s
    cm.__exit__ = MagicMock(return_value=False)
    cm.read.return_value = json.dumps(body).encode()
    return cm

def test_returns_median_price():
    scraper = OpenFoodFactsScraper(country_code='FR', currency='EUR')
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(MOCK_RESP)):
        result = scraper.scrape(None, 'Chicken', 'Poulet')
    assert result is not None
    assert isinstance(result, ScrapeResult)
    # Prices are per kg [11.90, 12.50, 13.00]; median=12.50; /10 = 1.25
    assert abs(result.price_per_100g - 1.25) < 0.01
    assert result.source == 'openfoodfacts'
    assert result.country_code == 'FR'
    assert result.currency == 'EUR'

def test_returns_none_when_fewer_than_3_results():
    few = {"items": [
        {"product": {"product_name": "X"}, "price": 1.0, "currency": "EUR", "location_country": "FR"},
    ]}
    scraper = OpenFoodFactsScraper(country_code='FR', currency='EUR')
    with patch('urllib.request.urlopen', return_value=_mock_urlopen(few)):
        assert scraper.scrape(None, 'Chicken', 'Poulet') is None

def test_returns_none_on_http_error():
    scraper = OpenFoodFactsScraper(country_code='FR', currency='EUR')
    with patch('urllib.request.urlopen', side_effect=Exception("timeout")):
        assert scraper.scrape(None, 'Chicken', 'Poulet') is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_openfoodfacts.py -v
```
Expected: 3 FAILED (ImportError)

- [ ] **Step 3: Create `python/scrapers/openfoodfacts.py`**

```python
import json, statistics, urllib.parse, urllib.request
from scrapers.base import BaseScraper, ScrapeResult

class OpenFoodFactsScraper(BaseScraper):
    BASE = "https://prices.openfoodfacts.org/api/v1/prices"

    def __init__(self, country_code: str, currency: str):
        self.country_code = country_code
        self.currency = currency

    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        for term in {ingredient_name, ingredient_name_fr} - {None, ''}:
            result = self._fetch(term, ingredient_name)
            if result:
                return result
        return None

    def _fetch(self, search_term: str, original_name: str) -> ScrapeResult | None:
        try:
            params = urllib.parse.urlencode({
                'product_name': search_term,
                'country': self.country_code.lower(),
                'page_size': 10,
            })
            with urllib.request.urlopen(f"{self.BASE}?{params}", timeout=8) as r:
                data = json.loads(r.read().decode())

            prices = [
                item['price'] for item in data.get('items', [])
                if item.get('price')
                and item.get('location_country', '').upper() == self.country_code
            ]
            if len(prices) < 3:
                return None

            # OFF prices are per kg; convert to per 100g
            price_per_100g = statistics.median(prices) / 10.0
            first_title = next(
                (i['product'].get('product_name', original_name)
                 for i in data['items'] if i.get('price')),
                original_name
            )
            return ScrapeResult(
                ingredient_id='', ingredient_name=original_name,
                country_code=self.country_code, currency=self.currency,
                scraped_title=first_title, price_per_100g=price_per_100g,
                package_size=1000.0, package_unit='g', source='openfoodfacts',
            )
        except Exception as e:
            print(f"  [OFF] Error for '{search_term}': {e}")
            return None
```

- [ ] **Step 4: Run tests — expect PASS**

```
python -m pytest python/tests/test_openfoodfacts.py -v
```
Expected: 3 PASSED

- [ ] **Step 5: Commit**

```
git add python/scrapers/openfoodfacts.py python/tests/test_openfoodfacts.py
git commit -m "feat: add Open Food Facts API pre-check scraper"
```

---

### Task 4: `scrapers/carrefour_fr.py`

**Files:**
- Create: `python/scrapers/carrefour_fr.py`
- Create: `python/tests/test_carrefour_fr.py`

**Interfaces:**
- Consumes: `BaseScraper`, `ScrapeResult`, `parse_price_per_100g`, `parse_package_info`
- Produces: `CarrefourFrScraper().scrape(page, name_en, name_fr) -> ScrapeResult | None`

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_carrefour_fr.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.carrefour_fr import CarrefourFrScraper
from scrapers.base import ScrapeResult

def _page(products):
    p = MagicMock()
    p.goto = MagicMock()
    p.wait_for_timeout = MagicMock()
    p.locator.return_value.count.return_value = 0
    p.evaluate.return_value = products
    return p

def test_returns_result_for_matching_product():
    page = _page([{'title': 'Filets de Poulet', 'priceStr': '11,90 € / kg'}])
    result = CarrefourFrScraper().scrape(page, 'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'FR'
    assert result.currency == 'EUR'
    assert abs(result.price_per_100g - 1.19) < 0.01
    assert result.package_unit == 'g'
    assert result.source == 'carrefour_fr'

def test_returns_none_when_no_products():
    result = CarrefourFrScraper().scrape(_page([]), 'Akpi', 'Akpi')
    assert result is None

def test_parses_per_100g_price():
    page = _page([{'title': 'Poivre Noir Moulu CARREFOUR', 'priceStr': '2,36 € / 100g'}])
    result = CarrefourFrScraper().scrape(page, 'Black pepper', 'Poivre noir')
    assert result is not None
    assert abs(result.price_per_100g - 2.36) < 0.01

def test_returns_none_on_page_error():
    p = MagicMock()
    p.goto.side_effect = Exception("timeout")
    assert CarrefourFrScraper().scrape(p, 'Chicken', 'Poulet') is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_carrefour_fr.py -v
```
Expected: 4 FAILED (ImportError)

- [ ] **Step 3: Create `python/scrapers/carrefour_fr.py`**

```python
import re, urllib.parse
from scrapers.base import BaseScraper, ScrapeResult, parse_price_per_100g

_STOP = {'de','en','la','les','le','au','aux','avec','sans','vrac','simpl',
         'carrefour','classic','bio','frais','et','ou'}

def _match(query: str, title: str) -> bool:
    q = re.sub(r'\(.*?\)', '', query.lower()).strip()
    q_words = {w for w in re.findall(r'\w+', q) if w not in _STOP and len(w) > 2}
    t_words = set(re.findall(r'\w+', title.lower()))
    return not q_words or any(qw in tw or tw in qw for qw in q_words for tw in t_words)

class CarrefourFrScraper(BaseScraper):
    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        term = re.sub(r'\(.*?\)', '', ingredient_name_fr or ingredient_name).strip()
        url = f"https://www.carrefour.fr/s?q={urllib.parse.quote(term)}"
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=20000)
            page.wait_for_timeout(3000)
            try:
                btn = page.locator('button:has-text("Accepter tout")')
                if btn.count() > 0:
                    btn.first.click(); page.wait_for_timeout(1000)
            except Exception:
                pass

            products = page.evaluate("""() => {
                const res = [];
                document.querySelectorAll('*').forEach(card => {
                    const t = card.querySelector('.product-card-title__text');
                    const p = card.querySelector('[class*="per-unit-label"]');
                    if (t && p) {
                        const title = t.innerText.trim();
                        const priceStr = p.innerText.trim();
                        if (title && priceStr && !res.some(r => r.title === title))
                            res.push({ title, priceStr });
                    }
                });
                return res;
            }""")

            matches = [p for p in products if _match(ingredient_name, p['title'])]
            if not matches and not products:
                return None
            best = matches[0] if matches else products[0]

            try:
                price_per_100g, pkg_size, pkg_unit = parse_price_per_100g(
                    best['priceStr'], best['title'])
            except ValueError:
                return None

            return ScrapeResult(
                ingredient_id='', ingredient_name=ingredient_name,
                country_code='FR', currency='EUR',
                scraped_title=best['title'], price_per_100g=price_per_100g,
                package_size=pkg_size, package_unit=pkg_unit, source='carrefour_fr',
            )
        except Exception as e:
            print(f"  [Carrefour] Error for '{ingredient_name}': {e}")
            return None
```

- [ ] **Step 4: Run tests — expect PASS**

```
python -m pytest python/tests/test_carrefour_fr.py -v
```
Expected: 4 PASSED

- [ ] **Step 5: Commit**

```
git add python/scrapers/carrefour_fr.py python/tests/test_carrefour_fr.py
git commit -m "feat: add Carrefour FR scraper with improved price parsing"
```

---

### Task 5: `scrapers/tesco_gb.py`

**Files:**
- Create: `python/scrapers/tesco_gb.py`
- Create: `python/tests/test_tesco_gb.py`

**Interfaces:**
- Consumes: `BaseScraper`, `ScrapeResult`, `parse_price_per_100g`
- Produces: `TescoGbScraper().scrape(page, name_en, name_fr) -> ScrapeResult | None`

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_tesco_gb.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.tesco_gb import TescoGbScraper

def _page(products):
    p = MagicMock()
    p.goto = MagicMock(); p.wait_for_timeout = MagicMock()
    p.evaluate.return_value = products
    return p

def test_returns_result_for_chicken():
    result = TescoGbScraper().scrape(
        _page([{'title': 'Chicken Breast Fillets', 'priceStr': '£8.00/kg'}]),
        'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'GB'
    assert result.currency == 'GBP'
    assert abs(result.price_per_100g - 0.80) < 0.01
    assert result.source == 'tesco_gb'

def test_returns_result_per_100g():
    result = TescoGbScraper().scrape(
        _page([{'title': 'Black Pepper Ground', 'priceStr': '£1.80 per 100g'}]),
        'Black pepper', 'Poivre')
    assert result is not None
    assert abs(result.price_per_100g - 1.80) < 0.01

def test_returns_none_on_empty():
    assert TescoGbScraper().scrape(_page([]), 'Akpi', 'Akpi') is None

def test_returns_none_on_error():
    p = MagicMock(); p.goto.side_effect = Exception("blocked")
    assert TescoGbScraper().scrape(p, 'Chicken', 'Poulet') is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_tesco_gb.py -v
```
Expected: 4 FAILED (ImportError)

- [ ] **Step 3: Create `python/scrapers/tesco_gb.py`**

```python
import re, urllib.parse
from scrapers.base import BaseScraper, ScrapeResult, parse_price_per_100g

_STOP = {'fresh','organic','free','range','british','tesco','finest','everyday'}

def _match(query: str, title: str) -> bool:
    q = re.sub(r'\(.*?\)', '', query.lower()).strip()
    q_words = {w for w in re.findall(r'\w+', q) if w not in _STOP and len(w) > 2}
    t_words = set(re.findall(r'\w+', title.lower()))
    return not q_words or any(qw in tw or tw in qw for qw in q_words for tw in t_words)

class TescoGbScraper(BaseScraper):
    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        term = re.sub(r'\(.*?\)', '', ingredient_name).strip()
        url = f"https://www.tesco.com/groceries/en-GB/search?query={urllib.parse.quote(term)}"
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=25000)
            page.wait_for_timeout(3000)

            products = page.evaluate("""() => {
                const res = [];
                document.querySelectorAll(
                    '[data-auto="product-tile"], .product-list--list-item, .product-item'
                ).forEach(tile => {
                    const titleEl = tile.querySelector('a[class*="title"] span, .product-image--wrapper img, h3');
                    const priceEl = tile.querySelector('.price-per-quantity-weight, .price-per-sellable-unit, [data-auto="price-details"]');
                    const title    = titleEl?.innerText?.trim() || titleEl?.alt?.trim() || '';
                    const priceStr = priceEl?.innerText?.trim() || '';
                    if (title && priceStr) res.push({ title, priceStr });
                });
                return res.slice(0, 10);
            }""")

            matches = [p for p in products if _match(ingredient_name, p['title'])]
            if not matches:
                return None
            best = matches[0]
            try:
                price_per_100g, pkg_size, pkg_unit = parse_price_per_100g(best['priceStr'], best['title'])
            except ValueError:
                return None
            return ScrapeResult(
                ingredient_id='', ingredient_name=ingredient_name,
                country_code='GB', currency='GBP',
                scraped_title=best['title'], price_per_100g=price_per_100g,
                package_size=pkg_size, package_unit=pkg_unit, source='tesco_gb',
            )
        except Exception as e:
            print(f"  [Tesco] Error for '{ingredient_name}': {e}")
            return None
```

- [ ] **Step 4: Run tests — expect PASS**

```
python -m pytest python/tests/test_tesco_gb.py -v
```
Expected: 4 PASSED

- [ ] **Step 5: Commit**

```
git add python/scrapers/tesco_gb.py python/tests/test_tesco_gb.py
git commit -m "feat: add Tesco GB scraper"
```

---

### Task 6: `scrapers/walmart_us.py` + `scrapers/walmart_ca.py`

**Files:**
- Create: `python/scrapers/walmart_us.py`
- Create: `python/scrapers/walmart_ca.py`
- Create: `python/tests/test_walmart.py`

**Interfaces:**
- Consumes: `BaseScraper`, `ScrapeResult`, `parse_price_per_100g`
- Produces: `WalmartUsScraper().scrape(...)`, `WalmartCaScraper().scrape(...)`

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_walmart.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.walmart_us import WalmartUsScraper
from scrapers.walmart_ca import WalmartCaScraper

def _page(products):
    p = MagicMock()
    p.goto = MagicMock(); p.wait_for_timeout = MagicMock()
    p.evaluate.return_value = products
    return p

def test_walmart_us_returns_result():
    result = WalmartUsScraper().scrape(
        _page([{'title': 'Great Value Chicken Breast', 'priceStr': '$3.98/lb'}]),
        'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'US'
    assert result.currency == 'USD'
    assert abs(result.price_per_100g - 0.877) < 0.01   # 3.98 / 4.536
    assert result.source == 'walmart_us'

def test_walmart_us_returns_none_on_empty():
    assert WalmartUsScraper().scrape(_page([]), 'Akpi', 'Akpi') is None

def test_walmart_us_returns_none_on_error():
    p = MagicMock(); p.goto.side_effect = Exception("bot detected")
    assert WalmartUsScraper().scrape(p, 'Chicken', 'Poulet') is None

def test_walmart_ca_returns_result():
    result = WalmartCaScraper().scrape(
        _page([{'title': 'Chicken Breast Boneless', 'priceStr': '$12.98/kg'}]),
        'Chicken', 'Poulet')
    assert result is not None
    assert result.country_code == 'CA'
    assert result.currency == 'CAD'
    assert abs(result.price_per_100g - 1.298) < 0.01
    assert result.source == 'walmart_ca'

def test_walmart_ca_returns_none_on_empty():
    assert WalmartCaScraper().scrape(_page([]), 'Akpi', 'Akpi') is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_walmart.py -v
```
Expected: 5 FAILED (ImportError)

- [ ] **Step 3: Create `python/scrapers/walmart_us.py`**

Walmart embeds product data in `window.__NEXT_DATA__` — extract it directly to avoid CSS selector churn:

```python
import re, urllib.parse
from scrapers.base import BaseScraper, ScrapeResult, parse_price_per_100g

_STOP = {'great','value','walmart','brand','organic','fresh','frozen'}

def _match(query: str, title: str) -> bool:
    q = re.sub(r'\(.*?\)', '', query.lower()).strip()
    q_words = {w for w in re.findall(r'\w+', q) if w not in _STOP and len(w) > 2}
    t_words = set(re.findall(r'\w+', title.lower()))
    return not q_words or any(qw in tw or tw in qw for qw in q_words for tw in t_words)

_JS_NEXT_DATA = """() => {
    try {
        const items = window.__NEXT_DATA__?.props?.pageProps
            ?.initialData?.searchResult?.itemStacks?.[0]?.items || [];
        return items.slice(0, 10).map(i => ({
            title: i.name || '',
            priceStr: i.priceInfo?.unitPrice || i.priceInfo?.currentPrice?.priceString || ''
        })).filter(p => p.title && p.priceStr);
    } catch(e) { return []; }
}"""

_JS_DOM_FALLBACK = """() => {
    const res = [];
    document.querySelectorAll('[data-item-id]').forEach(card => {
        const t = card.querySelector('[itemprop="name"], a span')?.innerText?.trim() || '';
        const p = card.querySelector('[class*="unit-price"], [class*="price-per"]')?.innerText?.trim() || '';
        if (t && p) res.push({ title: t, priceStr: p });
    });
    return res.slice(0, 10);
}"""

class WalmartUsScraper(BaseScraper):
    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        term = re.sub(r'\(.*?\)', '', ingredient_name).strip()
        url = f"https://www.walmart.com/search?q={urllib.parse.quote(term)}"
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=25000)
            page.wait_for_timeout(4000)
            products = page.evaluate(_JS_NEXT_DATA) or page.evaluate(_JS_DOM_FALLBACK)
            matches = [p for p in products if _match(ingredient_name, p['title'])]
            if not matches:
                return None
            best = matches[0]
            try:
                price_per_100g, pkg_size, pkg_unit = parse_price_per_100g(best['priceStr'], best['title'])
            except ValueError:
                return None
            return ScrapeResult(
                ingredient_id='', ingredient_name=ingredient_name,
                country_code='US', currency='USD',
                scraped_title=best['title'], price_per_100g=price_per_100g,
                package_size=pkg_size, package_unit=pkg_unit, source='walmart_us',
            )
        except Exception as e:
            print(f"  [Walmart US] Error for '{ingredient_name}': {e}")
            return None
```

- [ ] **Step 4: Create `python/scrapers/walmart_ca.py`**

```python
import re, urllib.parse
from scrapers.base import BaseScraper, ScrapeResult, parse_price_per_100g

_STOP = {'great','value','walmart','brand','organic','fresh','frozen'}

def _match(query: str, title: str) -> bool:
    q = re.sub(r'\(.*?\)', '', query.lower()).strip()
    q_words = {w for w in re.findall(r'\w+', q) if w not in _STOP and len(w) > 2}
    t_words = set(re.findall(r'\w+', title.lower()))
    return not q_words or any(qw in tw or tw in qw for qw in q_words for tw in t_words)

_JS_NEXT_DATA = """() => {
    try {
        const items = window.__NEXT_DATA__?.props?.pageProps
            ?.initialData?.searchResult?.itemStacks?.[0]?.items || [];
        return items.slice(0, 10).map(i => ({
            title: i.name || '',
            priceStr: i.priceInfo?.unitPrice || i.priceInfo?.currentPrice?.priceString || ''
        })).filter(p => p.title && p.priceStr);
    } catch(e) { return []; }
}"""

_JS_DOM_FALLBACK = """() => {
    const res = [];
    document.querySelectorAll('[data-item-id], .search-item-card-wrapper').forEach(card => {
        const t = card.querySelector('[itemprop="name"], h3, a span')?.innerText?.trim() || '';
        const p = card.querySelector('[class*="unit-price"], [class*="price-per"]')?.innerText?.trim() || '';
        if (t && p) res.push({ title: t, priceStr: p });
    });
    return res.slice(0, 10);
}"""

class WalmartCaScraper(BaseScraper):
    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        term = re.sub(r'\(.*?\)', '', ingredient_name).strip()
        url = f"https://www.walmart.ca/en/search?q={urllib.parse.quote(term)}"
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=25000)
            page.wait_for_timeout(4000)
            products = page.evaluate(_JS_NEXT_DATA) or page.evaluate(_JS_DOM_FALLBACK)
            matches = [p for p in products if _match(ingredient_name, p['title'])]
            if not matches:
                return None
            best = matches[0]
            try:
                price_per_100g, pkg_size, pkg_unit = parse_price_per_100g(best['priceStr'], best['title'])
            except ValueError:
                return None
            return ScrapeResult(
                ingredient_id='', ingredient_name=ingredient_name,
                country_code='CA', currency='CAD',
                scraped_title=best['title'], price_per_100g=price_per_100g,
                package_size=pkg_size, package_unit=pkg_unit, source='walmart_ca',
            )
        except Exception as e:
            print(f"  [Walmart CA] Error for '{ingredient_name}': {e}")
            return None
```

- [ ] **Step 5: Run tests — expect PASS**

```
python -m pytest python/tests/test_walmart.py -v
```
Expected: 5 PASSED

- [ ] **Step 6: Commit**

```
git add python/scrapers/walmart_us.py python/scrapers/walmart_ca.py python/tests/test_walmart.py
git commit -m "feat: add Walmart US and CA scrapers"
```

---

### Task 7: `scrapers/google_fallback.py`

**Files:**
- Create: `python/scrapers/google_fallback.py`
- Create: `python/tests/test_google_fallback.py`

**Interfaces:**
- Consumes: `BaseScraper`, `ScrapeResult`, `parse_price_per_100g`, `parse_package_info`; `validator.NON_FOOD_BLACKLIST`, `validator._normalise`
- Produces: `GoogleFallbackScraper(country_code, currency).scrape(page, name_en, name_fr) -> ScrapeResult | None`

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_google_fallback.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import MagicMock
from scrapers.google_fallback import GoogleFallbackScraper

def _page(products):
    p = MagicMock()
    p.goto = MagicMock(); p.wait_for_timeout = MagicMock()
    p.evaluate.return_value = products
    return p

def test_returns_result_for_specialty_ingredient():
    result = GoogleFallbackScraper('FR', 'EUR').scrape(
        _page([{'title': 'Akpi seeds 200g afrishop', 'priceStr': '4.99', 'url': 'https://afrishop.fr/akpi'}]),
        'Akpi', 'Akpi')
    assert result is not None
    assert result.source == 'google_fallback'
    assert result.country_code == 'FR'
    assert result.price_per_100g > 0

def test_skips_non_food_hits():
    result = GoogleFallbackScraper('FR', 'EUR').scrape(
        _page([{'title': 'Nettoyant Anti-Calcaire ANTIKAL', 'priceStr': '3.50', 'url': 'https://shop.fr/clean'}]),
        'Akpi', 'Akpi')
    assert result is None

def test_returns_none_on_empty():
    assert GoogleFallbackScraper('FR', 'EUR').scrape(_page([]), 'Akpi', 'Akpi') is None

def test_returns_none_on_error():
    p = MagicMock(); p.goto.side_effect = Exception("blocked")
    assert GoogleFallbackScraper('FR', 'EUR').scrape(p, 'Akpi', 'Akpi') is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_google_fallback.py -v
```
Expected: 4 FAILED (ImportError)

- [ ] **Step 3: Create `python/scrapers/google_fallback.py`**

```python
import re, urllib.parse
from scrapers.base import BaseScraper, ScrapeResult, parse_price_per_100g, parse_package_info
from validator import NON_FOOD_BLACKLIST, _normalise

_LANG = {'FR': 'fr', 'GB': 'en', 'US': 'en', 'CA': 'en'}

class GoogleFallbackScraper(BaseScraper):
    def __init__(self, country_code: str, currency: str):
        self.country_code = country_code
        self.currency = currency

    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> ScrapeResult | None:
        lang = _LANG.get(self.country_code, 'en')
        query = f"{ingredient_name} buy price {self.country_code.lower()}"
        url = f"https://www.google.com/search?q={urllib.parse.quote(query)}&tbm=shop&hl={lang}"
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=20000)
            page.wait_for_timeout(3000)

            products = page.evaluate("""() => {
                const res = [];
                document.querySelectorAll(
                    '.sh-dgr__grid-result, .sh-dgr__content'
                ).forEach(card => {
                    const title    = card.querySelector('h3, .tAxDx')?.innerText?.trim() || '';
                    const priceStr = card.querySelector('.a8Pemb, .kHxwFf')?.innerText?.trim() || '';
                    const url      = card.querySelector('a[href]')?.href || '';
                    if (title && priceStr) res.push({ title, priceStr, url });
                });
                return res.slice(0, 5);
            }""")

            for product in products:
                if any(kw in _normalise(product['title']) for kw in NON_FOOD_BLACKLIST):
                    continue
                # Try to parse price with explicit unit label first
                try:
                    price_per_100g, pkg_size, pkg_unit = parse_price_per_100g(
                        product['priceStr'], product['title'])
                except ValueError:
                    # No unit label — infer from title package info
                    pkg_size, pkg_unit = parse_package_info(product['title'])
                    if not pkg_size:
                        continue
                    m = re.search(r'([0-9]+[.,][0-9]+|[0-9]+)', product['priceStr'])
                    if not m:
                        continue
                    val = float(m.group(1).replace(',', '.'))
                    price_per_100g = val / (pkg_size / 100.0)

                if price_per_100g <= 0:
                    continue

                return ScrapeResult(
                    ingredient_id='', ingredient_name=ingredient_name,
                    country_code=self.country_code, currency=self.currency,
                    scraped_title=product['title'], price_per_100g=price_per_100g,
                    package_size=pkg_size or 1000.0, package_unit=pkg_unit or 'g',
                    source='google_fallback',
                )
            return None
        except Exception as e:
            print(f"  [Google Fallback] Error for '{ingredient_name}': {e}")
            return None
```

- [ ] **Step 4: Run tests — expect PASS**

```
python -m pytest python/tests/test_google_fallback.py -v
```
Expected: 4 PASSED

- [ ] **Step 5: Commit**

```
git add python/scrapers/google_fallback.py python/tests/test_google_fallback.py
git commit -m "feat: add Google Shopping fallback scraper"
```

---

### Task 8: `orchestrator.py`

**Files:**
- Create: `python/orchestrator.py`
- Create: `python/tests/test_orchestrator.py`

**Interfaces:**
- Consumes: all scrapers, `validator.validate`, `db.get_ingredients`, `db.save_market_price`, `db.trigger_recipe_recalc`
- Produces: `run_cascade(page, context, ingredient, country_code) -> (ScrapeResult|None, ValidationResult|None)`; `main()` CLI

- [ ] **Step 1: Write failing tests**

Create `python/tests/test_orchestrator.py`:
```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from unittest.mock import patch, MagicMock
from scrapers.base import ScrapeResult
from validator import ValidationResult
import orchestrator

def _result(source='carrefour_fr'):
    return ScrapeResult(
        ingredient_id='id1', ingredient_name='Chicken', country_code='FR',
        currency='EUR', scraped_title='Filets de Poulet', price_per_100g=1.19,
        package_size=1000.0, package_unit='g', source=source)

_ING = {'id': 'id1', 'name': 'Chicken', 'name_fr': 'Poulet', 'category': 'meat'}

def test_cascade_uses_off_first():
    off = MagicMock(scrape=MagicMock(return_value=_result('openfoodfacts')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': off}), \
         patch('orchestrator.validate', return_value=ValidationResult('PASS', 'ok')):
        result, vr = orchestrator.run_cascade(None, None, _ING, 'FR')
    assert result.source == 'openfoodfacts'

def test_cascade_falls_back_to_retailer_when_off_none():
    retailer = MagicMock(scrape=MagicMock(return_value=_result('carrefour_fr')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': retailer}), \
         patch('orchestrator.validate', return_value=ValidationResult('PASS', 'ok')):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result.source == 'carrefour_fr'

def test_cascade_falls_back_to_google_on_reject():
    google = MagicMock(scrape=MagicMock(return_value=_result('google_fallback')))
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=_result()))}), \
         patch.dict('orchestrator.GOOGLE_SCRAPERS', {'FR': google}), \
         patch('orchestrator.validate', side_effect=[
             ValidationResult('REJECT', 'bad'), ValidationResult('PASS', 'ok')]):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result.source == 'google_fallback'

def test_cascade_returns_none_when_all_fail():
    with patch.dict('orchestrator.OFF_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.RETAILER_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}), \
         patch.dict('orchestrator.GOOGLE_SCRAPERS', {'FR': MagicMock(scrape=MagicMock(return_value=None))}):
        result, vr = orchestrator.run_cascade(MagicMock(), None, _ING, 'FR')
    assert result is None and vr is None
```

- [ ] **Step 2: Run tests — expect FAIL**

```
python -m pytest python/tests/test_orchestrator.py -v
```
Expected: 4 FAILED (ImportError)

- [ ] **Step 3: Create `python/orchestrator.py`**

```python
import argparse, json, sys, time
from playwright.sync_api import sync_playwright
from db import get_ingredients, save_market_price, trigger_recipe_recalc
from scrapers.openfoodfacts import OpenFoodFactsScraper
from scrapers.carrefour_fr import CarrefourFrScraper
from scrapers.tesco_gb import TescoGbScraper
from scrapers.walmart_us import WalmartUsScraper
from scrapers.walmart_ca import WalmartCaScraper
from scrapers.google_fallback import GoogleFallbackScraper
from validator import validate, ValidationResult

COUNTRIES = {'FR': 'EUR', 'GB': 'GBP', 'US': 'USD', 'CA': 'CAD'}
LOCALES   = {'FR': 'fr-FR,fr;q=0.9', 'GB': 'en-GB,en;q=0.9',
             'US': 'en-US,en;q=0.9', 'CA': 'en-CA,en;q=0.9'}

# Module-level dicts — patchable in tests
OFF_SCRAPERS:      dict = {}
RETAILER_SCRAPERS: dict = {}
GOOGLE_SCRAPERS:   dict = {}

def _build_scrapers():
    global OFF_SCRAPERS, RETAILER_SCRAPERS, GOOGLE_SCRAPERS
    OFF_SCRAPERS      = {c: OpenFoodFactsScraper(c, cur) for c, cur in COUNTRIES.items()}
    RETAILER_SCRAPERS = {'FR': CarrefourFrScraper(), 'GB': TescoGbScraper(),
                         'US': WalmartUsScraper(),  'CA': WalmartCaScraper()}
    GOOGLE_SCRAPERS   = {c: GoogleFallbackScraper(c, cur) for c, cur in COUNTRIES.items()}

def run_cascade(page, context, ingredient: dict, country_code: str):
    """Returns (ScrapeResult, ValidationResult) or (None, None)."""
    name_en  = ingredient.get('name', '')
    name_fr  = ingredient.get('name_fr') or name_en
    category = ingredient.get('category') or 'default'
    ing_id   = ingredient.get('id', '')

    def _try(scraper, use_page):
        if not scraper:
            return None, None
        result = scraper.scrape(use_page, name_en, name_fr)
        if not result:
            return None, None
        result.ingredient_id = ing_id
        vr = validate(result, name_en, category)
        return (result, vr) if vr.verdict != 'REJECT' else (None, None)

    result, vr = _try(OFF_SCRAPERS.get(country_code), None)
    if result:
        return result, vr

    result, vr = _try(RETAILER_SCRAPERS.get(country_code), page)
    if result:
        return result, vr

    return _try(GOOGLE_SCRAPERS.get(country_code), page)

def main():
    parser = argparse.ArgumentParser(description='Akeli Multi-Source Price Scraper v2')
    parser.add_argument('--countries', default='FR,GB,US,CA')
    parser.add_argument('--filter', dest='name_filter', default=None)
    parser.add_argument('--retry-review', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--delay', type=float, default=2.0)
    args = parser.parse_args()

    target = [c.strip().upper() for c in args.countries.split(',') if c.strip().upper() in COUNTRIES]
    if not target:
        print(f"No valid countries in: {args.countries}"); sys.exit(1)

    _build_scrapers()

    if args.retry_review:
        try:
            with open('review_queue.json', encoding='utf-8') as f:
                queue = json.load(f)
            ingredients = [{'id': e['ingredient_id'], 'name': e['ingredient_name'],
                             'name_fr': e['ingredient_name'], 'category': e.get('category', '')}
                           for e in queue]
            target = list({e['country_code'] for e in queue if e['country_code'] in COUNTRIES})
        except FileNotFoundError:
            print("review_queue.json not found."); sys.exit(1)
    else:
        ingredients = get_ingredients(name_filter=args.name_filter)

    print(f"Scraping {len(ingredients)} ingredients x {target}")
    scraped, review = [], []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        UA = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36')
        contexts = {c: browser.new_context(user_agent=UA, viewport={'width':1280,'height':800},
                                            extra_http_headers={'Accept-Language': LOCALES[c]})
                    for c in target}
        pages = {c: ctx.new_page() for c, ctx in contexts.items()}

        for idx, ing in enumerate(ingredients):
            print(f"\n[{idx+1}/{len(ingredients)}] {ing.get('name','')}")
            for code in target:
                print(f"  [{code}] ...", end='', flush=True)
                result, vr = run_cascade(pages[code], contexts[code], ing, code)
                if result and vr:
                    if vr.corrected_unit:
                        result.package_unit = vr.corrected_unit
                    print(f" {vr.verdict} | {result.source} | {result.price_per_100g:.3f} {result.currency}/100g")
                    scraped.append({
                        'ingredient_id': result.ingredient_id,
                        'ingredient_name': result.ingredient_name,
                        'country_code': result.country_code,
                        'scraped_title': result.scraped_title,
                        'price_per_100g': result.price_per_100g,
                        'package_size': result.package_size,
                        'package_unit': result.package_unit,
                        'source': result.source,
                        'verdict': vr.verdict, 'reason': vr.reason,
                    })
                    if not args.dry_run:
                        save_market_price(result.ingredient_id, result.country_code,
                                          result.currency, result.price_per_100g,
                                          result.package_size, result.package_unit,
                                          result.source)
                else:
                    print(f" UNFOUND")
                    review.append({'ingredient_id': ing.get('id',''),
                                   'ingredient_name': ing.get('name',''),
                                   'country_code': code,
                                   'category': ing.get('category',''),
                                   'last_source': 'all_failed',
                                   'reject_reason': 'no source returned a valid result'})
            if idx < len(ingredients) - 1:
                time.sleep(args.delay)

        for ctx in contexts.values():
            ctx.close()
        browser.close()

    with open('scraped_prices.json', 'w', encoding='utf-8') as f:
        json.dump(scraped, f, ensure_ascii=False, indent=2)
    with open('review_queue.json', 'w', encoding='utf-8') as f:
        json.dump(review, f, ensure_ascii=False, indent=2)

    print(f"\nSaved {len(scraped)} results | {len(review)} flagged for review")
    if not args.dry_run:
        for code in target:
            trigger_recipe_recalc(code)
    print("\n[SUCCESS] Scraper finished.")

if __name__ == '__main__':
    main()
```

- [ ] **Step 4: Run tests — expect PASS**

```
python -m pytest python/tests/test_orchestrator.py -v
```
Expected: 4 PASSED

- [ ] **Step 5: Run full test suite — all green**

```
python -m pytest python/tests/ -v
```
Expected: 34 PASSED across 7 test files

- [ ] **Step 6: Smoke test (dry-run, one ingredient)**

With venv activated and `.env` populated:
```
cd python
venv\Scripts\Activate.ps1
python orchestrator.py --filter "chicken" --countries FR --dry-run
```
Expected output:
```
Scraping 1 ingredients x ['FR']

[1/1] Chicken
  [FR] ... PASS | carrefour_fr | 1.190 EUR/100g

Saved 1 results to scraped_prices.json
0 flagged for review

[SUCCESS] Scraper finished.
```
`review_queue.json` should contain `[]`.

- [ ] **Step 7: Commit**

```
git add python/orchestrator.py python/tests/test_orchestrator.py
git commit -m "feat: add multi-source orchestrator with OFF→retailer→Google cascade, validation gate, and review queue"
```
