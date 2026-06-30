import os
import sys
import re
import time
import json
import argparse
import urllib.parse
import urllib.request
from datetime import datetime
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright

# Load environment variables
load_dotenv()
load_dotenv('../.env')

DATABASE_URL = os.getenv("DATABASE_URL", "")
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")

def get_headers(use_service_key=True):
    key = SUPABASE_SERVICE_ROLE_KEY if use_service_key else SUPABASE_ANON_KEY
    if not key:
        key = SUPABASE_ANON_KEY # fallback
    return {
        'apikey': key,
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json'
    }

def get_ingredients(limit=None, name_filter=None):
    """Fetch active ingredients from the database, trying Postgres first, then REST API."""
    if DATABASE_URL:
        try:
            print("Connecting to database via direct Postgres pooler...")
            query = "SELECT id, name, name_fr, name_en, category FROM ingredient"
            params = []
            
            if name_filter:
                query += " WHERE name ILIKE %s OR name_fr ILIKE %s OR name_en ILIKE %s"
                params.extend([f"%{name_filter}%", f"%{name_filter}%", f"%{name_filter}%"])
                
            query += " ORDER BY name ASC"
            if limit:
                query += " LIMIT %s"
                params.append(limit)
                
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute(query, params)
                    return cur.fetchall()
        except Exception as e:
            print(f"Postgres connection failed: {e}. Trying Supabase REST API...")

    # Fallback to Supabase REST API (Select query is safe with Anon Key)
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        print("Error: Neither DATABASE_URL nor SUPABASE_URL + SUPABASE_ANON_KEY are set.")
        sys.exit(1)
        
    print("Fetching ingredients via Supabase REST API...")
    select_fields = "id,name,name_fr,name_en,category"
    url = f"{SUPABASE_URL}/rest/v1/ingredient?select={select_fields}"
    
    # Apply filters in PostgREST format
    if name_filter:
        escaped_filter = urllib.parse.quote(f"*{name_filter}*")
        url += f"&or=(name.ilike.{escaped_filter},name_fr.ilike.{escaped_filter},name_en.ilike.{escaped_filter})"
        
    url += "&order=name.asc"
    if limit:
        url += f"&limit={limit}"
        
    try:
        req = urllib.request.Request(url, headers=get_headers(use_service_key=False))
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Error fetching ingredients via REST API: {e}")
        sys.exit(1)

def save_market_price(ing_id, country, currency, price_per_100g, package_size, package_unit):
    """Save ingredient market price to the database, trying Postgres first, then REST API."""
    if DATABASE_URL:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO ingredient_market_price (
                            ingredient_id, country_code, currency, price_per_100g, 
                            package_size, package_unit, source, scraped_at
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
                        ON CONFLICT (ingredient_id, country_code) DO UPDATE
                        SET price_per_100g = EXCLUDED.price_per_100g,
                            package_size = EXCLUDED.package_size,
                            package_unit = EXCLUDED.package_unit,
                            source = EXCLUDED.source,
                            scraped_at = EXCLUDED.scraped_at;
                    """, (
                        ing_id, country, currency, price_per_100g,
                        package_size, package_unit, 'carrefour_scraper_v1'
                    ))
                    conn.commit()
            return True
        except Exception as e:
            print(f"  Postgres save failed: {e}. Trying Supabase REST API...")
            
    # Fallback to Supabase REST API
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("  Error: Supabase Service Role Key is required for database write operations.")
        return False
        
    url = f"{SUPABASE_URL}/rest/v1/ingredient_market_price"
    payload = {
        "ingredient_id": ing_id,
        "country_code": country,
        "currency": currency,
        "price_per_100g": price_per_100g,
        "package_size": package_size,
        "package_unit": package_unit,
        "source": "carrefour_scraper_v1",
        "scraped_at": datetime.utcnow().isoformat()
    }
    
    headers = get_headers(use_service_key=True)
    # Add PostgREST upsert headers
    headers['Prefer'] = 'resolution=merge-duplicates'
    
    try:
        req = urllib.request.Request(
            url,
            headers=headers,
            data=json.dumps(payload).encode('utf-8'),
            method='POST'
        )
        with urllib.request.urlopen(req) as response:
            return True
    except Exception as e:
        print(f"  REST API save failed: {e}")
        return False

def trigger_recipe_recalc(country_code):
    """Trigger recalculate_recipe_costs function, trying Postgres first, then REST API."""
    if DATABASE_URL:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT recalculate_recipe_costs(%s)", (country_code,))
                    conn.commit()
            print(f"  -> Recalculation complete for {country_code} (Postgres)")
            return True
        except Exception as e:
            print(f"  Postgres RPC call failed: {e}. Trying Supabase REST API...")
            
    # Fallback to Supabase REST API
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("  Error: Supabase Service Role Key is required to call RPC functions.")
        return False
        
    url = f"{SUPABASE_URL}/rest/v1/rpc/recalculate_recipe_costs"
    payload = {"p_country_code": country_code}
    
    try:
        req = urllib.request.Request(
            url,
            headers=get_headers(use_service_key=True),
            data=json.dumps(payload).encode('utf-8'),
            method='POST'
        )
        with urllib.request.urlopen(req) as response:
            print(f"  -> Recalculation complete for {country_code} (REST API)")
            return True
    except Exception as e:
        print(f"  REST API RPC call failed: {e}")
        return False

def clean_term(text):
    if not text:
        return ""
    t = text.lower()
    t = re.sub(r'[àâä]', 'a', t)
    t = re.sub(r'[éèêë]', 'e', t)
    t = re.sub(r'[îï]', 'i', t)
    t = re.sub(r'[ôö]', 'o', t)
    t = re.sub(r'[ûüù]', 'u', t)
    t = re.sub(r'[ç]', 'c', t)
    t = re.sub(r'\(.*?\)', '', t)
    return t.strip()

def is_keyword_match(query_name, product_title):
    q_clean = clean_term(query_name)
    title_clean = clean_term(product_title)
    
    q_words = set(re.findall(r'\w+', q_clean))
    title_words = set(re.findall(r'\w+', title_clean))
    
    stop_words = {
        'de', 'en', 'la', 'les', 'le', 'aux', 'au', 'avec', 'sans', 'vrac', 
        'simpl', 'carrefour', 'classic', 'bio', 'organic', 'fresh', 'frais', 
        'and', 'with', 'for', 'l\'', 'd\'', 's'
    }
    keywords = {w for w in q_words if w not in stop_words and len(w) > 2}
    
    if not keywords:
        keywords = {w for w in q_words if len(w) > 1}
        
    for kw in keywords:
        for tw in title_words:
            if kw in tw or tw in kw:
                return True
    return False

def parse_package_info(title_text):
    t = title_text.lower()
    m = re.search(r'([0-9]+[.,]?[0-9]*)\s*(g|kg|ml|l|cl|oz|lb)', t)
    if m:
        val = float(m.group(1).replace(',', '.'))
        unit = m.group(2)
        if unit == 'kg' or unit == 'l':
            return val * 1000.0, 'g' if unit == 'kg' else 'ml'
        elif unit == 'cl':
            return val * 10.0, 'ml'
        else:
            return val, 'g' if unit in ['g', 'oz', 'lb'] else 'ml'
            
    m_pce = re.search(r'(?:x\s*|([0-9]+)\s*)(?:pieces?|pieces?|unites?|units?|oeufs?|pcs)', t)
    if m_pce:
        val_str = m_pce.group(1) or m_pce.group(0).replace('x', '').strip()
        try:
            return float(val_str), 'unit'
        except ValueError:
            pass
            
    return None, None

def scrape_carrefour_price(page, ingredient_name):
    search_query = ingredient_name
    search_query = re.sub(r'\(.*?\)', '', search_query).strip()
    
    url = f"https://www.carrefour.fr/s?q={urllib.parse.quote(search_query)}"
    
    try:
        page.goto(url, wait_until="domcontentloaded", timeout=20000)
        page.wait_for_timeout(3000)
        
        try:
            cookie_btn = page.locator('button:has-text("Accepter tout")')
            if cookie_btn.count() > 0:
                cookie_btn.first.click()
                page.wait_for_timeout(1000)
        except Exception:
            pass
            
        products = page.evaluate("""() => {
            const results = [];
            const cards = document.querySelectorAll('*');
            for (const card of cards) {
                const titleEl = card.querySelector('.product-card-title__text');
                const priceEl = card.querySelector('[class*="per-unit-label"]');
                if (titleEl && priceEl) {
                    const title = titleEl.innerText.trim();
                    const priceStr = priceEl.innerText.trim();
                    if (!results.some(r => r.title === title)) {
                        results.push({ title, priceStr });
                    }
                }
            }
            return results;
        }""")
        
        matching_products = []
        for p in products:
            if is_keyword_match(ingredient_name, p['title']):
                matching_products.append(p)
                
        if not matching_products:
            if products:
                matching_products = [products[0]]
            else:
                return None
                
        best_match = matching_products[0]
        title = best_match['title']
        price_str = best_match['priceStr']
        
        price_val_match = re.search(r'([0-9]+[.,][0-9]{2})', price_str)
        if not price_val_match:
            return None
            
        price_val = float(price_val_match.group(1).replace(',', '.'))
        package_size, package_unit = parse_package_info(title)
        
        price_per_100g = price_val / 10.0
        
        if 'unit' in price_str.lower() or '/ u' in price_str.lower() or '/ pce' in price_str.lower() or '/ p' in price_str.lower():
            price_per_100g = price_val
            if not package_size:
                package_size = 1.0
                package_unit = 'unit'
                
        if not package_size:
            package_size = 1000.0 if 'kg' in price_str.lower() or '/ l' in price_str.lower() else 100.0
            package_unit = 'g' if 'kg' in price_str.lower() else 'ml'
            
        return {
            'scraped_title': title,
            'price_per_100g_eur': price_per_100g,
            'package_size': package_size,
            'package_unit': package_unit
        }
        
    except Exception as e:
        print(f"  Error scraping '{ingredient_name}': {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Akeli Ingredient Price Scraper")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of ingredients to scrape")
    parser.add_argument("--query", type=str, default=None, help="Scrape only ingredients matching this query")
    parser.add_argument("--dry-run", action="store_true", help="Scrape prices but don't save to DB")
    parser.add_argument("--delay", type=float, default=2.0, help="Delay between searches in seconds")
    args = parser.parse_args()
    
    ingredients = get_ingredients(limit=args.limit, name_filter=args.query)
    print(f"Loaded {len(ingredients)} ingredients to process.")
    
    if not ingredients:
        print("No ingredients to scrape.")
        return
        
    # Exchange rate conversion factors
    conversion_rates = {
        'FR': {'rate': 1.0, 'currency': 'EUR'},
        'GB': {'rate': 0.85, 'currency': 'GBP'},
        'CA': {'rate': 1.45, 'currency': 'CAD'},
        'US': {'rate': 1.08, 'currency': 'USD'}
    }
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        
        for idx, ing in enumerate(ingredients):
            name = ing.get('name_fr') or ing.get('name')
            print(f"[{idx+1}/{len(ingredients)}] Scraping '{name}'...")
            
            result = scrape_carrefour_price(page, name)
            
            if result:
                print(f"  -> Found: {result['scraped_title']}")
                print(f"     Price/100g (EUR): {result['price_per_100g_eur']:.4f} | Pkg: {result['package_size']} {result['package_unit']}")
                
                if not args.dry_run:
                    saved_all = True
                    for country, info in conversion_rates.items():
                        converted_price = result['price_per_100g_eur'] * info['rate']
                        success = save_market_price(
                            ing['id'], country, info['currency'], converted_price,
                            result['package_size'], result['package_unit']
                        )
                        if not success:
                            saved_all = False
                    if saved_all:
                        print("     Successfully saved to database.")
            else:
                print("  -> No real price found. Skipping (keeping existing price).")
                
            if idx < len(ingredients) - 1:
                time.sleep(args.delay)
                
        browser.close()
        
    if not args.dry_run:
        print("\nRecalculating recipe costs for all countries...")
        for country in conversion_rates.keys():
            trigger_recipe_recalc(country)
                
    print("\n[SUCCESS] Scraper process finished successfully!")

if __name__ == "__main__":
    main()
