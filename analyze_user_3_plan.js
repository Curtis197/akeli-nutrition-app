const SUPABASE_URL = process.env.SUPABASE_URL || 'https://njzqcftjzskwcpforwzf.supabase.co';
const ANON_KEY = process.env.SUPABASE_ANON_KEY || 'sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R';
const EMAIL = process.env.TEST_EMAIL || 'test_3@client.com';
const PASS = process.env.TEST_PASS || (() => { throw new Error('Set TEST_PASS env var'); })();

let authToken = '';

async function login() {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { 'apikey': ANON_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASS })
  });
  const data = await res.json();
  if (data.access_token) authToken = data.access_token;
  return data.user?.id;
}

async function fetchDb(table, query) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
    headers: { 'apikey': ANON_KEY, 'Authorization': `Bearer ${authToken}` }
  });
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

async function analyze() {
  const userId = await login();
  if (!userId) {
    console.log('Login failed');
    return;
  }
  console.log(`User ID: ${userId}`);

  const profile = await fetchDb('health_profile', `user_id=eq.${userId}&select=*`);
  console.log(`\n--- HEALTH PROFILE ---`);
  console.log(JSON.stringify(profile, null, 2));

  const plans = await fetchDb('meal_plan', `user_id=eq.${userId}&is_active=eq.true&order=start_date.desc`);
  if (!Array.isArray(plans) || plans.length === 0) {
    console.log('No active meal plans found.');
    return;
  }

  for (const plan of plans) {
    console.log(`\n======================================================`);
    console.log(`MEAL PLAN: ${plan.id} | Dates: ${plan.start_date} to ${plan.end_date}`);
    console.log(`======================================================`);

    const dailyMeals = await fetchDb('daily_meal', `meal_plan_id=eq.${plan.id}&select=id,date,meal_type,recipe_id,recipe(title, calories, protein, carbs, fat, is_vegetarian, is_vegan, is_gluten_free)`);
    
    console.log(`\n--- DAILY MEALS (${dailyMeals?.length || 0}) ---`);
    if (Array.isArray(dailyMeals)) {
      dailyMeals.sort((a, b) => new Date(a.date) - new Date(b.date) || a.meal_type.localeCompare(b.meal_type));
      for (const m of dailyMeals) {
        console.log(`${m.date} [${m.meal_type}]: ${m.recipe?.title} (Cal: ${m.recipe?.calories}, P: ${m.recipe?.protein}, C: ${m.recipe?.carbs}, F: ${m.recipe?.fat}) [Veg: ${m.recipe?.is_vegetarian}, Vgn: ${m.recipe?.is_vegan}, GF: ${m.recipe?.is_gluten_free}]`);
      }
    }
  }
}

analyze();
