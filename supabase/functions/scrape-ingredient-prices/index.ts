import { createClient } from 'jsr:@supabase/supabase-js@2';
import { createLogger } from '../_shared/logger.ts';

function timingSafeEqual(a: string, b: string): boolean {
  const aBytes = new TextEncoder().encode(a);
  const bBytes = new TextEncoder().encode(b);
  if (aBytes.length !== bBytes.length) return false;
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) diff |= aBytes[i] ^ bBytes[i];
  return diff === 0;
}

// --- REAL SCRAPING LOGIC GOES HERE LATER ---
function getBasePriceEUR(name: string, category: string | null): number {
  const n = (name || '').toLowerCase();
  if (n.includes('rice') || n.includes('riz')) return 0.20;
  if (n.includes('chicken') || n.includes('poulet')) return 0.85;
  if (n.includes('beef') || n.includes('boeuf')) return 1.40;
  if (n.includes('fish') || n.includes('poisson') || n.includes('mackerel')) return 0.90;
  if (n.includes('plantain')) return 0.30;
  if (n.includes('egusi') || n.includes('melon')) return 2.50;
  if (n.includes('palm oil') || n.includes('huile')) return 0.60;
  if (n.includes('tomato') || n.includes('tomate')) return 0.25;
  if (n.includes('onion') || n.includes('oignon')) return 0.15;
  if (n.includes('peanut') || n.includes('arachide')) return 1.20;
  if (n.includes('cassava') || n.includes('manioc')) return 0.20;
  if (n.includes('yam') || n.includes('igname')) return 0.25;
  if (n.includes('okra') || n.includes('gombo')) return 0.40;
  
  if (category === 'spice') return 3.00;
  if (category === 'vegetable') return 0.30;
  if (category === 'meat') return 1.20;
  return 0.50; // Generic fallback
}

function simulatePrice(ing: any, countryCode: string): { price: number, currency: string } {
  const base = getBasePriceEUR(ing.name, ing.category);
  switch (countryCode) {
    case 'FR': return { price: base, currency: 'EUR' };
    case 'GB': return { price: base * 0.85, currency: 'GBP' }; // UK diaspora markup
    case 'CA': return { price: base * 1.45, currency: 'CAD' }; // CAD conversion + markup
    case 'US': return { price: base * 1.25, currency: 'USD' }; // USD conversion + markup
    default: return { price: base, currency: 'EUR' };
  }
}
// -------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  const logger = createLogger('scrape-ingredient-prices');
  const start = Date.now();
  
  // 1. Auth check (Internal Secret for Cron Jobs)
  const secret = Deno.env.get('INTERNAL_SECRET');
  const authHeader = req.headers.get('Authorization');
  if (!secret || !authHeader || !timingSafeEqual(authHeader, `Bearer ${secret}`)) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const countries = ['FR', 'GB', 'CA', 'US'];
  
  // 2. Fetch all ingredients
  const { data: ingredients, error: fetchError } = await supabase
    .from('ingredient')
    .select('id, name, category');

  if (fetchError) {
    logger.error('Failed to fetch ingredients', { error: fetchError.message });
    return new Response(JSON.stringify({ error: fetchError.message }), { status: 500 });
  }

  // 3. Process each country
  for (const country of countries) {
    logger.info(`Processing country: ${country}`);
    const pricesToUpsert = [];
    
    for (const ing of ingredients) {
      const { price, currency } = simulatePrice(ing, country);
      
      pricesToUpsert.push({
        ingredient_id: ing.id,
        country_code: country,
        currency: currency,
        price_per_100g: price,
        source: 'simulation_v1',
        scraped_at: new Date().toISOString()
      });
    }

    // 4. Upsert prices in batches
    if (pricesToUpsert.length > 0) {
      const batchSize = 100;
      for (let i = 0; i < pricesToUpsert.length; i += batchSize) {
        const batch = pricesToUpsert.slice(i, i + batchSize);
        const { error: upsertError } = await supabase
          .from('ingredient_market_price')
          .upsert(batch, { onConflict: 'ingredient_id,country_code' });
          
        if (upsertError) {
          logger.error(`Upsert failed for ${country} batch ${i}`, { error: upsertError.message });
        }
      }
    }

    // 5. Trigger recipe cost recalculation for this country
    const { error: recalcError } = await supabase.rpc('recalculate_recipe_costs', {
      p_country_code: country
    });
    
    if (recalcError) {
      logger.error(`Recalc failed for ${country}`, { error: recalcError.message });
    } else {
      logger.info(`Successfully updated costs for ${country}`);
    }
  }

  logger.info(`✅ Scraper complete | duration: ${Date.now() - start}ms`);
  return new Response(JSON.stringify({ success: true, duration: Date.now() - start }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
});
