-- Module 33: role-based RLS replacing permissive dev policies.

CREATE OR REPLACE FUNCTION public.current_app_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM app_users
  WHERE auth_user_id = auth.uid()
    AND deleted_at IS NULL
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_app_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT current_app_role() = 'admin';
$$;

CREATE OR REPLACE FUNCTION public.is_app_salesman()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT current_app_role() = 'salesman';
$$;

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
    EXECUTE format('DROP POLICY IF EXISTS dev_allow_all_anon ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS dev_allow_all_authenticated ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS admin_all ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS salesman_select ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS salesman_write ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS salesman_update ON %I', tbl);
  END LOOP;
END $$;

-- Admin full access on every syncable table.
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
    EXECUTE format(
      'CREATE POLICY admin_all ON %I FOR ALL TO authenticated USING (is_app_admin()) WITH CHECK (is_app_admin())',
      tbl
    );
  END LOOP;
END $$;

-- Salesman read access to catalog + operational data needed for POS/KDS.
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'categories', 'products', 'product_variants', 'modifier_groups', 'modifiers',
    'deals', 'deal_items', 'halls', 'restaurant_tables', 'orders', 'order_items',
    'order_item_modifiers', 'discounts', 'pickup_companies', 'riders'
  ]
  LOOP
    EXECUTE format(
      'CREATE POLICY salesman_select ON %I FOR SELECT TO authenticated USING (is_app_salesman())',
      tbl
    );
  END LOOP;
END $$;

-- Salesman write access for day-to-day order and table operations.
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'orders', 'order_items', 'order_item_modifiers', 'restaurant_tables'
  ]
  LOOP
    EXECUTE format(
      'CREATE POLICY salesman_write ON %I FOR INSERT TO authenticated WITH CHECK (is_app_salesman())',
      tbl
    );
    EXECUTE format(
      'CREATE POLICY salesman_update ON %I FOR UPDATE TO authenticated USING (is_app_salesman()) WITH CHECK (is_app_salesman())',
      tbl
    );
  END LOOP;
END $$;

-- Salesmen can read their own app_users row only.
CREATE POLICY salesman_read_own_app_user ON app_users
  FOR SELECT TO authenticated
  USING (is_app_salesman() AND auth_user_id = auth.uid());
