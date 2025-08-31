import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:savessa/core/models/password_reset_token.dart';
import 'package:savessa/services/database/database_service.dart';

/// Repository for managing password reset tokens
class PasswordResetTokenRepository {
  final DatabaseService _db = DatabaseService();

  /// Creates a new password reset token for the specified user
  /// Returns the plain text token that should be sent to the user
  Future<String> createToken({
    required String userId,
    required PasswordResetType type,
    Duration expiration = const Duration(minutes: 10),
  }) async {
    try {
      // Check for existing active tokens (rate limiting)
      final hasActiveToken = await this.hasActiveToken(userId);
      if (hasActiveToken) {
        throw Exception('RATE_LIMITED: User already has an active password reset token');
      }

      // Generate secure token
      final plainToken = _generateSecureToken();
      
      // Hash the token for secure storage
      final tokenHash = sha256.convert(utf8.encode(plainToken)).bytes;
      
      // Calculate expiration time
      final expiresAt = DateTime.now().add(expiration);
      
      // Insert token into database
      await _db.execute(
        '''
        INSERT INTO password_reset_tokens (user_id, token_hash, type, expires_at)
        VALUES (@user_id, @token_hash, @type, @expires_at)
        ''',
        {
          'user_id': userId,
          'token_hash': tokenHash,
          'type': type.value,
          'expires_at': expiresAt.toIso8601String(),
        },
      );

      debugPrint('Created password reset token for user $userId (type: ${type.value})');
      
      return plainToken;
    } catch (e) {
      debugPrint('Error creating password reset token: $e');
      rethrow;
    }
  }

  /// Validates a password reset token
  /// Returns the token record if valid, null otherwise
  Future<PasswordResetToken?> validateToken(String plainToken) async {
    try {
      // Hash the provided token
      final tokenHash = sha256.convert(utf8.encode(plainToken)).bytes;
      
      // Look up token in database
      final results = await _db.query(
        '''
        SELECT * FROM password_reset_tokens 
        WHERE token_hash = @token_hash 
        AND NOT used 
        AND expires_at > NOW()
        LIMIT 1
        ''',
        {'token_hash': tokenHash},
      );

      if (results.isEmpty) {
        debugPrint('Password reset token validation failed: invalid or expired token');
        return null;
      }

      final tokenData = results.first;
      return PasswordResetToken.fromMap(tokenData);
    } catch (e) {
      debugPrint('Error validating password reset token: $e');
      return null;
    }
  }

  /// Marks a password reset token as used
  Future<bool> markTokenAsUsed(String plainToken) async {
    try {
      // Hash the provided token
      final tokenHash = sha256.convert(utf8.encode(plainToken)).bytes;
      
      // Update token as used
      final rowsAffected = await _db.execute(
        '''
        UPDATE password_reset_tokens 
        SET used = true 
        WHERE token_hash = @token_hash 
        AND NOT used 
        AND expires_at > NOW()
        ''',
        {'token_hash': tokenHash},
      );

      final success = rowsAffected > 0;
      if (success) {
        debugPrint('Marked password reset token as used');
      } else {
        debugPrint('Failed to mark token as used: token not found or already used');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error marking password reset token as used: $e');
      return false;
    }
  }

  /// Checks if a user has an active (unused, non-expired) password reset token
  Future<bool> hasActiveToken(String userId) async {
    try {
      final results = await _db.query(
        '''
        SELECT COUNT(*) as count FROM password_reset_tokens 
        WHERE user_id = @user_id 
        AND NOT used 
        AND expires_at > NOW()
        ''',
        {'user_id': userId},
      );

      final count = (results.first['count'] as int?) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('Error checking for active password reset token: $e');
      return false;
    }
  }

  /// Gets the most recent active password reset token for a user
  Future<PasswordResetToken?> getActiveToken(String userId) async {
    try {
      final results = await _db.query(
        '''
        SELECT * FROM password_reset_tokens 
        WHERE user_id = @user_id 
        AND NOT used 
        AND expires_at > NOW()
        ORDER BY created_at DESC
        LIMIT 1
        ''',
        {'user_id': userId},
      );

      if (results.isEmpty) {
        return null;
      }

      return PasswordResetToken.fromMap(results.first);
    } catch (e) {
      debugPrint('Error getting active password reset token: $e');
      return null;
    }
  }

  /// Cleans up expired password reset tokens
  /// Should be called periodically to maintain database hygiene
  Future<int> cleanupExpiredTokens() async {
    try {
      final rowsAffected = await _db.execute(
        'DELETE FROM password_reset_tokens WHERE expires_at <= NOW()',
      );

      if (rowsAffected > 0) {
        debugPrint('Cleaned up $rowsAffected expired password reset tokens');
      }
      
      return rowsAffected;
    } catch (e) {
      debugPrint('Error cleaning up expired password reset tokens: $e');
      return 0;
    }
  }

  /// Invalidates all active tokens for a user
  /// Useful when user successfully resets password or requests cancellation
  Future<int> invalidateUserTokens(String userId) async {
    try {
      final rowsAffected = await _db.execute(
        '''
        UPDATE password_reset_tokens 
        SET used = true 
        WHERE user_id = @user_id 
        AND NOT used 
        AND expires_at > NOW()
        ''',
        {'user_id': userId},
      );

      if (rowsAffected > 0) {
        debugPrint('Invalidated $rowsAffected active password reset tokens for user $userId');
      }
      
      return rowsAffected;
    } catch (e) {
      debugPrint('Error invalidating password reset tokens for user: $e');
      return 0;
    }
  }

  /// Generates a cryptographically secure token
  /// For email: 32-character alphanumeric token
  /// For SMS: 6-digit numeric code
  String _generateSecureToken({PasswordResetType type = PasswordResetType.email}) {
    final random = Random.secure();
    
    if (type == PasswordResetType.sms) {
      // Generate 6-digit code for SMS
      return random.nextInt(1000000).toString().padLeft(6, '0');
    } else {
      // Generate 32-character token for email
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
    }
  }

  /// Gets token statistics for monitoring/debugging
  Future<Map<String, int>> getTokenStats() async {
    try {
      final results = await _db.query(
        '''
        SELECT 
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE NOT used AND expires_at > NOW()) as active,
          COUNT(*) FILTER (WHERE used) as used,
          COUNT(*) FILTER (WHERE expires_at <= NOW() AND NOT used) as expired
        FROM password_reset_tokens
        ''',
      );

      if (results.isEmpty) {
        return {'total': 0, 'active': 0, 'used': 0, 'expired': 0};
      }

      final row = results.first;
      return {
        'total': (row['total'] as int?) ?? 0,
        'active': (row['active'] as int?) ?? 0,
        'used': (row['used'] as int?) ?? 0,
        'expired': (row['expired'] as int?) ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting password reset token stats: $e');
      return {'total': 0, 'active': 0, 'used': 0, 'expired': 0};
    }
  }
}
