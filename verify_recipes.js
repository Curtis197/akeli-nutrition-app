const SUPABASE_URL = 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_KEY = 'YOUR_SUPABASE_SERVICE_KEY'; 

async function run() {
  const ids = [
    '3c7d31a5-86f9-4532-8faf-5f925d2b3152',
    '3ae9521a-c453-4e75-851a-57edfb3b5171',
    'd854b43c-c06c-40d8-b5e0-e793b1ce7ac6'
  ];
  const res = await fetch(`${SUPABASE_URL}/rest/v1/recipe?id=in.(${ids.join(',')})&select=id,title,meal_types`, {
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
    }
  });

  const data = await res.json();
  for (const recipe of data) {
    console.log(`Recipe ID: ${recipe.id}, Title: ${recipe.title}, Meal Types: ${recipe.meal_types}`);
  }
}

run().catch(console.error);
