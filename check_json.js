const fs = require('fs');
const content = fs.readFileSync('supabase/seed.sql', 'utf8');

// Find everything that looks like a draft_data json blob.
// It starts with '{"tags": and ends with }'
const matches = content.match(/'\{"tags":.*?\}'/g);

if (!matches) {
  console.log("No matches found!");
  process.exit(0);
}

let failed = 0;
for (let i = 0; i < matches.length; i++) {
  let str = matches[i].substring(1, matches[i].length - 1); // remove outer single quotes
  // in SQL, single quotes inside strings are escaped as ''. We need to convert them back to '
  str = str.replace(/''/g, "'");
  try {
    JSON.parse(str);
  } catch (e) {
    console.log(`Failed to parse JSON at index ${i}: ${e.message}`);
    const posMatch = e.message.match(/position (\d+)/);
    if (posMatch) {
      const pos = parseInt(posMatch[1], 10);
      console.log(`Context: ${str.substring(Math.max(0, pos - 30), pos)} ---> ${str[pos]} <--- ${str.substring(pos + 1, pos + 30)}`);
    }
    failed++;
  }
}
console.log(`Checked ${matches.length} json blobs. ${failed} failed.`);
