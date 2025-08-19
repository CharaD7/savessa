import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A service that provides access to environment variables.
/// 
/// This class centralizes access to all environment variables used in the app,
/// making it easier to manage and update them.
class EnvConfig {
  // Singleton pattern
  static final EnvConfig _instance = EnvConfig._internal();
  
  factory EnvConfig() {
    return _instance;
  }
  
  EnvConfig._internal();
  
  // Database configuration
  String get dbHostRaw => dotenv.env['DB_HOST'] ?? '';
  String get dbHostResolved {
    final raw = dbHostRaw.trim();
    // On Android emulator, localhost should be 10.0.2.2 to reach the host machine.
    if (Platform.isAndroid && (raw == 'localhost' || raw == '127.0.0.1' || raw.isEmpty)) {
      return '10.0.2.2';
    }
    return raw;
  }
  String get dbHost => dbHostResolved;
  String get dbPort => dotenv.env['DB_PORT'] ?? '5432';
  String get dbName => dotenv.env['DB_NAME'] ?? '';
  String get dbUser => dotenv.env['DB_USER'] ?? '';
  String get dbPassword => dotenv.env['DB_PASSWORD'] ?? '';
  String get dbSsl => dotenv.env['DB_SSL'] ?? 'require';
  
  // Construct the database connection URI
  String get dbConnectionUri => 
      'postgres://$dbUser:$dbPassword@$dbHost:$dbPort/$dbName?sslmode=$dbSsl';
  
  // Firebase configuration
  String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  // API keys
  String get abstractApiKey => dotenv.env['ABSTRACT_API_KEY'] ?? '';
  
  // SMTP / Email
  String get smtpHost => dotenv.env['SMTP_HOST'] ?? '';
  int get smtpPort => int.tryParse(dotenv.env['SMTP_PORT'] ?? '') ?? 587;
  String get smtpUsername => dotenv.env['SMTP_USERNAME'] ?? '';
  String get smtpPassword => dotenv.env['SMTP_PASSWORD'] ?? '';
  bool get smtpUseTls => (dotenv.env['SMTP_USE_TLS'] ?? 'true').toLowerCase() == 'true';
  String get emailFromAddress => dotenv.env['EMAIL_FROM_ADDRESS'] ?? '';
  String get emailFromName => dotenv.env['EMAIL_FROM_NAME'] ?? 'Savessa';
  
  // App configuration
  String get appName => dotenv.env['APP_NAME'] ?? 'Savessa';
  String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  bool get isProduction => appEnv == 'production';
  bool get isDevelopment => appEnv == 'development';
  bool get isStaging => appEnv == 'staging';
}
