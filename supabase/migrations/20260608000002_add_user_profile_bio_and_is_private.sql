ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS is_private boolean NOT NULL DEFAULT false;
