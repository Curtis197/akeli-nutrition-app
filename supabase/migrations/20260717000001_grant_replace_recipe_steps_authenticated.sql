-- Hotfix: replace_recipe_steps had no EXECUTE grant for `authenticated`.
-- v1 (landing repo) locked it to service_role only. v2 (20260716220000, this repo)
-- added an in-body ownership check specifically so the creator-facing wizard could
-- call it directly as `authenticated`, but CREATE OR REPLACE FUNCTION preserves the
-- existing ACL — the grant was never added. Result: every creator's Publish action
-- (which calls this RPC via the browser Supabase client, running as `authenticated`)
-- has been failing with 42501 permission denied since v2 was deployed.
--
-- Safe to grant broadly now: the function's own ownership check (added in v2) gates
-- per-call authorization, so this doesn't reopen the IDOR v1's ACL was preventing.

GRANT EXECUTE ON FUNCTION public.replace_recipe_steps(uuid, jsonb) TO authenticated;
