import 'package:bcrypt/bcrypt.dart';

class SecurityService {
  // Hash password using bcrypt with a generated salt.
  static String hashPassword(String password) {
    // Use default work factor (cost). Can be tuned, e.g., BCrypt.gensaltWithRounds(12)
    final salt = BCrypt.gensalt();
    return BCrypt.hashpw(password, salt);
  }

  // Verify plaintext against a bcrypt hash. Falls back to legacy plaintext compare if needed.
  static bool verifyPassword(String password, String stored) {
    try {
      // If stored looks like a bcrypt hash (starts with $2...), use bcrypt verify
      if (stored.startsWith(r'$2')) {
        return BCrypt.checkpw(password, stored);
      }
    } catch (_) {
      // If bcrypt parsing fails, treat as legacy below
    }
    // Legacy fallback: plaintext compare for pre-migration records
    return stored == password;
  }
}

