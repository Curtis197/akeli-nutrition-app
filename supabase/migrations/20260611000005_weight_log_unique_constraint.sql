-- Ensure at most one weight entry per user per day.
-- Clean up any remaining duplicates first (keep the most recent by created_at).
DELETE FROM weight_log
WHERE id NOT IN (
  SELECT DISTINCT ON (user_id, logged_at) id
  FROM weight_log
  ORDER BY user_id, logged_at, created_at DESC
);

ALTER TABLE weight_log
  ADD CONSTRAINT weight_log_user_date_unique UNIQUE (user_id, logged_at);
