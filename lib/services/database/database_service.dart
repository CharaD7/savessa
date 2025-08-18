import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'package:savessa/core/config/env_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late PostgreSQLConnection _connection;
  bool _isConnected = false;

  // Singleton pattern
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal() {
    _initConnection();
  }

  void _initConnection() {
    // Get database configuration from environment variables
    final config = EnvConfig();
    
    try {
      _connection = PostgreSQLConnection(
        config.dbHost,
        int.parse(config.dbPort),
        config.dbName,
        username: config.dbUser,
        password: config.dbPassword,
        useSSL: config.dbSsl.toLowerCase() == 'require',
      );
    } catch (e) {
      debugPrint('Error initializing database connection: $e');
      throw Exception('Failed to initialize PostgreSQL connection: $e');
    }
  }

  Future<void> connect() async {
    if (!_isConnected) {
      try {
        await _connection.open();
        _isConnected = true;
        debugPrint('Connected to PostgreSQL database');
      } catch (e) {
        debugPrint('Failed to connect to PostgreSQL database: $e');
        rethrow;
      }
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      await _connection.close();
      _isConnected = false;
      debugPrint('Disconnected from PostgreSQL database');
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql, [Map<String, dynamic>? parameters]) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      final results = await _connection.mappedResultsQuery(sql, substitutionValues: parameters);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      debugPrint('Query error: $e');
      rethrow;
    }
  }

  Future<int> execute(String sql, [Map<String, dynamic>? parameters]) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      return await _connection.execute(sql, substitutionValues: parameters);
    } catch (e) {
      debugPrint('Execute error: $e');
      rethrow;
    }
  }

  // User-related methods
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final results = await query(
      'SELECT * FROM users WHERE email = @email',
      {'email': email},
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final results = await query(
      'SELECT id, first_name, last_name, other_names, email, phone, role, profile_image_url FROM users WHERE id = @id LIMIT 1',
      {'id': userId},
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateUserProfile({
    required int userId,
    String? firstName,
    String? lastName,
    String? otherNames,
    String? phone,
    String? profileImageUrl,
  }) async {
    final fields = <String, String>{};
    final params = <String, dynamic>{'id': userId};
    if (firstName != null) {
      fields['first_name'] = '@first_name';
      params['first_name'] = firstName;
    }
    if (lastName != null) {
      fields['last_name'] = '@last_name';
      params['last_name'] = lastName;
    }
    if (otherNames != null) {
      fields['other_names'] = '@other_names';
      params['other_names'] = otherNames;
    }
    if (phone != null) {
      fields['phone'] = '@phone';
      params['phone'] = phone;
    }
    if (profileImageUrl != null) {
      fields['profile_image_url'] = '@profile_image_url';
      params['profile_image_url'] = profileImageUrl;
    }
    if (fields.isEmpty) return; // nothing to update

    final setClause = fields.entries.map((e) => "${e.key} = ${e.value}").join(', ');
    final sql = 'UPDATE users SET $setClause, updated_at = NOW() WHERE id = @id';
    await execute(sql, params);
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final results = await query(
      'SELECT * FROM users WHERE phone = @phone',
      {'phone': phone},
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmailOrPhone(String identifier) async {
    final results = await query(
      'SELECT * FROM users WHERE email = @id OR phone = @id LIMIT 1',
      {'id': identifier},
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    // Enforce unique email/phone by checking first
    final existingEmail = await getUserByEmail(userData['email']);
    if (existingEmail != null) {
      throw Exception('EMAIL_EXISTS');
    }
    if ((userData['phone'] as String).isNotEmpty) {
      final existingPhone = await getUserByPhone(userData['phone']);
      if (existingPhone != null) {
        throw Exception('PHONE_EXISTS');
      }
    }

    await execute(
      '''
      INSERT INTO users (
        first_name, last_name, other_names, email, phone, role, password_hash, created_at
      ) VALUES (
        @first_name, @last_name, @other_names, @email, @phone, @role, @password_hash, NOW()
      )
      ''',
      {
        'first_name': userData['first_name'],
        'last_name': userData['last_name'],
        'other_names': userData['other_names'] ?? '',
        'email': userData['email'],
        'phone': userData['phone'],
        'role': userData['role'],
        'password_hash': userData['password'], // In a real app, this would be hashed
      },
    );
  }

  Future<Map<String, dynamic>?> verifyCredentials({required String identifier, required String password}) async {
    final user = await getUserByEmailOrPhone(identifier);
    if (user == null) return null;
    // NOTE: In production use a proper password hash verification.
    final stored = (user['password_hash'] ?? '').toString();
    if (stored == password) return user;
    throw Exception('INVALID_PASSWORD');
  }

  // Mirror Firebase user to Postgres users table (by firebase_uid)
  Future<void> upsertUserMirror({
    required String firebaseUid,
    String? email,
    String? phone,
    String defaultRole = 'member',
  }) async {
    await execute(
      '''
      INSERT INTO users (firebase_uid, email, phone, role, created_at, updated_at)
      VALUES (@uid, @email, @phone, @role, NOW(), NOW())
      ON CONFLICT (firebase_uid)
      DO UPDATE SET email = COALESCE(EXCLUDED.email, users.email),
                    phone = COALESCE(EXCLUDED.phone, users.phone),
                    updated_at = NOW()
      ''',
      {
        'uid': firebaseUid,
        'email': email,
        'phone': phone,
        'role': defaultRole,
      },
    );
  }

  Future<String?> getRoleByFirebaseUid(String firebaseUid) async {
    final rows = await query(
      'SELECT role FROM users WHERE firebase_uid = @uid LIMIT 1',
      {'uid': firebaseUid},
    );
    if (rows.isEmpty) return null;
    return rows.first['role'] as String?;
  }

  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    final rows = await query(
      'SELECT id, role, email, phone FROM users WHERE firebase_uid = @uid LIMIT 1',
      {'uid': firebaseUid},
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  // Add more methods for other database operations as needed
}
