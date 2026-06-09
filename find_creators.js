const fs = require('fs');
const content = fs.readFileSync('supabase/seed.sql', 'utf8');

// The SQL insert format:
// ('UUID', 'CREATOR_ID', ... )
const matches = content.matchAll(/\('[a-f0-9\-]{36}',\s*'([a-f0-9\-]{36})'/g);

const creators = new Set();
for (const match of matches) {
  creators.add(match[1]);
}

console.log("Distinct creators found:", Array.from(creators));
