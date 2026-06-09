const fs = require('fs');

const usersSql = `
-- Create users needed for foreign key constraints
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
VALUES 
('00000000-0000-0000-0000-000000000000', '1a1b225a-1328-4d58-976f-253574410c6f', 'authenticated', 'authenticated', 'user1@example.com', crypt('password', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'f1414791-8f57-4bf4-a730-42f3c89dad95', 'authenticated', 'authenticated', 'test@client.com', crypt('jehojada', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
ON CONFLICT DO NOTHING;

INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
VALUES
('1a1b225a-1328-4d58-976f-253574410c6f', '1a1b225a-1328-4d58-976f-253574410c6f', '1a1b225a-1328-4d58-976f-253574410c6f', format('{"sub":"%s","email":"%s"}', '1a1b225a-1328-4d58-976f-253574410c6f', 'user1@example.com')::jsonb, 'email', now(), now(), now()),
('f1414791-8f57-4bf4-a730-42f3c89dad95', 'f1414791-8f57-4bf4-a730-42f3c89dad95', 'f1414791-8f57-4bf4-a730-42f3c89dad95', format('{"sub":"%s","email":"%s"}', 'f1414791-8f57-4bf4-a730-42f3c89dad95', 'test@client.com')::jsonb, 'email', now(), now(), now())
ON CONFLICT DO NOTHING;

INSERT INTO public.user_profile (id, username, updated_at)
VALUES 
('1a1b225a-1328-4d58-976f-253574410c6f', 'user1', now()),
('f1414791-8f57-4bf4-a730-42f3c89dad95', 'testuser', now())
ON CONFLICT DO NOTHING;

`;

let content = fs.readFileSync('supabase/seed.sql', 'utf8');
// Remove everything up to the first actual insert of seed data or the old prepended users
content = content.replace(/^.*?(?=INSERT INTO)/s, '');

// If it starts with my old injected SQL, remove it
const firstInsertIdx = content.indexOf('INSERT INTO auth.users');
const firstRecipeInsertIdx = content.indexOf('INSERT INTO "public"."recipe"');

if (firstInsertIdx !== -1 && firstInsertIdx < firstRecipeInsertIdx) {
  content = content.substring(firstRecipeInsertIdx);
}

fs.writeFileSync('supabase/seed.sql', usersSql + content, 'utf8');
console.log('Fixed provider_id in seed.sql');
