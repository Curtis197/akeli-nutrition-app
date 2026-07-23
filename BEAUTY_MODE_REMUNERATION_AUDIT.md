# Beauty Mode Remuneration & Database Audit

> Rewritten 2026-07-23 to describe the system as actually shipped. The
> previous version of this document described an abandoned tokenized
> pool/fan-allocation model (`beauty_care_logs`, `fan_allocations`,
> migration `20240103000001_fix_beauty_remuneration_and_fan_mode.sql`) that
> was never the live implementation and does not match any migration
> filename that has ever existed in this repository. See
> `docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`
> for the audit that surfaced this discrepancy and the fixes applied
> alongside this rewrite.

## Shipped model: `revenue_value = 1 / N` proportional plan-slot payout

- **Migrations:** `supabase/migrations/20260721000012_beauty_plan_slot_revenue_value.sql`
  (adds `beauty_plan_slot.revenue_value`, computed by `generate_beauty_plan`
  as `1 / total_slots_in_plan` once a plan is generated) and
  `supabase/migrations/20260721000013_beauty_payouts_revenue_value.sql`
  (creator payout aggregation).
- **Mechanism:** every slot in a user's monthly beauty plan is worth an
  equal fraction (`1 / N`) of a fixed 1.00€ (100 cents) creator pool per
  plan. When the user marks a slot `is_completed = true`, that slot's
  `revenue_value` counts toward its recipe's creator.
- **Aggregation:** `calculate_creator_payouts(target_month, plan_revenue_cents)`
  sums `revenue_value` across all completed slots for each creator in a
  given month, converts the sum to cents (`ROUND(points * plan_revenue_cents)`),
  and upserts the result into `creator_monthly_payouts.pool_earnings_cents`.
- **Reporting RPCs:** `get_creator_beauty_revenue_share` and
  `get_creator_beauty_payout_breakdown` recompute the same points/cents math
  on demand for a single creator (dashboard display); both are now
  authorization-gated to the creator's own `auth.uid()`
  (see `docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`,
  Task 3). `get_platform_retained_beauty_revenue` computes the
  platform-retained remainder across all plans for a month and is now
  restricted to `service_role` only (same plan, Task 3).

## Fan-mode revenue is NOT computed by the beauty payout engine

Earlier drafts of `calculate_creator_payouts` additionally counted active
`fan_subscription` rows into a `fan_earnings_cents` column. This was removed
(`docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`, Task 2):
Nutrition's existing `supabase/functions/compute-monthly-revenue` edge
function already recognizes every active `fan_subscription` row as revenue
into `creator_balance.balance`, once per creator per month. Counting the
same rows again in the beauty payout engine would double-count the same
euro. Fan-mode revenue for creators — beauty or nutrition — is
authoritatively tracked by `compute-monthly-revenue` /
`creator_balance` / `creator_revenue_log` only.
`creator_monthly_payouts.fan_earnings_cents` remains in the schema for
backward compatibility but is never written by `calculate_creator_payouts`
and should be treated as always `0`.

## Automation

`calculate_creator_payouts` is invoked monthly by the
`compute-monthly-beauty-revenue` edge function (mirrors
`compute-monthly-revenue`'s internal-secret-gated cron pattern), registered
via `supabase/migrations/20260722110300_register_compute_monthly_beauty_revenue_cron.sql`.
Before this, the function existed in the schema but was never called by
anything in production
(`docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`, Task 4).

## Known out-of-scope legacy artifacts

`supabase/migrations/20260521000003_fix_beauty_remuneration_and_fan_mode.sql`
created an earlier, abandoned schema (`beauty_plans`,
`user_beauty_subscriptions`, `fan_allocations`, `beauty_care_logs`) and a
now-dropped 1-arg `calculate_creator_payouts(date)` overload (dropped by
`20260722110400_drop_legacy_calculate_creator_payouts_overload.sql`). Those
dead tables are confirmed unreferenced anywhere in `lib/` or
`supabase/functions/` and are left in place, untouched, as an accepted
cleanup item for a future migration — dropping them is out of scope for
this document's audit and for the 2026-07-23 fix plan.
