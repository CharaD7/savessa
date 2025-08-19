import 'dart:io';
import 'package:dotenv/dotenv.dart' as d;
import 'package:postgres/postgres.dart';

Future<void> main() async {
  final env = d.DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final host = env['DB_HOST'] ?? 'localhost';
  final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
  final db = env['DB_NAME'] ?? 'savessa';
  final user = env['DB_USER'] ?? 'postgres';
  final pass = env['DB_PASSWORD'] ?? '';

  final endpoint = Endpoint(host: host, port: port, database: db, username: user, password: pass);
  final conn = await Connection.open(endpoint);
  stdout.writeln('Connected to Postgres at $host:$port/$db');

  // Create or get admin user
  const firebaseUid = 'local-admin-demo-uid';
  const email = 'admin@example.com';
  const phone = '+233200000001';
  const firstName = 'Admin';
  const lastName = 'Manager';

  await conn.execute(
    Sql.named('''
    INSERT INTO users (firebase_uid, email, phone, first_name, last_name, role)
    VALUES (@uid, @em, @ph, @fn, @ln, 'admin')
    ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email
    '''),
    parameters: {'uid': firebaseUid, 'em': email, 'ph': phone, 'fn': firstName, 'ln': lastName},
  );

  final adminRows = await conn.execute(Sql.named("SELECT id FROM users WHERE firebase_uid = @uid"), parameters: {'uid': firebaseUid});
  final adminId = adminRows.first.first as String;

  // Create group
  const groupName = 'Community Savings Group';
  await conn.execute(
    Sql.named('''
    INSERT INTO groups (id, name, monthly_goal, smart_contract_enabled, created_by)
    VALUES (gen_random_uuid(), @name, 500, FALSE, @admin)
    '''),
    parameters: {'name': groupName, 'admin': adminId},
  );

  final grpRows = await conn.execute(Sql.named("SELECT id FROM groups WHERE name = @name ORDER BY created_at DESC LIMIT 1"), parameters: {'name': groupName});
  final groupId = grpRows.first.first as String;

  // Create members
  final members = [
    {'email': 'amina@example.com', 'phone': '+233200000002', 'first': 'Amina', 'last': 'Issah'},
    {'email': 'kojo@example.com', 'phone': '+233200000003', 'first': 'Kojo', 'last': 'Mensah'},
    {'email': 'kofi@example.com', 'phone': '+233200000004', 'first': 'Kofi', 'last': 'Owusu'},
  ];

  for (final m in members) {
    await conn.execute(
      Sql.named("INSERT INTO users (id, email, phone, first_name, last_name, role) VALUES (gen_random_uuid(), @em, @ph, @fn, @ln, 'member') ON CONFLICT (email) DO NOTHING"),
      parameters: {'em': m['email'], 'ph': m['phone'], 'fn': m['first'], 'ln': m['last']},
    );
  }

  final userRows = await conn.execute(
    Sql.named("SELECT id, email FROM users WHERE email IN (@a, @b, @c)"),
    parameters: {
      'a': members[0]['email'],
      'b': members[1]['email'],
      'c': members[2]['email'],
    },
  );

  for (final row in userRows) {
    final uid = row[0] as String;
    await conn.execute(
      Sql.named('''
      INSERT INTO group_members (group_id, user_id, role, status)
      VALUES (@g, @u, 'member', 'active') ON CONFLICT DO NOTHING
      '''),
      parameters: {'g': groupId, 'u': uid},
    );
  }

  // Monthly goal row for current month
  final now = DateTime.now();
  await conn.execute(
    Sql.named('''
    INSERT INTO monthly_goals (group_id, month, year, target_amount, achieved_amount)
    VALUES (@g, @m, @y, 500, 0)
    ON CONFLICT (group_id, month, year) DO NOTHING
    '''),
    parameters: {'g': groupId, 'm': now.month, 'y': now.year},
  );

  // Contributions for current month
  final contribUsers = await conn.execute(Sql.named("SELECT user_id FROM group_members WHERE group_id = @g"), parameters: {'g': groupId});
  int day = 5;
  for (final r in contribUsers) {
    final uid = r[0] as String;
    await conn.execute(
      Sql.named('''
      INSERT INTO contributions (id, group_id, user_id, amount, date, status)
      VALUES (gen_random_uuid(), @g, @u, 200, @d, 'recorded')
      '''),
      parameters: {'g': groupId, 'u': uid, 'd': DateTime(now.year, now.month, day)},
    );
    day += 7;
  }

  stdout.writeln('Seeded admin, group, members, and contributions.');
  await conn.close();
}

