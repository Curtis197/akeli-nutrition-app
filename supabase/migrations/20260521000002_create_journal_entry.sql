-- Journal entries — daily food diary with optional photo attachments

CREATE TABLE journal_entry (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
  meal_type   text NOT NULL CHECK (meal_type IN ('Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation')),
  description text NOT NULL,
  photo_urls  text[] DEFAULT '{}',
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX idx_journal_entry_user ON journal_entry(user_id, created_at DESC);

ALTER TABLE journal_entry ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner only journal_entry" ON journal_entry
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
