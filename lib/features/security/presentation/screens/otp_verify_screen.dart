import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:savessa/features/security/services/security_service.dart';
import 'package:savessa/services/audit/audit_log_service.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/core/constants/icon_mapping.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String channel; // 'sms' or 'email'
  const OtpVerifyScreen({super.key, required this.channel});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _controller = TextEditingController();
  bool _sent = false;
  bool _verifying = false;
  String? _verificationId;
  int? _forceResendToken;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (widget.channel == 'sms') {
      final auth = Provider.of<AuthService>(context, listen: false);
      final phone = auth.currentUser?.phoneNumber;
      if (phone == null || phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number linked to your account.')));
        return;
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _forceResendToken,
        verificationCompleted: (cred) async {
          // Avoid auto-signin; let user verify explicitly for 2FA enabling
        },
        verificationFailed: (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send SMS: ${e.code}')));
        },
        codeSent: (verificationId, forceResendingToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _forceResendToken = forceResendingToken;
            _sent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS code sent.')));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
      return;
    }

    // Email: ask backend to send a code
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.postgresUserId;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not ready. Try again.')));
      return;
    }
    try {
      await SecurityService().requestEmailOtp(userId: uid);
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email code sent.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send email code.')));
    }
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.postgresUserId;
    try {
      if (widget.channel == 'sms') {
        if (_verificationId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request a code first.')));
          return;
        }
        final smsCode = _controller.text.trim();
        final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await user.linkWithCredential(cred);
          } catch (_) {
            try {
              await user.reauthenticateWithCredential(cred);
            } catch (_) {}
          }
        } else {
          await FirebaseAuth.instance.signInWithCredential(cred);
        }
        if (uid != null) {
          await SecurityService().enableSms2fa(userId: uid);
          // audit
          // ignore: unawaited_futures
          AuditLogService().logAction(userId: uid, action: 'enable_sms_2fa', targetType: 'user', targetId: uid);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS verified. 2FA enabled.')));
        return;
      }

      // Email
      if (uid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not ready. Try again.')));
        return;
      }
      final code = _controller.text.trim();
      final ok = await SecurityService().verifyEmailOtp(userId: uid, code: code);
      if (!mounted) return;
      if (ok) {
        await SecurityService().enableEmail2fa(userId: uid);
        // ignore: unawaited_futures
        AuditLogService().logAction(userId: uid, action: 'enable_email_2fa', targetType: 'user', targetId: uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verified. 2FA enabled.')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code.')));
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.channel == 'sms' ? 'Verify SMS OTP' : 'Verify Email OTP';
    return Scaffold(
appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channel == 'sms'
                ? 'We will send a code to your phone number.'
                : 'We will send a code to your email.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Enter 6-digit code'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sent ? null : _sendCode,
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 12),
FilledButton.icon(
              onPressed: _verifying ? null : _verify,
              icon: _verifying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(IconMapping.checkCircle),
              label: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

