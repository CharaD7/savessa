import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/contribution_service.dart';
import 'package:savessa/services/groups/active_group_service.dart';

class AddSavingsScreen extends StatefulWidget {
  const AddSavingsScreen({super.key});

  @override
  State<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends State<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill amount if provided via navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['amount'] is String) {
        _amountCtrl.text = args['amount'] as String;
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid == null) {
        _snack('User not ready.');
        return;
      }
      // Use active group id
final active = Provider.of<ActiveGroupService>(context, listen: false);
      final groupId = active.groupId;
      if (groupId == null) {
        _snack('Select a group first.');
        return;
      }
      final amount = double.parse(_amountCtrl.text.trim());
      final ok = await ContributionService().addContribution(groupId: groupId, userId: uid, amount: amount);
      if (!mounted) return;
      if (ok) {
        _snack('Contribution added.');
        Navigator.of(context).pop();
      } else {
        _snack('Failed to add contribution.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: const Text('Add Savings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (GHS)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
