import os, json, urllib.parse, urllib.request
from datetime import datetime
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()
load_dotenv('../.env')

DATABASE_URL            = os.getenv("DATABASE_URL", "")
SUPABASE_URL            = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY       = os.getenv("SUPABASE_ANON_KEY", "")

def _headers(use_service_key=True):
    key = SUPABASE_SERVICE_ROLE_KEY if use_service_key else SUPABASE_ANON_KEY
    return {'apikey': key, 'Authorization': f'Bearer {key}', 'Content-Type': 'application/json'}

def get_ingredients(limit=None, name_filter=None):
    if DATABASE_URL:
        try:
            q = "SELECT id, name, name_fr, name_en, category FROM ingredient"
            params = []
            if name_filter:
                q += " WHERE name ILIKE %s OR name_fr ILIKE %s OR name_en ILIKE %s"
                params.extend([f"%{name_filter}%"] * 3)
            q += " ORDER BY name ASC"
            if limit:
                q += " LIMIT %s"; params.append(limit)
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute(q, params)
                    return cur.fetchall()
        except Exception as e:
            print(f"Postgres failed: {e}. Trying REST...")
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        print("Error: No DB credentials available (DATABASE_URL or SUPABASE_URL+SUPABASE_ANON_KEY required).")
        return []
    url = (f"{SUPABASE_URL}/rest/v1/ingredient"
           f"?select=id,name,name_fr,name_en,category&order=name.asc")
    if name_filter:
        esc = urllib.parse.quote(f"*{name_filter}*")
        url += f"&or=(name.ilike.{esc},name_fr.ilike.{esc},name_en.ilike.{esc})"
    if limit:
        url += f"&limit={limit}"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=_headers(False))) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        print(f"Error fetching ingredients via REST API: {e}")
        return []

def save_market_price(ing_id, country, currency, price_per_100g,
                      package_size, package_unit, source='multi_scraper_v2'):
    if DATABASE_URL:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO ingredient_market_price
                            (ingredient_id,country_code,currency,price_per_100g,
                             package_size,package_unit,source,scraped_at)
                        VALUES (%s,%s,%s,%s,%s,%s,%s,NOW())
                        ON CONFLICT (ingredient_id,country_code) DO UPDATE
                        SET price_per_100g=EXCLUDED.price_per_100g,
                            package_size=EXCLUDED.package_size,
                            package_unit=EXCLUDED.package_unit,
                            source=EXCLUDED.source,
                            scraped_at=EXCLUDED.scraped_at
                    """, (ing_id,country,currency,price_per_100g,
                          package_size,package_unit,source))
                    conn.commit()
            return True
        except Exception as e:
            print(f"  Postgres save failed: {e}")
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("  No REST credentials — save skipped.")
        return False
    hdrs = _headers(); hdrs['Prefer'] = 'resolution=merge-duplicates'
    payload = json.dumps({
        'ingredient_id': ing_id, 'country_code': country, 'currency': currency,
        'price_per_100g': price_per_100g, 'package_size': package_size,
        'package_unit': package_unit, 'source': source,
        'scraped_at': datetime.utcnow().isoformat()
    }).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(
                f"{SUPABASE_URL}/rest/v1/ingredient_market_price",
                headers=hdrs, data=payload, method='POST')):
            return True
    except Exception as e:
        print(f"  REST save failed: {e}")
        return False

def trigger_recipe_recalc(country_code):
    if DATABASE_URL:
        try:
            with psycopg2.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT recalculate_recipe_costs(%s)", (country_code,))
                    conn.commit()
            print(f"  Recalculation done: {country_code}")
            return True
        except Exception as e:
            print(f"  RPC failed: {e}")
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("  No REST credentials — recalc skipped.")
        return False
    payload = json.dumps({'p_country_code': country_code}).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(
                f"{SUPABASE_URL}/rest/v1/rpc/recalculate_recipe_costs",
                headers=_headers(), data=payload, method='POST')):
            print(f"  Recalculation done: {country_code} (REST)")
        return True
    except Exception as e:
        print(f"  REST recalc failed: {e}")
        return False
