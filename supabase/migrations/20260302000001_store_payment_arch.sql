-- =============================================================================
-- AKELI V1 — Migration: Store Payment Architecture
-- Migration: 20260302000001_store_payment_arch.sql
-- Raison: les abonnements utilisateurs passent par Google Play / App Store
--         (pas Stripe). Stripe est réservé aux reversements créateurs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. TABLE subscription — remplacer les colonnes Stripe par les colonnes store
-- ---------------------------------------------------------------------------

ALTER TABLE subscription
  -- Colonnes Stripe obsolètes (abonnement utilisateur géré par le store)
  DROP COLUMN IF EXISTS stripe_customer_id,
  DROP COLUMN IF EXISTS stripe_subscription_id,

  -- Nouvelles colonnes pour in-app purchase (Google Play / App Store)
  ADD COLUMN IF NOT EXISTS store_platform     text CHECK (store_platform IN ('android', 'ios')),
  ADD COLUMN IF NOT EXISTS store_product_id   text,
  ADD COLUMN IF NOT EXISTS store_purchase_token text;

-- Mettre à jour le CHECK sur status : supprimer 'trialing' et 'past_due'
-- (spécifiques Stripe), garder 'active' et 'cancelled'
ALTER TABLE subscription
  DROP CONSTRAINT IF EXISTS subscription_status_check;

ALTER TABLE subscription
  ADD CONSTRAINT subscription_status_check
  CHECK (status IN ('active', 'cancelled'));

-- ---------------------------------------------------------------------------
-- 2. TABLE creator — ajouter les colonnes Stripe Connect (reversements)
-- ---------------------------------------------------------------------------

ALTER TABLE creator
  ADD COLUMN IF NOT EXISTS stripe_account_id      text UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_charges_enabled boolean DEFAULT false;

-- ---------------------------------------------------------------------------
-- 3. TABLE creator_payout — historique des reversements vers les créateurs
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS creator_payout (
  id                         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id                 uuid NOT NULL REFERENCES creator(id) ON DELETE CASCADE,
  stripe_payment_intent_id   text UNIQUE,
  amount_cents               int NOT NULL,
  currency                   text NOT NULL DEFAULT 'eur',
  status                     text CHECK (status IN ('succeeded', 'failed')) NOT NULL,
  paid_at                    timestamptz,
  created_at                 timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_creator_payout_creator ON creator_payout(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_payout_status  ON creator_payout(status);

ALTER TABLE creator_payout ENABLE ROW LEVEL SECURITY;

-- Les créateurs peuvent voir leurs propres reversements
CREATE POLICY "creator reads own payouts" ON creator_payout
  FOR SELECT USING (
    creator_id IN (
      SELECT id FROM creator WHERE user_id = auth.uid()
    )
  );

-- Seul le service role peut insérer (via stripe-webhook Edge Function)
CREATE POLICY "service inserts creator_payout" ON creator_payout
  FOR INSERT WITH CHECK (auth.role() = 'service_role');
