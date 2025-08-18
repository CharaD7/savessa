import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/email/email_service.dart';

class SecurityService {
  final DatabaseService _db = DatabaseService();
  final EmailService _email = EmailService();

  Future<void> bindTotpSecret({required String userId, required String secret}) async {
    // Store secret hashed or encrypted server-side ideally; for demo, store as-is in a secure column
    await _db.execute(
      '''
      INSERT INTO user_security (user_id, totp_secret, totp_enabled, updated_at)
      VALUES (@uid, @sec, false, NOW())
      ON CONFLICT (user_id)
      DO UPDATE SET totp_secret = EXCLUDED.totp_secret, updated_at = NOW()
      ''',
      {'uid': userId, 'sec': secret},
    );
  }

  Future<void> enableTotp({required String userId}) async {
    await _db.execute(
      'UPDATE user_security SET totp_enabled = true, updated_at = NOW() WHERE user_id = @uid',
      {'uid': userId},
    );
  }

  Future<void> disableTotp({required String userId}) async {
    await _db.execute(
      'UPDATE user_security SET totp_enabled = false, updated_at = NOW() WHERE user_id = @uid',
      {'uid': userId},
    );
  }

  Future<Map<String, dynamic>?> getSecurityState(String userId) async {
    final rows = await _db.query('SELECT totp_enabled, sms_enabled, email_enabled FROM user_security WHERE user_id = @uid', {'uid': userId});
    return rows.isNotEmpty ? rows.first : null;
  }

  // Email OTP: generate, store hashed in DB with TTL, and send via SMTP
  Future<void> requestEmailOtp({required String userId}) async {
    // 1) Fetch email for user
    final userRows = await _db.query('SELECT email FROM users WHERE id = @uid', {'uid': userId});
    if (userRows.isEmpty || (userRows.first['email']?.toString().isEmpty ?? true)) {
      throw Exception('No email on file');
    }
    final email = userRows.first['email'].toString();

    // 2) Generate 6-digit numeric code
    final code = _generateOtpCode();

    // 3) Hash and upsert into email_otp_codes with 10 min TTL and attempts reset
    final digestBytes = sha256.convert(utf8.encode(code)).bytes;
    await _db.execute(
      '''
      INSERT INTO email_otp_codes (user_id, code_hash, expires_at, attempts, created_at)
      VALUES (@uid, @hash, NOW() + INTERVAL '10 minutes', 0, NOW())
      ON CONFLICT (user_id)
      DO UPDATE SET code_hash = EXCLUDED.code_hash, expires_at = EXCLUDED.expires_at, attempts = 0, created_at = NOW()
      ''',
      {
        'uid': userId,
        'hash': digestBytes,
      },
    );

    // 4) Send email (non-blocking failure handled inside service)
    await _email.sendEmailOtp(recipient: email, code: code);
  }

  String _generateOtpCode() {
    final rnd = Random.secure();
    final n = rnd.nextInt(1000000); // 0..999999
    return n.toString().padLeft(6, '0');
  }

  Future<bool> verifyEmailOtp({required String userId, required String code}) async {
    final rows = await _db.query(
      'SELECT verify_email_otp(@uid, @code) AS ok',
      {'uid': userId, 'code': code},
    );
    if (rows.isEmpty) return false;
    final ok = rows.first['ok'];
    return ok == true || ok == 1;
  }

  Future<void> enableEmail2fa({required String userId}) async {
    await _db.execute('UPDATE user_security SET email_enabled = true, updated_at = NOW() WHERE user_id = @uid', {'uid': userId});
  }

  Future<void> disableEmail2fa({required String userId}) async {
    await _db.execute('UPDATE user_security SET email_enabled = false, updated_at = NOW() WHERE user_id = @uid', {'uid': userId});
  }

  Future<void> enableSms2fa({required String userId}) async {
    await _db.execute('UPDATE user_security SET sms_enabled = true, updated_at = NOW() WHERE user_id = @uid', {'uid': userId});
  }

  Future<void> disableSms2fa({required String userId}) async {
    await _db.execute('UPDATE user_security SET sms_enabled = false, updated_at = NOW() WHERE user_id = @uid', {'uid': userId});
  }
}

