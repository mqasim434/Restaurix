-- Product prep time used by kitchen tickets / order ETA.
-- Fixes PGRST204: Could not find the 'estimated_prep_minutes' column of 'products'

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS estimated_prep_minutes INTEGER NOT NULL DEFAULT 10;

COMMENT ON COLUMN products.estimated_prep_minutes IS
  'Estimated kitchen prep time in minutes for this product';
