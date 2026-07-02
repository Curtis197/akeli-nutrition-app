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
    if any(kw in t for kw in ('à la pièce', 'a la piece', 'each', 'per unit', 'unité')):
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
    if re.search(r'\beach\b', s) or 'per unit' in s or '/ u' in s or '/ pce' in s:
        return val, 1.0, 'unit'

    # Fallback: infer from title package info
    pkg_size, pkg_unit = parse_package_info(title)
    if pkg_size and pkg_unit in ('g', 'ml') and pkg_size > 0:
        return val / (pkg_size / 100.0), pkg_size, pkg_unit

    # Default: assume price is per kg
    return val / 10.0, 1000.0, 'g'
