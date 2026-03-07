-- =============================================================================
-- AKELI V1 — Migration: Fix Missing RLS Policies
-- Migration: 20260302000002_fix_rls_policies.sql
-- Raison: plusieurs Edge Functions échouent car les policies RLS ne couvrent
--         pas toutes les opérations effectuées avec le JWT utilisateur.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. fan_subscription — ajouter UPDATE pour le propriétaire
--    Nécessaire pour activate-fan-mode et cancel-fan-mode (utilisent client JWT)
-- ---------------------------------------------------------------------------

CREATE POLICY "owner updates fan_subscription" ON fan_subscription
  FOR UPDATE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 2. fan_subscription_history — ajouter INSERT pour le propriétaire
--    activate-fan-mode et cancel-fan-mode insèrent l'historique via client JWT
-- ---------------------------------------------------------------------------

CREATE POLICY "owner inserts fan_subscription_history" ON fan_subscription_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 3. fan_external_recipe_counter — ajouter INSERT et UPDATE pour le propriétaire
--    log-meal-consumption incrémente le compteur via client JWT
-- ---------------------------------------------------------------------------

CREATE POLICY "owner inserts fan_external_recipe_counter" ON fan_external_recipe_counter
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner updates fan_external_recipe_counter" ON fan_external_recipe_counter
  FOR UPDATE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 4. creator — ajouter UPDATE pour service_role
--    stripe-webhook met à jour stripe_charges_enabled via serviceClient()
--    (service_role contourne RLS par défaut, mais le rendre explicite est une
--    bonne pratique et évite les surprises si la config RLS change)
-- ---------------------------------------------------------------------------

CREATE POLICY "service updates creator" ON creator
  FOR UPDATE WITH CHECK (auth.role() = 'service_role');
