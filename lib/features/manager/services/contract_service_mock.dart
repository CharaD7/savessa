import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/features/security/services/biometric_service.dart';
import 'package:savessa/features/security/services/security_prefs_service.dart';
import 'package:savessa/services/audit/audit_log_service.dart';
import 'package:savessa/services/auth/auth_service.dart';

class ContractServiceMock {
  Future<bool> setAutomationEnabled(String groupId, bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return true; // always succeeds in mock
  }
}

Future<void> showSmartContractToggleDialog(BuildContext context, {required String groupId}) async {
  final prefs = Provider.of<SecurityPrefsService>(context, listen: false);
  final auth = Provider.of<AuthService>(context, listen: false);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Enable Automation?'),
        content: const Text('This will enable smart contract automation for group payouts and checks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(IconMapping.lockOpen),
            label: const Text('Enable'),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return;

  if (prefs.requireBiometric) {
    final ok = await BiometricService().authenticate(reason: 'Authenticate to enable smart contracts');
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed.')));
      return;
    }
  }

  final ok = await ContractServiceMock().setAutomationEnabled(groupId, true);
  // ignore: unawaited_futures
  AuditLogService().logAction(
    userId: auth.postgresUserId ?? 'unknown',
    action: 'smart_contract_toggle',
    targetType: 'group',
    targetId: groupId,
    metadata: {'enabled': true, 'result': ok},
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Automation enabled.' : 'Failed to enable.')));
}

