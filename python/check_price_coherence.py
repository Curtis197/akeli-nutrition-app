"""
Price coherence checker for scraped_prices.json.
Flags: bad keyword matches, price outliers, wrong units, duplicates, and unit/packaging anomalies.
"""

import json
import re
import sys
from collections import defaultdict

# ── helpers ─────────────────────────────────────────────────────────────────

def clean(text):
    t = text.lower()
    for src, dst in [('à','a'),('â','a'),('ä','a'),('é','e'),('è','e'),('ê','e'),
                     ('ë','e'),('î','i'),('ï','i'),('ô','o'),('ö','o'),('û','u'),
                     ('ü','u'),('ù','u'),('ç','c')]:
        t = t.replace(src, dst)
    t = re.sub(r'\(.*?\)', '', t)
    return t.strip()

FOOD_STOPWORDS = {
    'de','en','la','les','le','aux','au','avec','sans','vrac','simpl','carrefour',
    'classic','bio','organic','fresh','frais','and','with','for','extra','original',
    'the','a','of','du','des','or','al','pour'
}

NON_FOOD_KEYWORDS = [
    # cleaning / household
    'calcaire','anti-calcaire','nettoyant','menager','detartrant','desinfectant',
    'antibacterien','lessive','vaisselle','wc','hygiene',
    # cosmetics / health
    'baume','pieds','reparateur','crevasses','cicabiafine','rasoir','lame','philips',
    'matifiant','poudre legere','rimmel','peach glow','stay matte','fond de teint',
    'mascara','rouge a levres','parfum','shampoo','shampooing',
    # pest control / non-food
    'anti-mites','mites alimentaires','piege','vegetal','insecticide',
    # pet food
    'croquettes','chat','chien','senior','stérilisé','ultima',
    # alcohol / beverages (when ingredient is a food)
    'captain morgan','sans alcool spiced',
]

PRICE_THRESHOLDS = {
    # (min, max) per 100g in EUR for broad categories
    'spice':    (0.5,  20.0),
    'meat':     (0.5,  6.0),
    'fish':     (0.5,  8.0),
    'vegetable':(0.05, 3.0),
    'grain':    (0.05, 2.0),
    'oil':      (0.2,  3.0),
    'dairy':    (0.1,  3.0),
    'default':  (0.03, 25.0),  # catch cosmetics/razors above this
}

SPICE_NAMES = {
    'bay leaf','cumin','cinnamon','cloves','cardamom','paprika','turmeric','nutmeg',
    'coriander','pepper','black pepper','ginger','thyme','ras el hanout','curry',
    'harissa','berbere','suya spice','allspice','fenugreek'
}
MEAT_NAMES = {
    'beef','lamb','pork','chicken','goat meat','veal','mutton','rabbit',
    'beef blood','biltong','merguez','whole chicken','smoked chicken','smoked pork',
    'ground meat','natural casings','pigs feet','pigs\' feet'
}
FISH_NAMES = {
    'crab','shrimp','cod','cod fish','captain fish','dried fish','dried crayfish',
    'smoked fish','smoked mackerel','canned tuna','fresh fish','thiof fish',
    'fermented fish','dried shrimp powder'
}
VEGETABLE_NAMES = {
    'carrot','onion','red onion','potato','sweet potato','tomato','fresh tomato',
    'eggplant','african eggplant','green bell pepper','red bell pepper','spinach',
    'celery','taro','yam','cassava','okra','fresh okra','turnip','cabbage',
    'white cabbage','green cabbage','kale sukuma','green bananas matoke',
    'ripe plantain','unripe plantain'
}
GRAIN_NAMES = {
    'rice','long grain rice','broken rice','couscous','pasta','bread','stale bread',
    'wheat flour','corn flour','cornmeal','fine semolina','breadcrumbs','gari'
}
OIL_NAMES = {'olive oil','oil','vegetable oil','peanut oil','sesame oil','palm oil'}
DAIRY_NAMES = {'milk','evaporated milk','butter','creme fraiche','yogurt','curdled milk'}


def get_category(name):
    n = name.lower().strip()
    if any(s in n for s in SPICE_NAMES):    return 'spice'
    if any(s in n for s in MEAT_NAMES):     return 'meat'
    if any(s in n for s in FISH_NAMES):     return 'fish'
    if any(s in n for s in VEGETABLE_NAMES):return 'vegetable'
    if any(s in n for s in GRAIN_NAMES):    return 'grain'
    if any(s in n for s in OIL_NAMES):      return 'oil'
    if any(s in n for s in DAIRY_NAMES):    return 'dairy'
    return 'default'


def is_keyword_match(ingredient, title):
    q_clean = clean(ingredient)
    t_clean = clean(title)
    q_words = {w for w in re.findall(r'\w+', q_clean) if w not in FOOD_STOPWORDS and len(w) > 2}
    t_words  = set(re.findall(r'\w+', t_clean))
    if not q_words:
        return True  # can't check
    for qw in q_words:
        for tw in t_words:
            if qw in tw or tw in qw:
                return True
    return False


def detect_non_food(title):
    t = clean(title)
    hits = [kw for kw in NON_FOOD_KEYWORDS if kw in t]
    return hits


# ── main ────────────────────────────────────────────────────────────────────

def main(path='scraped_prices.json'):
    with open(path, encoding='utf-8') as f:
        items = json.load(f)

    print(f"Loaded {len(items)} entries\n")
    print("=" * 70)

    # 1. Non-food matches
    non_food = []
    for item in items:
        hits = detect_non_food(item['scraped_title'])
        if hits:
            non_food.append((item, hits))

    print(f"\n[!!] NON-FOOD / WRONG PRODUCT MATCHES  ({len(non_food)} found)")
    print("-" * 70)
    for item, hits in non_food:
        print(f"  BAD  {item['ingredient_name']}")
        print(f"       scraped: {item['scraped_title']}")
        print(f"       price:   {item['price_per_100g_eur']:.3f} EUR/100g | "
              f"pkg: {item['package_size']} {item['package_unit']}")
        print(f"       trigger: {', '.join(hits)}")

    # 2. Keyword mismatch (ingredient name has no word overlap with scraped title)
    mismatches = []
    for item in items:
        if not detect_non_food(item['scraped_title']):  # already flagged above
            if not is_keyword_match(item['ingredient_name'], item['scraped_title']):
                mismatches.append(item)

    print(f"\n[?]  KEYWORD MISMATCHES (no word overlap)  ({len(mismatches)} found)")
    print("-" * 70)
    for item in mismatches:
        print(f"  ???  {item['ingredient_name']}")
        print(f"       scraped: {item['scraped_title']}")
        print(f"       price:   {item['price_per_100g_eur']:.3f} EUR/100g | "
              f"pkg: {item['package_size']} {item['package_unit']}")

    # 3. Price outliers
    print(f"\n[$]  PRICE OUTLIERS")
    print("-" * 70)
    outliers = []
    for item in items:
        cat = get_category(item['ingredient_name'])
        lo, hi = PRICE_THRESHOLDS[cat]
        p = item['price_per_100g_eur']
        if p < lo or p > hi:
            outliers.append((item, cat, lo, hi, p))

    if outliers:
        for item, cat, lo, hi, p in sorted(outliers, key=lambda x: -x[4]):
            flag = '[HI]' if p > 20 else '[lo]'
            print(f"  {flag} {item['ingredient_name']}  ({cat})")
            print(f"       scraped: {item['scraped_title']}")
            print(f"       price: {p:.3f} EUR/100g  (expected {lo}-{hi} for {cat})")
    else:
        print("  None found.")

    # 4. Wrong unit (solid food with ml, or liquid with g)
    LIKELY_SOLID = {
        'bay leaf','bread','stale bread','kale','eggplant','carrot','potato',
        'onion','yam','taro','cassava','plantain','lamb','beef','pork','chicken',
        'rice','flour','pasta','legume','bean','spice','powder'
    }
    print(f"\n[u]  POSSIBLE UNIT ERRORS  (solid ingredient with ml, or pkg anomaly)")
    print("-" * 70)
    unit_errors = []
    for item in items:
        n = item['ingredient_name'].lower()
        is_solid_clue = any(s in n for s in LIKELY_SOLID)
        if is_solid_clue and item['package_unit'] == 'ml':
            unit_errors.append(item)
        elif item['package_size'] not in (1.0, 6.0, 50.0, 100.0, 250.0, 500.0, 1000.0):
            unit_errors.append(item)

    seen = set()
    for item in unit_errors:
        key = item['ingredient_id']
        if key not in seen:
            seen.add(key)
            print(f"  pkg  {item['ingredient_name']}")
            print(f"       scraped: {item['scraped_title']}")
            print(f"       pkg: {item['package_size']} {item['package_unit']} | "
                  f"price: {item['price_per_100g_eur']:.3f} EUR/100g")

    # 5. Duplicate ingredient names
    name_map = defaultdict(list)
    for item in items:
        name_map[item['ingredient_name'].strip().lower()].append(item)

    dupes = {k: v for k, v in name_map.items() if len(v) > 1}
    print(f"\n[2x] DUPLICATE INGREDIENT NAMES  ({len(dupes)} groups)")
    print("-" * 70)
    for name, group in sorted(dupes.items()):
        print(f"  '{name}' x{len(group)}")
        for item in group:
            print(f"     id: {item['ingredient_id'][:8]}...  "
                  f"price: {item['price_per_100g_eur']:.3f} EUR/100g  "
                  f"scraped: {item['scraped_title'][:50]}")

    # 6. Summary table of all prices (sorted by price)
    print(f"\n[=]  ALL PRICES (sorted high to low)")
    print("-" * 70)
    print(f"  {'Ingredient':<35} {'€/100g':>8}  {'Pkg':>12}  Scraped title (truncated)")
    print(f"  {'-'*35} {'-'*8}  {'-'*12}  {'-'*30}")
    for item in sorted(items, key=lambda x: -x['price_per_100g_eur']):
        pkg = f"{item['package_size']:.0f} {item['package_unit']}"
        print(f"  {item['ingredient_name']:<35} {item['price_per_100g_eur']:>8.3f}  "
              f"{pkg:>12}  {item['scraped_title'][:45]}")

    print("\n" + "=" * 70)
    print(f"Summary: {len(non_food)} non-food | {len(mismatches)} mismatches | "
          f"{len(outliers)} price outliers | {len(dupes)} dupe names")


if __name__ == '__main__':
    path = sys.argv[1] if len(sys.argv) > 1 else 'scraped_prices.json'
    main(path)
