import 'package:postgres/postgres.dart';
import '../../core/config/env_config.dart';

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
      print('Error initializing database connection: $e');
      throw Exception('Failed to initialize PostgreSQL connection: $e');
    }
  }

  Future<void> connect() async {
    if (!_isConnected) {
      try {
        await _connection.open();
        _isConnected = true;
        print('Connected to PostgreSQL database');
      } catch (e) {
        print('Failed to connect to PostgreSQL database: $e');
        rethrow;
      }
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      await _connection.close();
      _isConnected = false;
      print('Disconnected from PostgreSQL database');
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
      print('Query error: $e');
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
      print('Execute error: $e');
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

  Future<void> createUser(Map<String, dynamic> userData) async {
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

  // Add more methods for other database operations as needed
}