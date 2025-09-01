import 'dart:convert';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'package:savessa/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _env = EnvConfig();

  Future<void> sendEmailOtp({required String recipient, required String code}) async {
    try {
      if (_env.smtpHost.isEmpty || _env.smtpUsername.isEmpty || _env.smtpPassword.isEmpty) {
        // No SMTP configured; silently no-op for local dev
        return;
      }
      final server = SmtpServer(
        _env.smtpHost,
        port: _env.smtpPort,
        username: _env.smtpUsername,
        password: _env.smtpPassword,
        ssl: !_env.smtpUseTls && _env.smtpPort == 465,
        ignoreBadCertificate: false,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_env.emailFromAddress.isEmpty ? _env.smtpUsername : _env.emailFromAddress, _env.emailFromName)
        ..recipients.add(recipient)
        ..subject = '${_env.appName} verification code'
        ..text = 'Your ${_env.appName} verification code is $code. It expires in 10 minutes.';

      await send(message, server);
    } catch (_) {
      // swallow failures; UI will still show generic error from caller if needed
    }
  }

  /// Sends a password reset email with token
  Future<void> sendPasswordResetEmail({
    required String recipient, 
    required String resetToken
  }) async {
    try {
      if (_env.smtpHost.isEmpty || _env.smtpUsername.isEmpty || _env.smtpPassword.isEmpty) {
        // No SMTP configured; silently no-op for local dev
        return;
      }
      
      final server = SmtpServer(
        _env.smtpHost,
        port: _env.smtpPort,
        username: _env.smtpUsername,
        password: _env.smtpPassword,
        ssl: !_env.smtpUseTls && _env.smtpPort == 465,
        ignoreBadCertificate: false,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_env.emailFromAddress.isEmpty ? _env.smtpUsername : _env.emailFromAddress, _env.emailFromName)
        ..recipients.add(recipient)
        ..subject = '${_env.appName} - Password Reset Request'
        ..text = _buildPasswordResetTextEmail(resetToken)
        ..html = _buildPasswordResetHtmlEmail(resetToken);

      await send(message, server);
    } catch (_) {
      // swallow failures; UI will still show generic error from caller if needed
    }
  }

  /// Sends a password reset confirmation email
  Future<void> sendPasswordResetConfirmation({required String recipient}) async {
    try {
      if (_env.smtpHost.isEmpty || _env.smtpUsername.isEmpty || _env.smtpPassword.isEmpty) {
        // No SMTP configured; silently no-op for local dev
        return;
      }
      
      final server = SmtpServer(
        _env.smtpHost,
        port: _env.smtpPort,
        username: _env.smtpUsername,
        password: _env.smtpPassword,
        ssl: !_env.smtpUseTls && _env.smtpPort == 465,
        ignoreBadCertificate: false,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_env.emailFromAddress.isEmpty ? _env.smtpUsername : _env.emailFromAddress, _env.emailFromName)
        ..recipients.add(recipient)
        ..subject = '${_env.appName} - Password Reset Successfully'
        ..text = _buildPasswordResetConfirmationTextEmail()
        ..html = _buildPasswordResetConfirmationHtmlEmail();

      await send(message, server);
    } catch (_) {
      // swallow failures; UI will still show generic error from caller if needed
    }
  }

  /// Builds the plain text version of the password reset email
  String _buildPasswordResetTextEmail(String resetToken) {
    return '''
Hello,

We received a request to reset your ${_env.appName} account password.

Your password reset code is: $resetToken

This code will expire in 10 minutes for your security.

If you didn't request this password reset, please ignore this email. Your password will remain unchanged.

For security reasons, please do not share this code with anyone.

Best regards,
The ${_env.appName} Team
''';
  }

  /// Builds the HTML version of the password reset email
  String _buildPasswordResetHtmlEmail(String resetToken) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${_env.appName} Password Reset</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4B2E83, #7B4397); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .token-box { background: white; border: 2px solid #4B2E83; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }
        .token { font-size: 24px; font-weight: bold; color: #4B2E83; letter-spacing: 2px; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .footer { text-align: center; color: #666; margin-top: 20px; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${_env.appName}</h1>
            <h2>Password Reset Request</h2>
        </div>
        <div class="content">
            <p>Hello,</p>
            
            <p>We received a request to reset your ${_env.appName} account password.</p>
            
            <div class="token-box">
                <p><strong>Your password reset code is:</strong></p>
                <div class="token">$resetToken</div>
            </div>
            
            <p><strong>Important:</strong></p>
            <ul>
                <li>This code will expire in <strong>10 minutes</strong> for your security</li>
                <li>Enter this code in the ${_env.appName} app to reset your password</li>
                <li>Do not share this code with anyone</li>
            </ul>
            
            <div class="warning">
                <strong>⚠️ Security Notice:</strong> If you didn't request this password reset, please ignore this email. Your password will remain unchanged.
            </div>
            
            <p>If you continue to have problems, please contact our support team.</p>
            
            <p>Best regards,<br>The ${_env.appName} Team</p>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Builds the plain text version of the password reset confirmation email
  String _buildPasswordResetConfirmationTextEmail() {
    return '''
Hello,

This email confirms that your ${_env.appName} account password has been successfully reset.

If you didn't make this change, please contact our support team immediately.

For your security:
- Your account has been secured with the new password
- All active sessions have been terminated
- You'll need to log in again with your new password

Best regards,
The ${_env.appName} Team
''';
  }

  /// Builds the HTML version of the password reset confirmation email
  String _buildPasswordResetConfirmationHtmlEmail() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${_env.appName} Password Reset Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4B2E83, #7B4397); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .success-box { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 4px; margin: 20px 0; text-align: center; }
        .info-box { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .footer { text-align: center; color: #666; margin-top: 20px; font-size: 12px; }
        .icon { font-size: 48px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${_env.appName}</h1>
            <h2>Password Reset Confirmation</h2>
        </div>
        <div class="content">
            <div class="success-box">
                <div class="icon">✅</div>
                <h3>Password Reset Successful!</h3>
                <p>Your ${_env.appName} account password has been successfully reset.</p>
            </div>
            
            <p>Hello,</p>
            
            <p>This email confirms that your account password has been changed. Your account is now secured with your new password.</p>
            
            <div class="info-box">
                <strong>For your security:</strong>
                <ul style="margin: 10px 0;">
                    <li>All active sessions have been terminated</li>
                    <li>You'll need to log in again with your new password</li>
                    <li>Your account is now protected with the updated credentials</li>
                </ul>
            </div>
            
            <p><strong>⚠️ Important:</strong> If you didn't make this change, please contact our support team immediately at support@${_env.appName.toLowerCase()}.com</p>
            
            <p>Thank you for using ${_env.appName}!</p>
            
            <p>Best regards,<br>The ${_env.appName} Team</p>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
''';
  }
}

