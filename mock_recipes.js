const SUPABASE_URL = 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_KEY = 'YOUR_SUPABASE_SERVICE_KEY'; 

async function run() {
  const recipes = [
    {
      title: 'Mock Breakfast',
      description: 'A mock breakfast',
      creator_id: 'f1414791-8f57-4bf4-a730-42f3c89dad95',
      meal_types: ['breakfast'],
      is_published: true,
      servings: 1
    },
    {
      title: 'Mock Lunch',
      description: 'A mock lunch',
      creator_id: 'f1414791-8f57-4bf4-a730-42f3c89dad95',
      meal_types: ['lunch'],
      is_published: true,
      servings: 1
    },
    {
      title: 'Mock Dinner',
      description: 'A mock dinner',
      creator_id: 'f1414791-8f57-4bf4-a730-42f3c89dad95',
      meal_types: ['dinner'],
      is_published: true,
      servings: 1
    }
  ];

  const res = await fetch(`${SUPABASE_URL}/rest/v1/recipe`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
    },
    body: JSON.stringify(recipes)
  });

  if (res.ok) {
    console.log("Mock recipes inserted!");
  } else {
    console.error("Failed to insert mock recipes:", await res.text());
  }
}

run().catch(console.error);
