-- Migration: Add product classification columns (is_premade_product, product_type) to recipe table
-- File: supabase/migrations/20260721000005_premade_product_classification.sql

ALTER TABLE recipe
ADD COLUMN IF NOT EXISTS is_premade_product BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS product_type TEXT DEFAULT 'diy';

-- Set product_type for existing starter remedies
UPDATE recipe
SET is_premade_product = false, product_type = 'diy'
WHERE mode = 'beauty';
