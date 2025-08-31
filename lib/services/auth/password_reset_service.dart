import 'package:flutter/foundation.dart';
import 'package:savessa/core/models/password_reset_token.dart';
import 'package:savessa/core/repositories/password_reset_token_repository.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/email/email_service.dart';
import 'package:savessa/services/sms/sms_service.dart';
import 'package:savessa/services/security/security_service.dart' as security;
import 'package:savessa/services/audit/audit_log_service.dart';

/// Service for handling password reset functionality
class PasswordResetService {
  static final PasswordResetService _instance = PasswordResetService._internal();
  factory PasswordResetService() => _instance;
  PasswordResetService._internal();

  final PasswordResetTokenRepository _tokenRepository = PasswordResetTokenRepository();
  final DatabaseService _db = DatabaseService();
  final EmailService _emailService = EmailService();
  final SmsService _smsService = SmsService();
  final AuditLogService _auditService = AuditLogService();

  /// Initiates the password reset process
  /// 
  /// [identifier] can be email address or phone number
  /// [type] specifies whether to send via email or SMS
  /// 
  /// Returns true if the reset process was initiated successfully
  Future<PasswordResetResult> initiatePasswordReset({
    required String identifier,
    required PasswordResetType type,
  }) async {
    try {
      debugPrint('Initiating password reset for identifier: $identifier (type: ${type.value})');

      // Step 1: Validate and find user
      final user = await _findUserByIdentifier(identifier, type);
      if (user == null) {
        // For security reasons, don't reveal whether user exists or not
        debugPrint('User not found for identifier: $identifier');
        return PasswordResetResult.success(
          message: 'If an account with that ${type.value} exists, you will receive a reset code shortly.',
        );
      }

      final userId = user['id']?.toString();
      if (userId == null) {
        throw Exception('User ID is null');
      }

      // Step 2: Check rate limiting
      final hasActiveToken = await _tokenRepository.hasActiveToken(userId);
      if (hasActiveToken) {
        debugPrint('Rate limited: User $userId already has an active password reset token');
        return PasswordResetResult.rateLimited(
          message: 'A password reset code has already been sent. Please wait before requesting another.',
        );
      }

      // Step 3: Generate and store secure token
      final plainToken = await _tokenRepository.createToken(
        userId: userId,
        type: type,
        expiration: const Duration(minutes: 10),
      );

      // Step 4: Send token via email or SMS
      final sendSuccess = await _sendResetToken(
        identifier: identifier,
        token: plainToken,
        type: type,
      );

      if (!sendSuccess) {
        // Clean up the token if sending failed
        await _tokenRepository.markTokenAsUsed(plainToken);
        return PasswordResetResult.sendFailed(
          message: 'Failed to send reset code. Please try again.',
        );
      }

      // Step 5: Log audit trail
      try {
        await _auditService.logAction(
          userId: userId,
          action: 'password_reset_requested',
          metadata: {
            'type': type.value,
            'identifier': _maskIdentifier(identifier, type),
          },
        );
      } catch (e) {
        debugPrint('Failed to log audit trail: $e');
        // Don't fail the entire operation for audit logging
      }

      debugPrint('Password reset initiated successfully for user $userId');
      return PasswordResetResult.success(
        message: 'A password reset code has been sent to your ${type.value}.',
      );
    } catch (e) {
      debugPrint('Error initiating password reset: $e');
      return PasswordResetResult.error(
        message: 'An error occurred. Please try again later.',
      );
    }
  }

  /// Validates a password reset token
  /// 
  /// Returns the token if valid, null otherwise
  Future<PasswordResetToken?> validateResetToken(String token) async {
    try {
      final passwordResetToken = await _tokenRepository.validateToken(token);
      
      if (passwordResetToken == null) {
        debugPrint('Password reset token validation failed');
        return null;
      }

      debugPrint('Password reset token validated successfully');
      return passwordResetToken;
    } catch (e) {
      debugPrint('Error validating password reset token: $e');
      return null;
    }
  }

  /// Resets the user's password using a valid token
  /// 
  /// Returns true if the password was reset successfully
  Future<PasswordResetResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      debugPrint('Attempting to reset password with token');

      // Step 1: Validate the token
      final resetToken = await validateResetToken(token);
      if (resetToken == null) {
        return PasswordResetResult.invalidToken(
          message: 'Invalid or expired reset code. Please request a new one.',
        );
      }

      // Step 2: Get user information
      final user = await _db.getUserById(resetToken.userId);
      if (user == null) {
        debugPrint('User not found for token: ${resetToken.userId}');
        return PasswordResetResult.error(
          message: 'User account not found.',
        );
      }

      // Step 3: Update the password
      final passwordHash = security.SecurityService.hashPassword(newPassword);
      await _db.execute(
        'UPDATE users SET password_hash = @password_hash, updated_at = NOW() WHERE id = @user_id',
        {
          'password_hash': passwordHash,
          'user_id': resetToken.userId,
        },
      );

      // Step 4: Mark the token as used
      await _tokenRepository.markTokenAsUsed(token);

      // Step 5: Invalidate any other active tokens for this user
      await _tokenRepository.invalidateUserTokens(resetToken.userId);

      // Step 6: Send confirmation email
      final userEmail = user['email']?.toString();
      if (userEmail != null && userEmail.isNotEmpty) {
        try {
          await _emailService.sendPasswordResetConfirmation(recipient: userEmail);
        } catch (e) {
          debugPrint('Failed to send password reset confirmation email: $e');
          // Don't fail the entire operation for email sending
        }
      }

      // Step 7: Log audit trail
      try {
        await _auditService.logAction(
          userId: resetToken.userId,
          action: 'password_reset_completed',
          metadata: {
            'type': resetToken.type,
            'reset_method': resetToken.type,
          },
        );
      } catch (e) {
        debugPrint('Failed to log audit trail: $e');
        // Don't fail the entire operation for audit logging
      }

      debugPrint('Password reset completed successfully for user ${resetToken.userId}');
      return PasswordResetResult.success(
        message: 'Your password has been reset successfully. You can now log in with your new password.',
      );
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return PasswordResetResult.error(
        message: 'An error occurred while resetting your password. Please try again.',
      );
    }
  }

  /// Finds a user by email or phone identifier
  Future<Map<String, dynamic>?> _findUserByIdentifier(
    String identifier, 
    PasswordResetType type,
  ) async {
    try {
      if (type == PasswordResetType.email) {
        return await _db.getUserByEmail(identifier);
      } else {
        return await _db.getUserByPhone(identifier);
      }
    } catch (e) {
      debugPrint('Error finding user by identifier: $e');
      return null;
    }
  }

  /// Sends the reset token via email or SMS
  Future<bool> _sendResetToken({
    required String identifier,
    required String token,
    required PasswordResetType type,
  }) async {
    try {
      if (type == PasswordResetType.email) {
        await _emailService.sendPasswordResetEmail(
          recipient: identifier,
          resetToken: token,
        );
        return true;
      } else {
        return await _smsService.sendPasswordResetSMS(
          phoneNumber: identifier,
          resetCode: token,
        );
      }
    } catch (e) {
      debugPrint('Error sending reset token: $e');
      return false;
    }
  }

  /// Masks an identifier for logging purposes
  String _maskIdentifier(String identifier, PasswordResetType type) {
    if (type == PasswordResetType.email) {
      final parts = identifier.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        final maskedUsername = username.length > 2
            ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
            : username;
        return '$maskedUsername@$domain';
      }
    } else {
      // Mask phone number: show first 3 and last 2 digits
      if (identifier.length > 5) {
        final start = identifier.substring(0, 3);
        final end = identifier.substring(identifier.length - 2);
        final middle = '*' * (identifier.length - 5);
        return '$start$middle$end';
      }
    }
    return identifier;
  }

  /// Gets password reset statistics
  Future<Map<String, int>> getResetStats() async {
    return await _tokenRepository.getTokenStats();
  }

  /// Cleans up expired password reset tokens
  Future<int> cleanupExpiredTokens() async {
    return await _tokenRepository.cleanupExpiredTokens();
  }
}

/// Result class for password reset operations
class PasswordResetResult {
  final bool success;
  final String message;
  final PasswordResetResultType type;

  const PasswordResetResult({
    required this.success,
    required this.message,
    required this.type,
  });

  factory PasswordResetResult.success({required String message}) {
    return PasswordResetResult(
      success: true,
      message: message,
      type: PasswordResetResultType.success,
    );
  }

  factory PasswordResetResult.rateLimited({required String message}) {
    return PasswordResetResult(
      success: false,
      message: message,
      type: PasswordResetResultType.rateLimited,
    );
  }

  factory PasswordResetResult.sendFailed({required String message}) {
    return PasswordResetResult(
      success: false,
      message: message,
      type: PasswordResetResultType.sendFailed,
    );
  }

  factory PasswordResetResult.invalidToken({required String message}) {
    return PasswordResetResult(
      success: false,
      message: message,
      type: PasswordResetResultType.invalidToken,
    );
  }

  factory PasswordResetResult.error({required String message}) {
    return PasswordResetResult(
      success: false,
      message: message,
      type: PasswordResetResultType.error,
    );
  }
}

/// Types of password reset results
enum PasswordResetResultType {
  success,
  rateLimited,
  sendFailed,
  invalidToken,
  error,
}
