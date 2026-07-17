# Creator Blog v2 Phase 1: Schema & Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the Creator Blog v2 database schema and backend logic. We will commit and apply the schema reconciliation migrations locally, write pgTAP tests to verify the RLS policies, constraints, and trigger-based aggregations (like and comment counts) for the blog, verify the remote production schema, and ensure everything is fully aligned between local dev and remote prod.

**Architecture:** 
1. **Reconciliation Migrations:** Apply local-only migration scripts to align the local dev database schema with the live production database (`njzqcftjzskwcpforwzf`). Production already contains the creator-blog schema.
2. **Creator Blog Tables:** 
   - `blog_post`: Core blog post metadata (creator, slug, visibility, counts, publish flags).
   - `blog_post_translation`: Multi-language localization entries (locale, title, JSONB body content).
   - `blog_post_like`: Post likes supporting both authenticated profiles and anonymous visitors.
   - `blog_comment`: Comments supporting replies (threaded hierarchy via `parent_id`) and single identity constraints.
   - `creator_follow` / `visitor_creator_follow`: Follow relations for creators.
3. **Triggers:** Automated increment/decrement triggers for `blog_post.like_count` and `blog_post.comment_count` on insertions and deletions.
4. **RLS Policies:** Lock down access so only authorized users can view drafts or specialized visibility posts, and only owners/creators can modify their posts and comments.

**Tech Stack:** Supabase Postgres 17 (project `njzqcftjzskwcpforwzf` "Akeli V1"), pgTAP, CLI db tools.

---

## Global Constraints

- **Local migrations repair/apply:** Commit the untracked migrations `20260717053537_reconcile_local_with_prod_schema.sql`, `20260717055452_reconcile_local_with_prod_schema_2.sql`, and `20260717061116_fix_generate_meal_plan_kcal_column_name.sql` to resolve local dev schema drift.
- **Do not apply reconciliation migrations to production:** The production database already has this schema. This is local-only schema sync.
- **Remote verification:** Verify the tables, constraints, and policies against the remote project using the `execute_sql` tool on Supabase.
- **Test execution:** pgTAP tests must run and pass locally via: `supabase db reset; supabase test db`.

---

### Task 1: Schema Reconciliation & Local Verification

**Files:**
- Modify (Commit): `supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql`
- Modify (Commit): `supabase/migrations/20260717055452_reconcile_local_with_prod_schema_2.sql`
- Modify (Commit): `supabase/migrations/20260717061116_fix_generate_meal_plan_kcal_column_name.sql`

**Interfaces:**
- Produces: Local DB matches production schema precisely.
- Enables: Writing blog tests locally that compile and execute against the real tables.

- [ ] **Step 1: Check git status to confirm reconciliation migrations are present**
  Run: `git status`
  Verify that the three files are present in `supabase/migrations/` as untracked files.

- [ ] **Step 2: Run local DB reset to apply all migrations**
  Run (PowerShell): `supabase db reset`
  Expected: Migrations apply cleanly.

- [ ] **Step 3: Run existing test suite to ensure no regressions**
  Run: `supabase test db`
  Expected: All existing database tests pass.

- [ ] **Step 4: Stage and commit the reconciliation migrations**
  Run:
  ```bash
  git add supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql
  git add supabase/migrations/20260717055452_reconcile_local_with_prod_schema_2.sql
  git add supabase/migrations/20260717061116_fix_generate_meal_plan_kcal_column_name.sql
  git commit -m "feat(db): align local schema with production via reconciliation migrations"
  ```

---

### Task 2: Implement pgTAP database tests for Blog V2

**Files:**
- Create: `supabase/tests/blog_test.sql`

**Interfaces:**
- Produces: Automated test suite for the blog schema, triggers, constraints, and RLS policies.

- [ ] **Step 1: Write pgTAP test script**
  Create `supabase/tests/blog_test.sql` to verify:
  1. Tables exist and have expected columns.
  2. Constraints are active (e.g., `chk_like_single_identity` and `chk_comment_single_identity`).
  3. Trigger functions update counts correctly:
     - Inserting `blog_comment` increments `blog_post.comment_count`.
     - Deleting `blog_comment` decrements `blog_post.comment_count`.
     - Inserting `blog_post_like` increments `blog_post.like_count`.
     - Deleting `blog_post_like` decrements `blog_post.like_count`.
  4. RLS policies behavior:
     - Public/Anonymous users can SELECT published public posts and translations.
     - Public/Anonymous users cannot INSERT, UPDATE, or DELETE posts.
     - Creators can INSERT their own posts, and UPDATE/DELETE them.
     - Users can SELECT comments on public posts.
     - Users can INSERT/UPDATE/DELETE their own comments/likes.

- [ ] **Step 2: Run tests locally**
  Run: `supabase test db`
  Verify that the new `blog_test.sql` runs and all assertions pass.

- [ ] **Step 3: Stage and commit the test script**
  Run:
  ```bash
  git add supabase/tests/blog_test.sql
  git commit -m "test(db): add pgTAP tests for blog schema, triggers, and RLS policies"
  ```

---

### Task 3: Remote Production Verification

**Interfaces:**
- Verify that the schema is already active on the remote production database and has no drifts.

- [ ] **Step 1: Verify tables exist on production**
  Execute read-only check on prod via `execute_sql` (remote):
  ```sql
  SELECT table_name 
  FROM information_schema.tables 
  WHERE table_schema = 'public' 
    AND table_name IN ('blog_post', 'blog_post_translation', 'blog_post_like', 'blog_comment', 'creator_follow', 'visitor_creator_follow');
  ```
  Expected: All 6 tables are returned.

- [ ] **Step 2: Verify RLS policies on production**
  Execute policy check on prod via `execute_sql` (remote):
  ```sql
  SELECT tablename, policyname, cmd, permissive, roles, qual, with_check 
  FROM pg_policies 
  WHERE tablename IN ('blog_post', 'blog_post_translation', 'blog_post_like', 'blog_comment');
  ```
  Expected: The RLS policies exist and match the local reconciliation definitions.

- [ ] **Step 3: Verify trigger functions on production**
  Execute trigger function check on prod via `execute_sql` (remote):
  ```sql
  SELECT proname, prosrc 
  FROM pg_proc 
  WHERE proname IN ('update_blog_comment_count', 'update_blog_like_count');
  ```
  Expected: Both trigger functions are active on production.

- [ ] **Step 4: Verify constraints on production**
  Execute constraint check on prod via `execute_sql` (remote):
  ```sql
  SELECT conname, contype, consrc 
  FROM pg_constraint 
  WHERE conname IN ('chk_like_single_identity', 'chk_comment_single_identity');
  ```
  Expected: Both check constraints are active on production.
