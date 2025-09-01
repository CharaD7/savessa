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
  
  // Firebase configuration - Shared across platforms
  String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  // Platform-specific Firebase API Keys
  String get firebaseWebApiKey => dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  String get firebaseAndroidApiKey => dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  String get firebaseIosApiKey => dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  String get firebaseMacosApiKey => dotenv.env['FIREBASE_MACOS_API_KEY'] ?? '';
  String get firebaseWindowsApiKey => dotenv.env['FIREBASE_WINDOWS_API_KEY'] ?? '';
  
  // Platform-specific Firebase App IDs
  String get firebaseWebAppId => dotenv.env['FIREBASE_WEB_APP_ID'] ?? '';
  String get firebaseAndroidAppId => dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  String get firebaseIosAppId => dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  String get firebaseMacosAppId => dotenv.env['FIREBASE_MACOS_APP_ID'] ?? '';
  String get firebaseWindowsAppId => dotenv.env['FIREBASE_WINDOWS_APP_ID'] ?? '';
  
  // Web-specific Firebase configuration
  String get firebaseWebAuthDomain => dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? '';
  String get firebaseWebMeasurementId => dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'] ?? '';
  
  // Windows-specific Firebase configuration
  String get firebaseWindowsAuthDomain => dotenv.env['FIREBASE_WINDOWS_AUTH_DOMAIN'] ?? '';
  String get firebaseWindowsMeasurementId => dotenv.env['FIREBASE_WINDOWS_MEASUREMENT_ID'] ?? '';
  
  // iOS/macOS-specific Firebase configuration
  String get firebaseIosBundleId => dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';
  
  // Legacy Firebase configuration (kept for backward compatibility)
  String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  
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
  
  // Twilio SMS Configuration
  String get twilioAccountSid => dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  String get twilioAuthToken => dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  String get twilioPhoneNumber => dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';
  
  // Resend Email Configuration
  String get resendApiKey => dotenv.env['RESEND_API_KEY'] ?? '';
  
  // App configuration
  String get appName => dotenv.env['APP_NAME'] ?? 'Savessa';
  String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  bool get isProduction => appEnv == 'production';
  bool get isDevelopment => appEnv == 'development';
  bool get isStaging => appEnv == 'staging';
  
  /// Validates that all required Firebase environment variables are present.
  /// 
  /// Throws a [StateError] with a detailed message if any required variables are missing.
  void validateFirebaseConfig() {
    final missingVars = <String>[];
    
    // Check shared Firebase configuration
    if (firebaseProjectId.isEmpty) missingVars.add('FIREBASE_PROJECT_ID');
    if (firebaseMessagingSenderId.isEmpty) missingVars.add('FIREBASE_MESSAGING_SENDER_ID');
    if (firebaseStorageBucket.isEmpty) missingVars.add('FIREBASE_STORAGE_BUCKET');
    
    // Check platform-specific API keys
    if (firebaseWebApiKey.isEmpty || firebaseWebApiKey == 'your-web-api-key-here') {
      missingVars.add('FIREBASE_WEB_API_KEY');
    }
    if (firebaseAndroidApiKey.isEmpty || firebaseAndroidApiKey == 'your-android-api-key-here') {
      missingVars.add('FIREBASE_ANDROID_API_KEY');
    }
    if (firebaseIosApiKey.isEmpty || firebaseIosApiKey == 'your-ios-api-key-here') {
      missingVars.add('FIREBASE_IOS_API_KEY');
    }
    if (firebaseMacosApiKey.isEmpty || firebaseMacosApiKey == 'your-macos-api-key-here') {
      missingVars.add('FIREBASE_MACOS_API_KEY');
    }
    if (firebaseWindowsApiKey.isEmpty || firebaseWindowsApiKey == 'your-windows-api-key-here') {
      missingVars.add('FIREBASE_WINDOWS_API_KEY');
    }
    
    // Check platform-specific App IDs
    if (firebaseWebAppId.isEmpty) missingVars.add('FIREBASE_WEB_APP_ID');
    if (firebaseAndroidAppId.isEmpty) missingVars.add('FIREBASE_ANDROID_APP_ID');
    if (firebaseIosAppId.isEmpty) missingVars.add('FIREBASE_IOS_APP_ID');
    if (firebaseMacosAppId.isEmpty) missingVars.add('FIREBASE_MACOS_APP_ID');
    if (firebaseWindowsAppId.isEmpty) missingVars.add('FIREBASE_WINDOWS_APP_ID');
    
    // Check web-specific configuration
    if (firebaseWebAuthDomain.isEmpty || firebaseWebAuthDomain.contains('your-project-id')) {
      missingVars.add('FIREBASE_WEB_AUTH_DOMAIN');
    }
    if (firebaseWebMeasurementId.isEmpty) missingVars.add('FIREBASE_WEB_MEASUREMENT_ID');
    
    // Check Windows-specific configuration
    if (firebaseWindowsAuthDomain.isEmpty || firebaseWindowsAuthDomain.contains('your-project-id')) {
      missingVars.add('FIREBASE_WINDOWS_AUTH_DOMAIN');
    }
    if (firebaseWindowsMeasurementId.isEmpty) missingVars.add('FIREBASE_WINDOWS_MEASUREMENT_ID');
    
    // Check iOS/macOS-specific configuration
    if (firebaseIosBundleId.isEmpty) missingVars.add('FIREBASE_IOS_BUNDLE_ID');
    
    if (missingVars.isNotEmpty) {
      final errorMessage = '''Firebase configuration validation failed!

Missing or invalid environment variables:
${missingVars.map((v) => '- $v').join('\n')}

Please check your .env file and ensure all Firebase credentials are properly configured.
Refer to the .env.example file for the required format.

To get these values:
1. Go to the Firebase Console (https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings > General
4. Scroll down to "Your apps" section
5. For each platform, copy the respective configuration values''';
      
      throw StateError(errorMessage);
    }
  }
}
