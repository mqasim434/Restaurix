-- Restaurix initial schema (Module 3)
-- Apply via Supabase CLI: supabase db push
-- Or paste into Supabase Dashboard → SQL Editor

-- ---------------------------------------------------------------------------
-- Helper: standard sync columns reused in comments below
-- id, created_at, updated_at, is_synced, deleted_at, sync_action, device_id, version
-- sync_action values: create | update | delete (text, matches local Isar enum names)
-- ---------------------------------------------------------------------------

-- =============================================================================
-- CATEGORIES
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
  id            UUID PRIMARY KEY,
  name          TEXT NOT NULL,
  image_url     TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_categories_updated_at ON categories (updated_at);
CREATE INDEX IF NOT EXISTS idx_categories_deleted_at ON categories (deleted_at);

-- =============================================================================
-- PRODUCTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS products (
  id                  UUID PRIMARY KEY,
  name                TEXT NOT NULL,
  category_id         UUID REFERENCES categories (id),
  base_price          NUMERIC(12, 2) NOT NULL DEFAULT 0,
  description         TEXT,
  image_url           TEXT,
  is_available        BOOLEAN NOT NULL DEFAULT TRUE,
  kitchen_category    TEXT NOT NULL DEFAULT '',
  printer_id          TEXT,
  modifier_group_ids  UUID[] NOT NULL DEFAULT '{}',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced           BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at          TIMESTAMPTZ,
  sync_action         TEXT NOT NULL DEFAULT 'create',
  device_id           TEXT NOT NULL DEFAULT '',
  version             INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_products_category_id ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_updated_at ON products (updated_at);

-- =============================================================================
-- PRODUCT VARIANTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS product_variants (
  id            UUID PRIMARY KEY,
  product_id    UUID NOT NULL REFERENCES products (id),
  name          TEXT NOT NULL,
  price         NUMERIC(12, 2) NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_default    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants (product_id);

-- =============================================================================
-- MODIFIER GROUPS & MODIFIERS
-- =============================================================================
CREATE TABLE IF NOT EXISTS modifier_groups (
  id              UUID PRIMARY KEY,
  name            TEXT NOT NULL,
  selection_type  TEXT NOT NULL DEFAULT 'multiple',
  is_required     BOOLEAN NOT NULL DEFAULT FALSE,
  min_selections  INTEGER NOT NULL DEFAULT 0,
  max_selections  INTEGER,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced       BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at      TIMESTAMPTZ,
  sync_action     TEXT NOT NULL DEFAULT 'create',
  device_id       TEXT NOT NULL DEFAULT '',
  version         INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS modifiers (
  id            UUID PRIMARY KEY,
  group_id      UUID NOT NULL REFERENCES modifier_groups (id),
  name          TEXT NOT NULL,
  price_delta   NUMERIC(12, 2) NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_modifiers_group_id ON modifiers (group_id);

-- =============================================================================
-- DEALS
-- =============================================================================
CREATE TABLE IF NOT EXISTS deals (
  id                  UUID PRIMARY KEY,
  name                TEXT NOT NULL,
  description         TEXT,
  image_url           TEXT,
  category_id         UUID REFERENCES categories (id),
  price               NUMERIC(12, 2) NOT NULL DEFAULT 0,
  is_available        BOOLEAN NOT NULL DEFAULT TRUE,
  availability_start  TIMESTAMPTZ,
  availability_end    TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced           BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at          TIMESTAMPTZ,
  sync_action         TEXT NOT NULL DEFAULT 'create',
  device_id           TEXT NOT NULL DEFAULT '',
  version             INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS deal_items (
  id               UUID PRIMARY KEY,
  deal_id          UUID NOT NULL REFERENCES deals (id),
  product_id       UUID NOT NULL REFERENCES products (id),
  variant_id       UUID REFERENCES product_variants (id),
  quantity         INTEGER NOT NULL DEFAULT 1,
  allow_modifiers  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced        BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at       TIMESTAMPTZ,
  sync_action      TEXT NOT NULL DEFAULT 'create',
  device_id        TEXT NOT NULL DEFAULT '',
  version          INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_deal_items_deal_id ON deal_items (deal_id);

-- =============================================================================
-- HALLS & RESTAURANT TABLES
-- =============================================================================
CREATE TABLE IF NOT EXISTS halls (
  id            UUID PRIMARY KEY,
  name          TEXT NOT NULL,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS restaurant_tables (
  id                UUID PRIMARY KEY,
  hall_id           UUID NOT NULL REFERENCES halls (id),
  label             TEXT NOT NULL,
  capacity          INTEGER NOT NULL DEFAULT 4,
  status            TEXT NOT NULL DEFAULT 'available',
  current_order_id  UUID,
  sort_order        INTEGER NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced         BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at        TIMESTAMPTZ,
  sync_action       TEXT NOT NULL DEFAULT 'create',
  device_id         TEXT NOT NULL DEFAULT '',
  version           INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_restaurant_tables_hall_id ON restaurant_tables (hall_id);

-- =============================================================================
-- ORDERS
-- =============================================================================
CREATE TABLE IF NOT EXISTS orders (
  id                    UUID PRIMARY KEY,
  order_number          TEXT NOT NULL,
  order_type            TEXT NOT NULL,
  table_id              UUID REFERENCES restaurant_tables (id),
  delivery_mode         TEXT,
  rider_id              UUID,
  rider_name            TEXT,
  pickup_company_id     UUID,
  pickup_company_name   TEXT,
  subtotal              NUMERIC(12, 2) NOT NULL DEFAULT 0,
  item_discount_total   NUMERIC(12, 2) NOT NULL DEFAULT 0,
  order_discount_total  NUMERIC(12, 2) NOT NULL DEFAULT 0,
  total                 NUMERIC(12, 2) NOT NULL DEFAULT 0,
  payment_type          TEXT,
  payment_status        TEXT NOT NULL DEFAULT 'unpaid',
  status                TEXT NOT NULL DEFAULT 'received',
  is_prepaid            BOOLEAN NOT NULL DEFAULT FALSE,
  is_held               BOOLEAN NOT NULL DEFAULT FALSE,
  created_by_user_id    TEXT NOT NULL DEFAULT '',
  notes                 TEXT,
  cancel_reason         TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced             BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at            TIMESTAMPTZ,
  sync_action           TEXT NOT NULL DEFAULT 'create',
  device_id             TEXT NOT NULL DEFAULT '',
  version               INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_updated_at ON orders (updated_at);

CREATE TABLE IF NOT EXISTS order_items (
  id                 UUID PRIMARY KEY,
  order_id           UUID NOT NULL REFERENCES orders (id),
  product_id         UUID,
  deal_id            UUID,
  name               TEXT NOT NULL,
  variant_name       TEXT,
  unit_price         NUMERIC(12, 2) NOT NULL DEFAULT 0,
  quantity           INTEGER NOT NULL DEFAULT 1,
  line_total         NUMERIC(12, 2) NOT NULL DEFAULT 0,
  applied_discounts  JSONB NOT NULL DEFAULT '[]',
  kitchen_status     TEXT NOT NULL DEFAULT 'received',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced          BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at         TIMESTAMPTZ,
  sync_action        TEXT NOT NULL DEFAULT 'create',
  device_id          TEXT NOT NULL DEFAULT '',
  version            INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items (order_id);

CREATE TABLE IF NOT EXISTS order_item_modifiers (
  id              UUID PRIMARY KEY,
  order_item_id   UUID NOT NULL REFERENCES order_items (id),
  modifier_id     UUID,
  name            TEXT NOT NULL,
  price_delta     NUMERIC(12, 2) NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced       BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at      TIMESTAMPTZ,
  sync_action     TEXT NOT NULL DEFAULT 'create',
  device_id       TEXT NOT NULL DEFAULT '',
  version         INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_order_item_modifiers_order_item_id
  ON order_item_modifiers (order_item_id);

-- =============================================================================
-- DISCOUNTS (applied at checkout, linked to orders)
-- =============================================================================
CREATE TABLE IF NOT EXISTS discounts (
  id              UUID PRIMARY KEY,
  order_id        UUID NOT NULL REFERENCES orders (id),
  order_item_id   UUID REFERENCES order_items (id),
  scope           TEXT NOT NULL,
  target_id       UUID,
  type            TEXT NOT NULL,
  value           NUMERIC(12, 2) NOT NULL DEFAULT 0,
  reason          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced       BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at      TIMESTAMPTZ,
  sync_action     TEXT NOT NULL DEFAULT 'create',
  device_id       TEXT NOT NULL DEFAULT '',
  version         INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_discounts_order_id ON discounts (order_id);

-- =============================================================================
-- EMPLOYEES & ATTENDANCE
-- =============================================================================
CREATE TABLE IF NOT EXISTS employees (
  id                        UUID PRIMARY KEY,
  full_name                 TEXT NOT NULL,
  role                      TEXT NOT NULL DEFAULT '',
  phone                     TEXT,
  hire_date                 DATE NOT NULL,
  pay_type                  TEXT NOT NULL DEFAULT 'hourly',
  hourly_rate               NUMERIC(12, 2),
  monthly_salary_base       NUMERIC(12, 2),
  fingerprint_enrollment_id TEXT,
  is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced                 BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at                TIMESTAMPTZ,
  sync_action               TEXT NOT NULL DEFAULT 'create',
  device_id                 TEXT NOT NULL DEFAULT '',
  version                   INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS attendance_records (
  id                  UUID PRIMARY KEY,
  employee_id         UUID NOT NULL REFERENCES employees (id),
  check_in_time       TIMESTAMPTZ NOT NULL,
  check_out_time      TIMESTAMPTZ,
  source              TEXT NOT NULL DEFAULT 'manual',
  created_by_user_id  TEXT NOT NULL DEFAULT '',
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced           BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at          TIMESTAMPTZ,
  sync_action         TEXT NOT NULL DEFAULT 'create',
  device_id           TEXT NOT NULL DEFAULT '',
  version             INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_attendance_records_employee_id
  ON attendance_records (employee_id);

CREATE TABLE IF NOT EXISTS salary_slips (
  id                    UUID PRIMARY KEY,
  employee_id           UUID NOT NULL REFERENCES employees (id),
  period_start          DATE NOT NULL,
  period_end            DATE NOT NULL,
  total_hours           NUMERIC(10, 2) NOT NULL DEFAULT 0,
  base_pay              NUMERIC(12, 2) NOT NULL DEFAULT 0,
  deductions            NUMERIC(12, 2),
  net_pay               NUMERIC(12, 2) NOT NULL DEFAULT 0,
  generated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  generated_by_user_id  TEXT NOT NULL DEFAULT '',
  status                TEXT NOT NULL DEFAULT 'draft',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced             BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at            TIMESTAMPTZ,
  sync_action           TEXT NOT NULL DEFAULT 'create',
  device_id             TEXT NOT NULL DEFAULT '',
  version               INTEGER NOT NULL DEFAULT 1
);

-- =============================================================================
-- DELIVERY CONFIG
-- =============================================================================
CREATE TABLE IF NOT EXISTS pickup_companies (
  id            UUID PRIMARY KEY,
  name          TEXT NOT NULL,
  logo_url      TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS riders (
  id            UUID PRIMARY KEY,
  name          TEXT NOT NULL,
  phone         TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

-- =============================================================================
-- APP USERS (Module 33 — auth linkage)
-- =============================================================================
CREATE TABLE IF NOT EXISTS app_users (
  id            UUID PRIMARY KEY,
  auth_user_id  UUID UNIQUE,
  employee_id   UUID REFERENCES employees (id),
  role          TEXT NOT NULL DEFAULT 'salesman',
  display_name  TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced     BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at    TIMESTAMPTZ,
  sync_action   TEXT NOT NULL DEFAULT 'create',
  device_id     TEXT NOT NULL DEFAULT '',
  version       INTEGER NOT NULL DEFAULT 1
);

-- =============================================================================
-- ROW LEVEL SECURITY (permissive for development — tightened in Module 33)
-- =============================================================================
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'categories', 'products', 'product_variants', 'modifier_groups', 'modifiers',
    'deals', 'deal_items', 'halls', 'restaurant_tables', 'orders', 'order_items',
    'order_item_modifiers', 'discounts', 'employees', 'attendance_records',
    'salary_slips', 'pickup_companies', 'riders', 'app_users'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);

    EXECUTE format(
      'DROP POLICY IF EXISTS dev_allow_all_anon ON %I', tbl
    );
    EXECUTE format(
      'CREATE POLICY dev_allow_all_anon ON %I FOR ALL TO anon USING (true) WITH CHECK (true)',
      tbl
    );

    EXECUTE format(
      'DROP POLICY IF EXISTS dev_allow_all_authenticated ON %I', tbl
    );
    EXECUTE format(
      'CREATE POLICY dev_allow_all_authenticated ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)',
      tbl
    );
  END LOOP;
END $$;
