const fs = require('fs');

let content = fs.readFileSync('supabase/seed.sql', 'utf8');

// The block I added was at the top. The actual seed data starts with:
const firstRecipeInsertIdx = content.indexOf('INSERT INTO "public"."recipe"');
if (firstRecipeInsertIdx !== -1) {
  content = content.substring(firstRecipeInsertIdx);
}
fs.writeFileSync('supabase/seed.sql', content, 'utf8');
console.log('Stripped users from seed.sql');
