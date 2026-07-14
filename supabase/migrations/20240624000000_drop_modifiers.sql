-- Remove modifier groups, modifiers, and order-item modifier snapshots.

DROP TABLE IF EXISTS order_item_modifiers CASCADE;
DROP TABLE IF EXISTS modifiers CASCADE;
DROP TABLE IF EXISTS modifier_groups CASCADE;

ALTER TABLE IF EXISTS products
  DROP COLUMN IF EXISTS modifier_group_ids;

ALTER TABLE IF EXISTS deal_items
  DROP COLUMN IF EXISTS allow_modifiers;
