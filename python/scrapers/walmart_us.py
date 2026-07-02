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
