-- In-restaurant credit accounts (regulars on tab) — distinct from customer_app profiles.

CREATE TABLE IF NOT EXISTS credit_customers (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name             TEXT NOT NULL,
  phone                 TEXT,
  address_line1         TEXT,
  address_line2         TEXT,
  city                  TEXT,
  postcode              TEXT,
  notes                 TEXT,
  balance               NUMERIC(12, 2) NOT NULL DEFAULT 0,
  credit_limit          NUMERIC(12, 2),
  is_active             BOOLEAN NOT NULL DEFAULT TRUE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced             BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at            TIMESTAMPTZ,
  sync_action           TEXT NOT NULL DEFAULT 'create',
  device_id             TEXT NOT NULL DEFAULT '',
  version               INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_credit_customers_active
  ON credit_customers (is_active)
  WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS credit_transactions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  credit_customer_id    UUID NOT NULL REFERENCES credit_customers (id),
  order_id              UUID REFERENCES orders (id),
  transaction_type      TEXT NOT NULL,
  amount                NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
  balance_delta         NUMERIC(12, 2) NOT NULL,
  balance_after         NUMERIC(12, 2) NOT NULL,
  payment_type          TEXT,
  notes                 TEXT,
  created_by_user_id    TEXT NOT NULL DEFAULT '',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced             BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at            TIMESTAMPTZ,
  sync_action           TEXT NOT NULL DEFAULT 'create',
  device_id             TEXT NOT NULL DEFAULT '',
  version               INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT credit_transactions_type_check CHECK (
    transaction_type IN ('order_charge', 'order_reversal', 'payment', 'adjustment')
  )
);

CREATE INDEX IF NOT EXISTS idx_credit_transactions_customer
  ON credit_transactions (credit_customer_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_credit_transactions_order_charge
  ON credit_transactions (order_id)
  WHERE deleted_at IS NULL
    AND transaction_type = 'order_charge'
    AND order_id IS NOT NULL;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS credit_customer_id UUID REFERENCES credit_customers (id);

CREATE INDEX IF NOT EXISTS idx_orders_credit_customer
  ON orders (credit_customer_id)
  WHERE deleted_at IS NULL AND credit_customer_id IS NOT NULL;

-- RLS: staff only (same pattern as employees).
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['credit_customers', 'credit_transactions']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);

    EXECUTE format('DROP POLICY IF EXISTS admin_all ON %I', tbl);
    EXECUTE format(
      'CREATE POLICY admin_all ON %I FOR ALL TO authenticated USING (is_app_admin()) WITH CHECK (is_app_admin())',
      tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS salesman_select ON %I', tbl);
    EXECUTE format(
      'CREATE POLICY salesman_select ON %I FOR SELECT TO authenticated USING (is_app_salesman())',
      tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS salesman_write ON %I', tbl);
    EXECUTE format(
      'CREATE POLICY salesman_write ON %I FOR INSERT TO authenticated WITH CHECK (is_app_salesman())',
      tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS salesman_update ON %I', tbl);
    EXECUTE format(
      'CREATE POLICY salesman_update ON %I FOR UPDATE TO authenticated USING (is_app_salesman()) WITH CHECK (is_app_salesman())',
      tbl
    );
  END LOOP;
END $$;
