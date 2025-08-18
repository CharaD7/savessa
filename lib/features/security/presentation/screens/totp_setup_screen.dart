import 'dart:math';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/features/security/services/security_service.dart';

class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  late String _secret;
  final _issuer = 'Savessa';
  final String _account = 'user@example.com';
  String? _lastCode;
  final _controller = TextEditingController();
  bool _verified = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _secret = _generateBase32Secret();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _generateBase32Secret({int length = 32}) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rnd = Random.secure();
    return List.generate(length, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }

  String _uri() {
    final label = Uri.encodeComponent(_account);
    final issuer = Uri.encodeComponent(_issuer);
    return 'otpauth://totp/$label?secret=$_secret&issuer=$issuer&algorithm=SHA1&digits=6&period=30';
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      _snack('Enter the 6-digit code from your authenticator app');
      return;
    }
    final current = OTP.generateTOTPCodeString(_secret, DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _lastCode = current;
      _verified = current == code;
    });
    if (_verified) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid == null) {
        _snack('User not ready. Try again.');
        return;
      }
      setState(() => _saving = true);
      try {
        await SecurityService().bindTotpSecret(userId: uid, secret: _secret);
        await SecurityService().enableTotp(userId: uid);
        _snack('TOTP verified. 2FA enabled.');
      } catch (e) {
        _snack('Failed to enable 2FA.');
      } finally {
        setState(() => _saving = false);
      }
    } else {
      _snack('Invalid code. Try again.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Set up Authenticator (TOTP)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan the QR in your authenticator app, then enter the 6-digit code.'),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: _uri(),
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _verify,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify & Enable'),
            ),
            if (_lastCode != null) ...[
              const SizedBox(height: 8),
              Text('Example code (for debug): $_lastCode', style: Theme.of(context).textTheme.bodySmall),
            ]
          ],
        ),
      ),
    );
  }
}

