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

            # Match against the French name — that's the language we searched in.
            # No fallback to products[0]: an unmatched first result is exactly
            # the v1 failure mode (razor blades, cat food). Let the cascade
            # move on to the Google fallback instead.
            matches = [p for p in products
                       if _match(ingredient_name_fr or ingredient_name, p['title'])]
            if not matches:
                return None
            best = matches[0]

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
