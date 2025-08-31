import 'package:flutter/foundation.dart';
import 'package:savessa/services/database/database_service.dart';

class MigrationService {
  final DatabaseService _db = DatabaseService();

  Future<void> run() async {
    // Ensure connection
    await _db.connect();

    // Run in a simple sequence; in a real app, track versions
    for (final stmt in _statements) {
      try {
        await _db.execute(stmt);
      } catch (e) {
        debugPrint('Migration error for statement: $e');
        rethrow;
      }
    }
  }

  // Schema (idempotent with IF NOT EXISTS / constraints guarded)
  List<String> get _statements => [
        // required extensions
        '''
        CREATE EXTENSION IF NOT EXISTS pgcrypto;
        CREATE EXTENSION IF NOT EXISTS pgcrypto;
        ''',
        // users
        '''
        CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          firebase_uid TEXT UNIQUE,
          first_name TEXT,
          last_name TEXT,
          other_names TEXT,
          email TEXT UNIQUE,
          phone TEXT,
          role TEXT DEFAULT 'member',
          password_hash TEXT,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        // groups
        '''
        CREATE TABLE IF NOT EXISTS groups (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name TEXT NOT NULL,
          monthly_goal NUMERIC DEFAULT 0,
          smart_contract_enabled BOOLEAN DEFAULT FALSE,
          created_by UUID,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        // group_members
        '''
        CREATE TABLE IF NOT EXISTS group_members (
          group_id UUID NOT NULL,
          user_id UUID NOT NULL,
          role TEXT DEFAULT 'member',
          status TEXT DEFAULT 'active',
          joined_at TIMESTAMPTZ DEFAULT NOW(),
          PRIMARY KEY (group_id, user_id)
        );
        ''',
        // contributions
        '''
        CREATE TABLE IF NOT EXISTS contributions (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          group_id UUID NOT NULL,
          user_id UUID NOT NULL,
          amount NUMERIC NOT NULL,
          date DATE NOT NULL,
          status TEXT DEFAULT 'recorded',
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        // indexes for contributions
        '''
        CREATE INDEX IF NOT EXISTS idx_contributions_group_date ON contributions (group_id, date);
        ''',
        // monthly_goals
        '''
        CREATE TABLE IF NOT EXISTS monthly_goals (
          group_id UUID NOT NULL,
          month INT NOT NULL,
          year INT NOT NULL,
          target_amount NUMERIC NOT NULL,
          achieved_amount NUMERIC DEFAULT 0,
          achieved_at TIMESTAMPTZ,
          PRIMARY KEY (group_id, month, year)
        );
        ''',
        // user_security (replaces older two_factor table)
        '''
        CREATE TABLE IF NOT EXISTS user_security (
          user_id UUID PRIMARY KEY,
          totp_secret TEXT,
          totp_enabled BOOLEAN DEFAULT FALSE,
          sms_enabled BOOLEAN DEFAULT FALSE,
          email_enabled BOOLEAN DEFAULT FALSE,
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        // email OTP codes table (hashed, expiring)
        '''
        CREATE TABLE IF NOT EXISTS email_otp_codes (
          user_id UUID PRIMARY KEY,
          code_hash BYTEA NOT NULL,
          expires_at TIMESTAMPTZ NOT NULL,
          attempts INT DEFAULT 0,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        // helper function to request email OTP (stub for backend email sending)
        '''
        CREATE OR REPLACE FUNCTION request_email_otp(uid UUID)
        RETURNS VOID AS \$\$
        DECLARE
          raw_code TEXT;
        BEGIN
          -- generate a 6-digit numeric code
          raw_code := lpad((floor(random()*1000000))::int::text, 6, '0');
          -- upsert hashed code with 10 min TTL
          INSERT INTO email_otp_codes (user_id, code_hash, expires_at, attempts, created_at)
          VALUES (uid, digest(raw_code, 'sha256'), NOW() + INTERVAL '10 minutes', 0, NOW())
          ON CONFLICT (user_id) DO UPDATE SET code_hash = EXCLUDED.code_hash,
                                             expires_at = EXCLUDED.expires_at,
                                             attempts = 0,
                                             created_at = NOW();
          -- NOTE: actual email sending should be handled by application server using this code
        END;
        \$\$ LANGUAGE plpgsql;
        ''',
        // function to verify email OTP
        '''
        CREATE OR REPLACE FUNCTION verify_email_otp(uid UUID, code TEXT)
        RETURNS BOOLEAN AS \$\$
        DECLARE
          rec RECORD;
          ok BOOLEAN := FALSE;
        BEGIN
          SELECT * INTO rec FROM email_otp_codes WHERE user_id = uid;
          IF rec IS NULL THEN
            RETURN FALSE;
          END IF;
          IF rec.expires_at < NOW() OR rec.attempts >= 5 THEN
            RETURN FALSE;
          END IF;
          IF rec.code_hash = digest(code, 'sha256') THEN
            ok := TRUE;
            -- consume code on success
            DELETE FROM email_otp_codes WHERE user_id = uid;
          ELSE
            -- increment attempts on failure
            UPDATE email_otp_codes SET attempts = attempts + 1 WHERE user_id = uid;
            ok := FALSE;
          END IF;
          RETURN ok;
        END;
        \$\$ LANGUAGE plpgsql;
        ''',
        // admin_audit_log
        '''
        CREATE TABLE IF NOT EXISTS admin_audit_log (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL,
          action TEXT NOT NULL,
          target_type TEXT,
          target_id UUID,
          metadata JSONB,
          ip TEXT,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        '''
        CREATE INDEX IF NOT EXISTS idx_audit_user_time ON admin_audit_log (user_id, created_at DESC);
        ''',
        // device_trust
        '''
        CREATE TABLE IF NOT EXISTS device_trust (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL,
          device_id TEXT,
          fcm_token TEXT,
          platform TEXT,
          last_seen TIMESTAMPTZ,
          trusted BOOLEAN DEFAULT TRUE
        );
        ''',
        // password_reset_tokens for forgot password functionality
        '''
        CREATE TABLE IF NOT EXISTS password_reset_tokens (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token_hash BYTEA NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('email', 'sms')),
          expires_at TIMESTAMPTZ NOT NULL,
          used BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        ''',
        // indexes for password reset tokens
        '''
        CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_hash ON password_reset_tokens(token_hash);
        CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user_created ON password_reset_tokens(user_id, created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires ON password_reset_tokens(expires_at) WHERE NOT used;
        ''',
      ];
}
