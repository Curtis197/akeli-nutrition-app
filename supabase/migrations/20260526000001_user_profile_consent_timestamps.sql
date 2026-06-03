-- GDPR Article 7: record the exact moment the user accepted each policy.
-- NULL = consent not yet given (e.g. legacy rows created before this migration).
-- Non-null = ISO 8601 timestamp of acceptance, set once at onboarding completion.

ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS consent_privacy_at timestamptz,
  ADD COLUMN IF NOT EXISTS consent_cgu_at     timestamptz;

COMMENT ON COLUMN user_profile.consent_privacy_at IS
  'Timestamp when the user accepted the Privacy Policy (GDPR Art. 7 record).';
COMMENT ON COLUMN user_profile.consent_cgu_at IS
  'Timestamp when the user accepted the Terms of Service (CGU).';
