import json, re, urllib.parse, urllib.request
from scrapers.base import BaseScraper, ScrapeResult, keyword_match
from validator import NON_FOOD_BLACKLIST, _normalise

_STOP_WORDS = {'fresh', 'dried', 'ground', 'whole', 'organic', 'the', 'and', 'with', 'for'}

# This store's catalog is full of flavored/processed products that
# incidentally contain common ingredient words — live testing matched
# "Chicken" to "Instant Noodles with onion Chicken Flavor". Restricting to
# ingredients confirmed hard-to-find on mainstream retailers (they also
# failed on Carrefour FR) keeps false-positive risk low. Extend deliberately.
SPECIALTY_INGREDIENTS = {n.lower() for n in [
    'Akpi', 'Attiéké', 'Banana leaves', 'Berbere Spice', 'Berbere spice mix',
    'Biltong (Dried meat)', 'Bredes leaves', 'Cassava Flour', 'Cassava flour',
    'Chickpea powder Shiro', 'Chopped cassava leaves', 'Dried crayfish',
    'Dried fish Guedj', 'Dried fish powder', 'Dried shellfish Yet',
    'Egusi seeds', 'Green bananas Matoke', 'Kale Sukuma', 'Millet grains',
    'Ndole leaves', 'Palm nuts', 'Pilau spice mix', 'Pklala leaves (Crincrin)',
    'Pumpkin seeds (Egusi)', 'Seasoning cube', 'Sorghum leaves',
    'Suya spice powder', 'Teff Flour', 'Teff flour',
    'White hibiscus leaves (Bissap)',
]}

class AfroasiaUsScraper(BaseScraper):
    """
    US specialty African/Asian grocery source (afroasiaa.com, Shopify).
    Pure HTTP, no browser needed — no bot protection observed on this store.
    Only queried for ingredients in SPECIALTY_INGREDIENTS — see its comment.
    """
    BASE = "https://www.afroasiaa.com"

    def scrape(self, page, ingredient_name: str, ingredient_name_fr: str) -> 'ScrapeResult | None':
        if (ingredient_name or '').lower() not in SPECIALTY_INGREDIENTS:
            return None
        for term in dict.fromkeys(t for t in (ingredient_name, ingredient_name_fr) if t):
            result = self._search_and_fetch(term, ingredient_name)
            if result:
                return result
        return None

    def _search_and_fetch(self, search_term: str, original_name: str) -> 'ScrapeResult | None':
        q = re.sub(r'\(.*?\)', '', search_term).strip()
        try:
            params = urllib.parse.urlencode({
                'q': q, 'resources[type]': 'product', 'resources[limit]': 5,
            })
            with urllib.request.urlopen(f"{self.BASE}/search/suggest.json?{params}", timeout=8) as r:
                data = json.loads(r.read().decode())
            products = data.get('resources', {}).get('results', {}).get('products', [])
        except Exception as e:
            print(f"  [AfroAsia] Search error for '{search_term}': {e}")
            return None

        for p in products:
            title = p.get('title', '')
            if any(kw in _normalise(title) for kw in NON_FOOD_BLACKLIST):
                continue
            if not keyword_match(original_name, title, _STOP_WORDS):
                continue
            handle = p.get('handle')
            if not handle:
                continue
            result = self._fetch_product(handle, original_name, title)
            if result:
                return result
        return None

    def _fetch_product(self, handle: str, original_name: str, title: str) -> 'ScrapeResult | None':
        try:
            with urllib.request.urlopen(f"{self.BASE}/products/{handle}.json", timeout=8) as r:
                data = json.loads(r.read().decode())
            variants = data.get('product', {}).get('variants', [])
            valid = [v for v in variants if v.get('grams', 0) and v.get('grams') > 0 and v.get('price')]
            if not valid:
                return None

            # Cheapest variant is reliably the real single-unit package;
            # bulk "case" variants are always priced far higher in total.
            best = min(valid, key=lambda v: float(v['price']))
            grams = float(best['grams'])
            price = float(best['price'])
            price_per_100g = (price / grams) * 100.0

            return ScrapeResult(
                ingredient_id='', ingredient_name=original_name,
                country_code='US', currency='USD',
                scraped_title=title, price_per_100g=price_per_100g,
                package_size=grams, package_unit='g', source='afroasia_us',
            )
        except Exception as e:
            print(f"  [AfroAsia] Product fetch error for '{handle}': {e}")
            return None
