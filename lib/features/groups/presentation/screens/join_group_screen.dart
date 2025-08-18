import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/group_service.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _joining = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid == null) {
        _snack('User not ready.');
        return;
      }
      final ok = await GroupService().joinByInviteCode(userId: uid, inviteCode: _codeCtrl.text.trim());
      if (!mounted) return;
      if (ok) {
        _snack('Joined group successfully.');
        Navigator.of(context).pop();
      } else {
        _snack('Invalid code or join failed.');
      }
    } finally {
      if (mounted) setState(() => _joining = false);
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
        title: const Text('Join Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: 'Invite Code'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid code' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _joining ? null : _submit,
                child: _joining
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

