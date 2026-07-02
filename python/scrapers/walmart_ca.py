import re, urllib.parse
from scrapers.base import BaseScraper, ScrapeResult, parse_price_per_100g, keyword_match

_STOP = {'great','value','walmart','brand','organic','fresh','frozen'}

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
            matches = [p for p in products if keyword_match(ingredient_name, p['title'], _STOP)]
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
