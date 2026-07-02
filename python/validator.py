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
    'baume', 'crevasses', 'cicabiafine',
    'rasoir', 'lame de rasoir', 'philips oneblade',
    'matifiant', 'poudre legere', 'rimmel', 'peach glow', 'stay matte',
    'fond de teint', 'mascara', 'rouge a levres',
    'anti-mites', 'mites alimentaires', 'insecticide', 'piege vegetal',
    'croquettes', 'pour chat', 'pour chien',
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
