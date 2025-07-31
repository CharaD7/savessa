import 'package:postgres/postgres.dart';

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
    // Parse the connection URI
    final uri = 'postgres://avnadmin:[PASSWORD]@pg-20190fe4-savessa.h.aivencloud.com:24322/defaultdb?sslmode=require';
    
    // Extract connection details from URI
    final RegExp regex = RegExp(r'postgres:\/\/([^:]+):([^@]+)@([^:]+):(\d+)\/([^?]+)');
    final match = regex.firstMatch(uri);
    
    if (match != null) {
      final username = match.group(1)!;
      final password = match.group(2)!;
      final host = match.group(3)!;
      final port = int.parse(match.group(4)!);
      final database = match.group(5)!;
      
      _connection = PostgreSQLConnection(
        host,
        port,
        database,
        username: username,
        password: password,
        useSSL: true,
      );
    } else {
      throw Exception('Invalid PostgreSQL connection URI');
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