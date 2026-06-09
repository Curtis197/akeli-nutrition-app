const SUPABASE_URL = 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_KEY = 'YOUR_SUPABASE_SERVICE_KEY'; // From the local setup output

async function run() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/generate_meal_plan`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
    },
    body: JSON.stringify({
      p_user_id: 'f1414791-8f57-4bf4-a730-42f3c89dad95',
      p_days: 1,
      p_meals_per_day: 3,
      p_start_date: '2026-05-24'
    })
  });

  const text = await res.text();
  console.log("Status:", res.status);
  
  if (res.ok) {
    const data = JSON.parse(text);
    console.log("Returned entries:", data.length);
    for (const entry of data) {
      console.log(`Meal Type: ${entry.meal_type}, Recipe ID: ${entry.recipe_id}`);
    }
  } else {
    console.error("Error:", text);
  }
}

run().catch(console.error);
