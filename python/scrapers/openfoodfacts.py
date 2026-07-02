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
            # Note: the OFF Prices API has no `country` filter param — it's
            # rejected/ignored server-side. Country is filtered client-side
            # below using the nested location field the API actually returns.
            params = urllib.parse.urlencode({
                'product_name': search_term,
                'page_size': 20,
            })
            with urllib.request.urlopen(f"{self.BASE}?{params}", timeout=8) as r:
                data = json.loads(r.read().decode())

            prices = [
                item['price'] for item in data.get('items', [])
                if item.get('price')
                and item.get('location', {}).get('osm_address_country_code', '').upper() == self.country_code
            ][:5]  # spec: median of the top 5 results
            if len(prices) < 3:
                return None

            # OFF prices are per kg; convert to per 100g
            price_per_100g = statistics.median(prices) / 10.0
            first_title = next(
                (i.get('product', {}).get('product_name') or original_name
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
