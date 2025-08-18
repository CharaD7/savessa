import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:savessa/core/config/env_config.dart';

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
}

