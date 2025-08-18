import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
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
      final group = await GroupService().createGroup(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        createdBy: uid,
      );
      if (!mounted) return;
      if (group != null) {
        _snack('Group created. Code: ${group['invite_code']}');
        Navigator.of(context).pop();
      } else {
        _snack('Failed to create group.');
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
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a group name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

