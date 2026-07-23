-- supabase/tests/calculate_creator_payouts_overload_test.sql
-- Finding #5 (Area C, High): calculate_creator_payouts has 2 coexisting
-- overloads — a stale 1-arg version (20260521000003) operating on dead
-- tables (beauty_care_logs, fan_allocations — confirmed unreferenced
-- anywhere in lib/ or supabase/functions/ via grep), and the real 2-arg
-- version (20260721000013, fixed in this plan's Task 2). Two overloads of
-- the same name is exactly the shape that produces PostgREST's PGRST203
-- "could not choose the best candidate function" ambiguity error.
BEGIN;
SELECT plan(3);

SELECT hasnt_function(
  'public', 'calculate_creator_payouts', ARRAY['date'],
  'legacy 1-arg calculate_creator_payouts(date) overload is dropped'
);

SELECT has_function(
  'public', 'calculate_creator_payouts', ARRAY['date','integer'],
  'calculate_creator_payouts(date, integer) 2-arg overload remains'
);

SELECT is(
  (SELECT count(*)::int FROM pg_proc WHERE proname = 'calculate_creator_payouts'),
  1,
  'exactly one calculate_creator_payouts overload exists (no PostgREST ambiguity risk)'
);

SELECT * FROM finish();
ROLLBACK;
