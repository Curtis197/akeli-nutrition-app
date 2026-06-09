const fs = require('fs');
let content = fs.readFileSync('supabase/seed.sql', 'utf8');

content = content.replace(/\\\\"rof\\\\"/g, '\\"rof\\"');
content = content.replace(/\\\\"takliya\\\\"/g, '\\"takliya\\"');

// Also just in case there are others
content = content.replace(/\\\\"/g, '\\"');

fs.writeFileSync('supabase/seed.sql', content, 'utf8');
console.log('Fixed seed.sql');
