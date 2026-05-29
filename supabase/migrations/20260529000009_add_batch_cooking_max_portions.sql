-- supabase/migrations/20260529000009_add_batch_cooking_max_portions.sql
ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS batch_cooking_max_portions int NOT NULL DEFAULT 4
  CHECK (batch_cooking_max_portions BETWEEN 2 AND 7);
