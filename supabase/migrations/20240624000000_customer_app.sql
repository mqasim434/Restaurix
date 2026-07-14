-- Customer mobile app: profiles, addresses, public branding, order fields, RLS.
-- Apply after 20240622000000_auth_rls.sql and 20240623000000_realtime_orders.sql

-- =============================================================================
-- RESTAURANT PUBLIC CONFIG (branding for customer app)
-- =============================================================================
CREATE TABLE IF NOT EXISTS restaurant_public_config (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name           TEXT NOT NULL,
  business_address        TEXT,
  tagline                 TEXT,
  logo_url                TEXT,
  cover_image_url         TEXT,
  currency_code           TEXT NOT NULL DEFAULT 'PKR',
  minimum_order_amount    NUMERIC(12, 2) NOT NULL DEFAULT 0,
  delivery_fee            NUMERIC(12, 2) NOT NULL DEFAULT 0,
  estimated_prep_minutes  INTEGER NOT NULL DEFAULT 30,
  is_accepting_orders     BOOLEAN NOT NULL DEFAULT TRUE,
  opening_hours           JSONB NOT NULL DEFAULT '{}',
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO restaurant_public_config (business_name, tagline)
SELECT 'Restaurix', 'Order fresh food to your door'
WHERE NOT EXISTS (SELECT 1 FROM restaurant_public_config);

-- =============================================================================
-- CUSTOMER PROFILES
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_profiles (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id     UUID NOT NULL UNIQUE REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name        TEXT NOT NULL,
  phone            TEXT,
  email            TEXT NOT NULL,
  avatar_url       TEXT,
  marketing_opt_in BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_customer_profiles_auth_user_id
  ON customer_profiles (auth_user_id);

-- =============================================================================
-- CUSTOMER ADDRESSES
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_addresses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customer_profiles (id) ON DELETE CASCADE,
  label       TEXT NOT NULL DEFAULT 'Home',
  line1       TEXT NOT NULL,
  line2       TEXT,
  city        TEXT NOT NULL,
  postcode    TEXT,
  notes       TEXT,
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id
  ON customer_addresses (customer_id);

-- =============================================================================
-- ORDERS — customer fields
-- =============================================================================
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customer_profiles (id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_line1 TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_line2 TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_city TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_postcode TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_notes TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_source TEXT NOT NULL DEFAULT 'desktop';

COMMENT ON COLUMN orders.order_source IS 'desktop | waiter_tablet | customer_app';

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_source ON orders (order_source);

-- =============================================================================
-- RLS HELPERS
-- =============================================================================
CREATE OR REPLACE FUNCTION public.current_customer_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id
  FROM customer_profiles
  WHERE auth_user_id = auth.uid()
    AND deleted_at IS NULL
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_customer()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT current_customer_id() IS NOT NULL;
$$;

ALTER TABLE restaurant_public_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY public_config_read ON restaurant_public_config
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY public_config_admin_write ON restaurant_public_config
  FOR ALL TO authenticated
  USING (is_app_admin())
  WITH CHECK (is_app_admin());

CREATE POLICY customer_profile_select_own ON customer_profiles
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());

CREATE POLICY customer_profile_insert_own ON customer_profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth_user_id = auth.uid());

CREATE POLICY customer_profile_update_own ON customer_profiles
  FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

CREATE POLICY customer_addresses_own ON customer_addresses
  FOR ALL TO authenticated
  USING (customer_id = current_customer_id())
  WITH CHECK (customer_id = current_customer_id());

-- Catalog read (customers)
CREATE POLICY customer_read_categories ON categories
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL AND is_active = TRUE);

CREATE POLICY customer_read_products ON products
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL AND is_available = TRUE);

CREATE POLICY customer_read_variants ON product_variants
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

CREATE POLICY customer_read_modifier_groups ON modifier_groups
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

CREATE POLICY customer_read_modifiers ON modifiers
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

CREATE POLICY customer_read_deals ON deals
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL AND is_available = TRUE);

CREATE POLICY customer_read_deal_items ON deal_items
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

-- Orders (customers)
CREATE POLICY customer_insert_orders ON orders
  FOR INSERT TO authenticated
  WITH CHECK (
    is_customer()
    AND customer_id = current_customer_id()
    AND order_source = 'customer_app'
  );

CREATE POLICY customer_select_own_orders ON orders
  FOR SELECT TO authenticated
  USING (is_customer() AND customer_id = current_customer_id());

CREATE POLICY customer_insert_order_items ON order_items
  FOR INSERT TO authenticated
  WITH CHECK (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_items.order_id
        AND o.customer_id = current_customer_id()
    )
  );

CREATE POLICY customer_select_own_order_items ON order_items
  FOR SELECT TO authenticated
  USING (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_items.order_id
        AND o.customer_id = current_customer_id()
    )
  );

CREATE POLICY customer_insert_order_item_modifiers ON order_item_modifiers
  FOR INSERT TO authenticated
  WITH CHECK (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE oi.id = order_item_modifiers.order_item_id
        AND o.customer_id = current_customer_id()
    )
  );

CREATE POLICY customer_select_own_order_item_modifiers ON order_item_modifiers
  FOR SELECT TO authenticated
  USING (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE oi.id = order_item_modifiers.order_item_id
        AND o.customer_id = current_customer_id()
    )
  );
