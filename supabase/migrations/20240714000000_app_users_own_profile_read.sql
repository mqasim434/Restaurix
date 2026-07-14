-- Let authenticated users read their own app_users row (waiter tablet login).
-- Supabase Auth alone is not enough: app_users must exist with auth_user_id + role.

DROP POLICY IF EXISTS authenticated_read_own_app_user ON app_users;

CREATE POLICY authenticated_read_own_app_user ON app_users
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid() AND deleted_at IS NULL);
