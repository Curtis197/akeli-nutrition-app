const SUPABASE_URL = 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_KEY = 'YOUR_SUPABASE_SERVICE_KEY'; 

async function run() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/user_health_profile`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
    },
    body: JSON.stringify({
      user_id: 'f1414791-8f57-4bf4-a730-42f3c89dad95',
      sex: 'male',
      birth_date: '1990-01-01',
      height_cm: 180,
      weight_kg: 80,
      target_weight_kg: 75,
      activity_level: 'moderate'
    })
  });

  if (res.ok) {
    console.log("Health profile inserted!");
  } else {
    console.error("Failed to insert health profile:", await res.text());
  }
}

run().catch(console.error);
