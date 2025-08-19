import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/features/security/services/security_service.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/audit/audit_log_service.dart';
import 'package:savessa/features/security/services/security_prefs_service.dart';
import 'package:savessa/features/security/services/biometric_service.dart';

import 'package:savessa/shared/widgets/screen_scaffold.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  bool _loading = false;
  bool _totpEnabled = false;
  bool _smsEnabled = false;
  bool _emailEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadState());
  }

  Future<void> _loadState() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.postgresUserId;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final st = await SecurityService().getSecurityState(uid) ?? {};
      setState(() {
        _totpEnabled = (st['totp_enabled'] == true);
        _smsEnabled = (st['sms_enabled'] == true);
        _emailEnabled = (st['email_enabled'] == true);
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool> _biometricGateIfRequired() async {
    final prefs = Provider.of<SecurityPrefsService>(context, listen: false);
    if (!prefs.requireBiometric) return true;
    // Capture messenger before async gap to avoid context-after-await lint
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await BiometricService().authenticate(reason: 'Authenticate to change 2FA settings');
    if (!ok) {
      messenger?.showSnackBar(const SnackBar(content: Text('Authentication required.')));
    }
    return ok;
  }

  Future<void> _disable(String method) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.postgresUserId;
    if (uid == null) return;

    // Optional biometric gate
    final proceed = await _biometricGateIfRequired();
    if (!proceed) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: Text('Are you sure you want to disable $method 2FA?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disable')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      final sec = SecurityService();
      switch (method) {
        case 'TOTP':
          await sec.disableTotp(userId: uid);
          await AuditLogService().logAction(userId: uid, action: 'disable_totp', targetType: 'user', targetId: uid);
          _totpEnabled = false;
          break;
        case 'SMS':
          await sec.disableSms2fa(userId: uid);
          await AuditLogService().logAction(userId: uid, action: 'disable_sms_2fa', targetType: 'user', targetId: uid);
          _smsEnabled = false;
          break;
        case 'Email':
          await sec.disableEmail2fa(userId: uid);
          await AuditLogService().logAction(userId: uid, action: 'disable_email_2fa', targetType: 'user', targetId: uid);
          _emailEnabled = false;
          break;
      }
      if (mounted) setState(() {});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Two-Factor Authentication',
      showBackHomeFab: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage your 2FA methods. Enable or disable as needed.'),
                  const SizedBox(height: 12),
SwitchListTile(
                    secondary: const Icon(IconMapping.qr),
                    title: const Text('Authenticator App (TOTP)'),
                    subtitle: const Text('Generate codes using an authenticator app'),
                    value: _totpEnabled,
                    onChanged: (v) async {
                      final router = GoRouter.of(context);
                      if (v) {
                        if (await _biometricGateIfRequired()) {
                          router.go('/settings/two-factor/totp');
                        }
                      } else {
                        await _disable('TOTP');
                      }
                    },
                  ),
SwitchListTile(
                    secondary: const Icon(IconMapping.phone),
                    title: const Text('SMS OTP'),
                    subtitle: const Text('Receive one-time codes by SMS'),
                    value: _smsEnabled,
                    onChanged: (v) async {
                      final router = GoRouter.of(context);
                      if (v) {
                        if (await _biometricGateIfRequired()) {
                          router.go('/settings/two-factor/otp', extra: {'channel': 'sms'});
                        }
                      } else {
                        await _disable('SMS');
                      }
                    },
                  ),
SwitchListTile(
                    secondary: const Icon(IconMapping.email),
                    title: const Text('Email OTP'),
                    subtitle: const Text('Receive one-time codes by email'),
                    value: _emailEnabled,
                    onChanged: (v) async {
                      final router = GoRouter.of(context);
                      if (v) {
                        if (await _biometricGateIfRequired()) {
                          router.go('/settings/two-factor/otp', extra: {'channel': 'email'});
                        }
                      } else {
                        await _disable('Email');
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For security, you may be asked to reauthenticate when changing 2FA settings.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }
}
