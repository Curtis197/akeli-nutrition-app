import argparse, json, sys, time
from playwright.sync_api import sync_playwright
from db import get_ingredients, save_market_price, trigger_recipe_recalc
from scrapers.openfoodfacts import OpenFoodFactsScraper
from scrapers.carrefour_fr import CarrefourFrScraper
from scrapers.tesco_gb import TescoGbScraper
from scrapers.walmart_us import WalmartUsScraper
from scrapers.walmart_ca import WalmartCaScraper
from scrapers.google_fallback import GoogleFallbackScraper
from validator import validate, ValidationResult

COUNTRIES = {'FR': 'EUR', 'GB': 'GBP', 'US': 'USD', 'CA': 'CAD'}
LOCALES   = {'FR': 'fr-FR,fr;q=0.9', 'GB': 'en-GB,en;q=0.9',
             'US': 'en-US,en;q=0.9', 'CA': 'en-CA,en;q=0.9'}

# Module-level dicts — patchable in tests
OFF_SCRAPERS:      dict = {}
RETAILER_SCRAPERS: dict = {}
GOOGLE_SCRAPERS:   dict = {}

def _build_scrapers():
    global OFF_SCRAPERS, RETAILER_SCRAPERS, GOOGLE_SCRAPERS
    OFF_SCRAPERS      = {c: OpenFoodFactsScraper(c, cur) for c, cur in COUNTRIES.items()}
    RETAILER_SCRAPERS = {'FR': CarrefourFrScraper(), 'GB': TescoGbScraper(),
                         'US': WalmartUsScraper(),  'CA': WalmartCaScraper()}
    GOOGLE_SCRAPERS   = {c: GoogleFallbackScraper(c, cur) for c, cur in COUNTRIES.items()}

def run_cascade(page, context, ingredient: dict, country_code: str):
    """Returns (ScrapeResult, ValidationResult) or (None, None)."""
    name_en  = ingredient.get('name', '')
    name_fr  = ingredient.get('name_fr') or name_en
    category = ingredient.get('category') or 'default'
    ing_id   = ingredient.get('id', '')

    def _try(scraper, use_page):
        if not scraper:
            return None, None
        result = scraper.scrape(use_page, name_en, name_fr)
        if not result:
            return None, None
        result.ingredient_id = ing_id
        vr = validate(result, name_en, category)
        return (result, vr) if vr.verdict != 'REJECT' else (None, None)

    result, vr = _try(OFF_SCRAPERS.get(country_code), None)
    if result:
        return result, vr

    result, vr = _try(RETAILER_SCRAPERS.get(country_code), page)
    if result:
        return result, vr

    return _try(GOOGLE_SCRAPERS.get(country_code), page)

def main():
    parser = argparse.ArgumentParser(description='Akeli Multi-Source Price Scraper v2')
    parser.add_argument('--countries', default='FR,GB,US,CA')
    parser.add_argument('--filter', dest='name_filter', default=None)
    parser.add_argument('--retry-review', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--delay', type=float, default=2.0)
    args = parser.parse_args()

    target = [c.strip().upper() for c in args.countries.split(',') if c.strip().upper() in COUNTRIES]
    if not target:
        print(f"No valid countries in: {args.countries}"); sys.exit(1)

    _build_scrapers()

    if args.retry_review:
        try:
            with open('review_queue.json', encoding='utf-8') as f:
                queue = json.load(f)
        except FileNotFoundError:
            print("review_queue.json not found."); sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"review_queue.json is corrupted: {e}"); sys.exit(1)
        # Group queue entries: one ingredient row with only its failed countries.
        by_id = {}
        for e in queue:
            if e['country_code'] not in COUNTRIES:
                continue
            row = by_id.setdefault(e['ingredient_id'], {
                'id': e['ingredient_id'], 'name': e['ingredient_name'],
                'name_fr': e.get('name_fr') or e['ingredient_name'],
                'category': e.get('category', ''), '_countries': []})
            row['_countries'].append(e['country_code'])
        ingredients = list(by_id.values())
        target = sorted({c for row in ingredients for c in row['_countries']})
        if not ingredients:
            print("review_queue.json is empty — nothing to retry."); sys.exit(0)
    else:
        ingredients = get_ingredients(name_filter=args.name_filter)

    print(f"Scraping {len(ingredients)} ingredients x {target}")
    scraped, review = [], []

    with sync_playwright() as p:
        browser = None
        contexts = {}
        try:
            browser = p.chromium.launch(headless=True)
            UA = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36')
            contexts = {c: browser.new_context(user_agent=UA, viewport={'width':1280,'height':800},
                                                extra_http_headers={'Accept-Language': LOCALES[c]})
                        for c in target}
            pages = {c: ctx.new_page() for c, ctx in contexts.items()}

            for idx, ing in enumerate(ingredients):
                print(f"\n[{idx+1}/{len(ingredients)}] {ing.get('name','')}")
                # In retry mode each row carries only its failed countries;
                # normal rows (from the DB) have no '_countries' key → all targets.
                for code in ing.get('_countries') or target:
                    print(f"  [{code}] ...", end='', flush=True)
                    try:
                        result, vr = run_cascade(pages[code], contexts[code], ing, code)
                    except Exception as e:
                        print(f" ERROR: {e}")
                        review.append({'ingredient_id': ing.get('id',''),
                                       'ingredient_name': ing.get('name',''),
                                       'name_fr': ing.get('name_fr') or '',
                                       'country_code': code,
                                       'category': ing.get('category',''),
                                       'last_source': 'unexpected_exception',
                                       'reject_reason': str(e)})
                        continue
                    if result and vr:
                        if vr.corrected_unit:
                            result.package_unit = vr.corrected_unit
                        print(f" {vr.verdict} | {result.source} | {result.price_per_100g:.3f} {result.currency}/100g")
                        scraped.append({
                            'ingredient_id': result.ingredient_id,
                            'ingredient_name': result.ingredient_name,
                            'country_code': result.country_code,
                            'scraped_title': result.scraped_title,
                            'price_per_100g': result.price_per_100g,
                            'package_size': result.package_size,
                            'package_unit': result.package_unit,
                            'source': result.source,
                            'verdict': vr.verdict, 'reason': vr.reason,
                        })
                        if not args.dry_run:
                            save_market_price(result.ingredient_id, result.country_code,
                                              result.currency, result.price_per_100g,
                                              result.package_size, result.package_unit,
                                              result.source)
                    else:
                        print(f" UNFOUND")
                        review.append({'ingredient_id': ing.get('id',''),
                                       'ingredient_name': ing.get('name',''),
                                       'name_fr': ing.get('name_fr') or '',
                                       'country_code': code,
                                       'category': ing.get('category',''),
                                       'last_source': 'all_failed',
                                       'reject_reason': 'no source returned a valid result'})
                if idx < len(ingredients) - 1:
                    time.sleep(args.delay)
        finally:
            for ctx in contexts.values():
                try:
                    ctx.close()
                except Exception as e:
                    print(f"  [warn] failed to close context: {e}")
            if browser is not None:
                try:
                    browser.close()
                except Exception as e:
                    print(f"  [warn] failed to close browser: {e}")

            with open('scraped_prices.json', 'w', encoding='utf-8') as f:
                json.dump(scraped, f, ensure_ascii=False, indent=2)
            with open('review_queue.json', 'w', encoding='utf-8') as f:
                json.dump(review, f, ensure_ascii=False, indent=2)

    print(f"\nSaved {len(scraped)} results | {len(review)} flagged for review")
    if not args.dry_run:
        for code in target:
            trigger_recipe_recalc(code)
    print("\n[SUCCESS] Scraper finished.")

if __name__ == '__main__':
    main()
