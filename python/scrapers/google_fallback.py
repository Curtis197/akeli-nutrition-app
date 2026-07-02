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
