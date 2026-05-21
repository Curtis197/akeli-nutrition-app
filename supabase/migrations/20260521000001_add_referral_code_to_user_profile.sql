-- Add personal referral code to user_profile
-- Each user gets a unique shareable code, defaulting to 'AKELI-' + first 6 chars of their UUID

ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS referral_code text UNIQUE;

-- Back-fill existing rows
UPDATE user_profile
SET referral_code = 'AKELI-' || UPPER(SUBSTRING(id::text, 1, 6))
WHERE referral_code IS NULL;

-- Add NOT NULL after back-fill
ALTER TABLE user_profile
  ALTER COLUMN referral_code SET DEFAULT 'AKELI-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 6));

-- Index for quick code lookups at sign-up
CREATE INDEX IF NOT EXISTS idx_user_profile_referral_code ON user_profile(referral_code);
