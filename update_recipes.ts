import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = 'http://127.0.0.1:54321';
const supabaseKey = 'YOUR_SUPABASE_SERVICE_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function update() {
  const { error } = await supabase
    .from('recipe')
    .update({ meal_types: ['breakfast', 'lunch', 'dinner', 'snack'] })
    .neq('id', '00000000-0000-0000-0000-000000000000'); // dummy filter to update all
  
  if (error) {
    console.error('Error updating recipes:', error);
  } else {
    console.log('Successfully updated all recipes to have meal_types!');
  }
}

update();
