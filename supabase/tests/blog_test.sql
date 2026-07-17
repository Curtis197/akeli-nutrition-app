-- =============================================================================
-- pgTAP Test: Creator Blog v2
-- Verifies:
--   1. Schema: Tables and columns exist as expected.
--   2. Constraints: check constraints (chk_like_single_identity, chk_comment_single_identity).
--   3. Triggers: comment_count and like_count increments/decrements.
--   4. RLS policies: read/write restrictions for anonymous, authenticated, and creators.
-- =============================================================================

BEGIN;

SELECT plan(34);

-- ─── 1. Schema Assertions ────────────────────────────────────────────────────

SELECT has_table('blog_post');
SELECT has_table('blog_post_translation');
SELECT has_table('blog_post_like');
SELECT has_table('blog_comment');

SELECT has_column('blog_post', 'id');
SELECT has_column('blog_post', 'creator_id');
SELECT has_column('blog_post', 'is_published');
SELECT has_column('blog_post', 'like_count');
SELECT has_column('blog_post', 'comment_count');

SELECT has_column('blog_comment', 'post_id');
SELECT has_column('blog_comment', 'parent_id');
SELECT has_column('blog_comment', 'user_id');
SELECT has_column('blog_comment', 'visitor_id');
SELECT has_column('blog_comment', 'content');

-- ─── 2. Seed Reference Data ──────────────────────────────────────────────────

-- User & Creator setup
INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES 
  ('11111111-1111-1111-1111-111111111111'::uuid, 'creator@test.local', 'authenticated', now(), now()),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'regular@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name)
VALUES 
  ('11111111-1111-1111-1111-111111111111'::uuid, 'CreatorUser'),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'RegularUser')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.creator (id, user_id, display_name, username)
VALUES ('77777777-7777-7777-7777-777777777777'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, 'Chef Creator', 'chef_creator')
ON CONFLICT (id) DO NOTHING;

-- Visitor setup
INSERT INTO public.visitor (id, email, password_hash, first_name)
VALUES ('88888888-8888-8888-8888-888888888888'::uuid, 'visitor@test.local', 'mock_hash', 'VisitorUser')
ON CONFLICT (id) DO NOTHING;

-- Core Blog Post setup
INSERT INTO public.blog_post (id, creator_id, slug, visibility, is_published)
VALUES ('99999999-9999-9999-9999-999999999999'::uuid, '77777777-7777-7777-7777-777777777777'::uuid, 'my-test-post', 'public', true);

INSERT INTO public.blog_post_translation (post_id, locale, title, content_json)
VALUES ('99999999-9999-9999-9999-999999999999'::uuid, 'fr', 'Mon Article de Test', '{"body": "Contenu de test"}'::jsonb);

-- ─── 3. Constraint Assertions ───────────────────────────────────────────────

-- chk_comment_single_identity: cannot have both user_id and visitor_id
SELECT throws_ok(
  $$ INSERT INTO public.blog_comment (post_id, user_id, visitor_id, content)
     VALUES ('99999999-9999-9999-9999-999999999999'::uuid, 
             '22222222-2222-2222-2222-222222222222'::uuid, 
             '88888888-8888-8888-8888-888888888888'::uuid, 
             'This comment violates constraint') $$,
  'new row for relation "blog_comment" violates check constraint "chk_comment_single_identity"',
  'chk_comment_single_identity blocks dual identity comment'
);

-- chk_comment_single_identity: cannot have both user_id and visitor_id as NULL
SELECT throws_ok(
  $$ INSERT INTO public.blog_comment (post_id, user_id, visitor_id, content)
     VALUES ('99999999-9999-9999-9999-999999999999'::uuid, NULL, NULL, 'This comment violates constraint') $$,
  'new row for relation "blog_comment" violates check constraint "chk_comment_single_identity"',
  'chk_comment_single_identity blocks null identity comment'
);

-- chk_like_single_identity: cannot have both user_id and visitor_id
SELECT throws_ok(
  $$ INSERT INTO public.blog_post_like (post_id, user_id, visitor_id)
     VALUES ('99999999-9999-9999-9999-999999999999'::uuid, 
             '22222222-2222-2222-2222-222222222222'::uuid, 
             '88888888-8888-8888-8888-888888888888'::uuid) $$,
  'new row for relation "blog_post_like" violates check constraint "chk_like_single_identity"',
  'chk_like_single_identity blocks dual identity like'
);

-- ─── 4. Trigger Assertions ───────────────────────────────────────────────────

-- Comment count trigger tests
-- Initial state: comment_count should be 0
SELECT is(
  (SELECT comment_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  0,
  'comment_count starts at 0'
);

-- Insert a top-level comment (parent_id IS NULL)
INSERT INTO public.blog_comment (id, post_id, parent_id, user_id, visitor_id, content)
VALUES ('55555555-5555-5555-5555-555555555555'::uuid, '99999999-9999-9999-9999-999999999999'::uuid, NULL, '22222222-2222-2222-2222-222222222222'::uuid, NULL, 'Great post!');

SELECT is(
  (SELECT comment_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  1,
  'comment_count increments on top-level comment insert'
);

-- Insert a reply comment (parent_id IS NOT NULL) - should not increment count
INSERT INTO public.blog_comment (id, post_id, parent_id, user_id, visitor_id, content)
VALUES ('66666666-6666-6666-6666-666666666666'::uuid, '99999999-9999-9999-9999-999999999999'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, NULL, 'Thanks!');

SELECT is(
  (SELECT comment_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  1,
  'comment_count does not increment on reply comment insert'
);

-- Delete reply comment
DELETE FROM public.blog_comment WHERE id = '66666666-6666-6666-6666-666666666666'::uuid;

SELECT is(
  (SELECT comment_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  1,
  'comment_count remains stable when deleting replies'
);

-- Delete top-level comment
DELETE FROM public.blog_comment WHERE id = '55555555-5555-5555-5555-555555555555'::uuid;

SELECT is(
  (SELECT comment_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  0,
  'comment_count decrements back to 0 on top-level comment deletion'
);

-- Like count trigger tests
-- Initial state: like_count should be 0
SELECT is(
  (SELECT like_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  0,
  'like_count starts at 0'
);

-- Insert a post like
INSERT INTO public.blog_post_like (id, post_id, user_id, visitor_id)
VALUES ('44444444-4444-4444-4444-444444444444'::uuid, '99999999-9999-9999-9999-999999999999'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, NULL);

SELECT is(
  (SELECT like_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  1,
  'like_count increments on like insert'
);

-- Delete the like
DELETE FROM public.blog_post_like WHERE id = '44444444-4444-4444-4444-444444444444'::uuid;

SELECT is(
  (SELECT like_count FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  0,
  'like_count decrements back to 0 on like deletion'
);

-- ─── 5. RLS Policies Assertions ───────────────────────────────────────────────

-- Create another draft post (unpublished)
INSERT INTO public.blog_post (id, creator_id, slug, visibility, is_published)
VALUES ('33333333-3333-3333-3333-333333333333'::uuid, '77777777-7777-7777-7777-777777777777'::uuid, 'my-draft-post', 'public', false);

-- A. Anonymous RLS tests
SET LOCAL request.jwt.claims = '{}';
SET LOCAL ROLE anon;

-- Can select published public post
SELECT is(
  (SELECT slug FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  'my-test-post',
  'anon can select published public blog post'
);

-- Cannot select draft post
SELECT is(
  (SELECT count(*)::int FROM public.blog_post WHERE id = '33333333-3333-3333-3333-333333333333'::uuid),
  0,
  'anon cannot select draft/unpublished blog post'
);

-- Can select translation for published public post
SELECT is(
  (SELECT title FROM public.blog_post_translation WHERE post_id = '99999999-9999-9999-9999-999999999999'::uuid LIMIT 1),
  'Mon Article de Test',
  'anon can select published translations'
);

-- B. Authenticated User RLS tests (non-owner)
SET LOCAL request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222"}';
SET LOCAL ROLE authenticated;

-- Can select published public post
SELECT is(
  (SELECT slug FROM public.blog_post WHERE id = '99999999-9999-9999-9999-999999999999'::uuid),
  'my-test-post',
  'authenticated user can select published public blog post'
);

-- Cannot select draft post
SELECT is(
  (SELECT count(*)::int FROM public.blog_post WHERE id = '33333333-3333-3333-3333-333333333333'::uuid),
  0,
  'authenticated user cannot select draft/unpublished blog post'
);

-- Can manage own likes
SELECT lives_ok(
  $$ INSERT INTO public.blog_post_like (post_id, user_id, visitor_id)
     VALUES ('99999999-9999-9999-9999-999999999999'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, NULL) $$,
  'authenticated user can like a post'
);

-- Cannot like as someone else
SELECT throws_ok(
  $$ INSERT INTO public.blog_post_like (post_id, user_id, visitor_id)
     VALUES ('99999999-9999-9999-9999-999999999999'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, NULL) $$,
  'new row violates row-level security policy for table "blog_post_like"',
  'RLS prevents user liking as another user'
);

-- C. Creator Owner RLS tests
SET LOCAL request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111"}';
SET LOCAL ROLE authenticated;

-- Creator can see draft post
SELECT is(
  (SELECT slug FROM public.blog_post WHERE id = '33333333-3333-3333-3333-333333333333'::uuid),
  'my-draft-post',
  'creator can see own draft post'
);

-- Creator can insert new post
SELECT lives_ok(
  $$ INSERT INTO public.blog_post (id, creator_id, slug, visibility, is_published)
     VALUES ('12121212-1212-1212-1212-121212121212'::uuid, '77777777-7777-7777-7777-777777777777'::uuid, 'new-post', 'public', false) $$,
  'creator can insert own blog post'
);

RESET ROLE;

SELECT * FROM finish();

ROLLBACK;
