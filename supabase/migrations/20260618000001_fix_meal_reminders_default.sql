-- Change meal_reminders default from false to true so that new users
-- receive reminders out of the box, consistent with chat/dm_requests
-- which also default to true. Users who want to opt out can toggle in Settings.

ALTER TABLE user_profile
  ALTER COLUMN notification_prefs
  SET DEFAULT '{"push":true,"chat":true,"meal_reminders":true,"dm_requests":true}'::jsonb;

-- Backfill existing rows that still carry the old default value
-- (notification_prefs was explicitly set to the old default at column creation).
UPDATE user_profile
SET notification_prefs = notification_prefs || '{"meal_reminders":true}'::jsonb
WHERE (notification_prefs->>'meal_reminders')::boolean = false
  AND notification_prefs = '{"push":true,"chat":true,"meal_reminders":false,"dm_requests":true}'::jsonb;
