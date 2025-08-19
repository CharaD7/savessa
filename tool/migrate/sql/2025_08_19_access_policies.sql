-- Savessa access policies and grants for app DB user
-- This migration is safe to run multiple times.

BEGIN;

-- Optional: Enable RLS and create permissive policies for the app user
-- If you do not use RLS, the GRANTs below are sufficient.
DO $$
DECLARE
  app_user text := current_user; -- assumes you run migrations as the app user
BEGIN
  -- Users table
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    EXECUTE 'ALTER TABLE users ENABLE ROW LEVEL SECURITY';
    -- Create or replace permissive policy allowing the app user full access
    -- Using commands that "upsert" policy by dropping if exists
    IF EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname = current_schema() AND tablename = 'users' AND policyname = 'users_app_rw'
    ) THEN
      EXECUTE 'DROP POLICY users_app_rw ON users';
    END IF;
    EXECUTE format(
      'CREATE POLICY users_app_rw ON users FOR ALL TO %I USING (true) WITH CHECK (true)',
      app_user
    );
  END IF;

  -- Audit log table
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_audit_log') THEN
    EXECUTE 'ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY';
    IF EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname = current_schema() AND tablename = 'admin_audit_log' AND policyname = 'audit_app_rw'
    ) THEN
      EXECUTE 'DROP POLICY audit_app_rw ON admin_audit_log';
    END IF;
    EXECUTE format(
      'CREATE POLICY audit_app_rw ON admin_audit_log FOR ALL TO %I USING (true) WITH CHECK (true)',
      app_user
    );
  END IF;

  -- GRANT privileges as an additional safety net (works with or without RLS)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE users TO %I', app_user);
    EXECUTE format('GRANT USAGE, SELECT, UPDATE ON SEQUENCE users_id_seq TO %I', app_user);
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_audit_log') THEN
    EXECUTE format('GRANT SELECT, INSERT ON TABLE admin_audit_log TO %I', app_user);
    BEGIN
      EXECUTE format('GRANT USAGE, SELECT, UPDATE ON SEQUENCE admin_audit_log_id_seq TO %I', app_user);
    EXCEPTION WHEN undefined_table THEN
      -- sequence may not exist if id is not serial
      NULL;
    END;
  END IF;
END $$;

COMMIT;

