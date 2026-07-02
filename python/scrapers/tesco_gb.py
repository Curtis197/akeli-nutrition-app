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
