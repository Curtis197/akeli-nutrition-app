const SUPABASE_URL = 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_KEY = 'YOUR_SUPABASE_SERVICE_KEY'; 

async function run() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/recipe?select=id,title,meal_types,is_published`, {
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
    }
  });

  const data = await res.json();
  console.log("Total recipes:", data.length);
  for (let i = 0; i < Math.min(10, data.length); i++) {
    console.log(data[i].title, "| meal_types:", data[i].meal_types, "| is_published:", data[i].is_published);
  }
}

run().catch(console.error);
