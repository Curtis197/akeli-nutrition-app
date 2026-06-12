ALTER TABLE user_profile
  ADD COLUMN notification_prefs jsonb NOT NULL DEFAULT '{"push":true,"chat":true,"meal_reminders":false,"dm_requests":true}'::jsonb;

COMMENT ON COLUMN user_profile.notification_prefs IS 'User notification preferences: push, chat, meal_reminders, dm_requests (booleans)';
