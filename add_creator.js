const fs = require('fs');
let content = fs.readFileSync('supabase/seed.sql', 'utf8');

const usersSql = `
-- Create creators needed for foreign key constraints
INSERT INTO public.creator (id, recipe_count)
VALUES 
('1a1b225a-1328-4d58-976f-253574410c6f', 0),
('f1414791-8f57-4bf4-a730-42f3c89dad95', 0)
ON CONFLICT DO NOTHING;

`;

// Insert the creator inserts right after the user_profile inserts
const userProfileIdx = content.indexOf('INSERT INTO public.user_profile');
const userProfileEndIdx = content.indexOf(';', userProfileIdx) + 1;

content = content.substring(0, userProfileEndIdx) + '\n' + usersSql + content.substring(userProfileEndIdx);

fs.writeFileSync('supabase/seed.sql', content, 'utf8');
console.log('Added creator insert to seed.sql');
