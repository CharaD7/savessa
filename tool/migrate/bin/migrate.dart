import 'dart:io';
import 'package:dotenv/dotenv.dart' as d;
import 'package:postgres/postgres.dart';

Future<void> main() async {
  // Load .env from project root
  final env = d.DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final host = env['DB_HOST'] ?? '';
  final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
  final db = env['DB_NAME'] ?? '';
  final user = env['DB_USER'] ?? '';
  final pass = env['DB_PASSWORD'] ?? '';

  if ([host, db, user].any((e) => e.isEmpty)) {
    stderr.writeln('Missing DB envs. Ensure DB_HOST, DB_NAME, DB_USER, DB_PASSWORD are set in .env');
    exit(1);
  }

  final endpoint = Endpoint(
    host: host,
    port: port,
    database: db,
    username: user,
    password: pass,
  );

  final connection = await Connection.open(endpoint);

  try {
    stdout.writeln('Connected to Postgres at $host:$port/$db');

    final statements = <String>[
      // required extension for gen_random_uuid
      'CREATE EXTENSION IF NOT EXISTS pgcrypto;',
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
      ''' ,
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
      ''' ,
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
      ''' ,
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
      ''' ,
      'CREATE INDEX IF NOT EXISTS idx_contributions_group_date ON contributions (group_id, date);',
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
      ''' ,
      // two_factor
      '''
      CREATE TABLE IF NOT EXISTS two_factor (
        user_id UUID PRIMARY KEY,
        totp_secret TEXT,
        sms_enabled BOOLEAN DEFAULT FALSE,
        email_enabled BOOLEAN DEFAULT FALSE,
        methods_enabled TEXT,
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
      ''' ,
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
      ''' ,
      'CREATE INDEX IF NOT EXISTS idx_audit_user_time ON admin_audit_log (user_id, created_at DESC);',
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
      ''' ,
    ];

    for (final s in statements) {
      await connection.execute(s);
    }

    stdout.writeln('Migrations completed successfully.');
  } catch (e) {
    stderr.writeln('Migration failed: $e');
    exit(2);
  } finally {
    await connection.close();
  }
}

