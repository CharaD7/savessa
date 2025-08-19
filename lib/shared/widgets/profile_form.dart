import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/validation/email_validator_service.dart';
import 'package:savessa/shared/widgets/app_card.dart';

class ProfileForm extends StatefulWidget {
  final bool isManager;
  final VoidCallback? onSaved;

  const ProfileForm({super.key, this.isManager = false, this.onSaved});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _otherNamesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _otherNamesCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid != null) {
        final db = DatabaseService();
        final row = await db.getUserById(uid);
        if (!mounted) return;
        setState(() {
          _firstNameCtrl.text = (row?['first_name'] ?? '').toString();
          _lastNameCtrl.text = (row?['last_name'] ?? '').toString();
          _otherNamesCtrl.text = (row?['other_names'] ?? '').toString();
          _phoneCtrl.text = (row?['phone'] ?? '').toString();
          _emailCtrl.text = (row?['email'] ?? '').toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid == null) return;
      final db = DatabaseService();
      await db.updateUserProfile(
        userId: uid,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        otherNames: _otherNamesCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      widget.onSaved?.call();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.isManager ? 'Savings Manager' : 'Savings Contributor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(child: Text(roleLabel)),
              ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherNamesCtrl,
                  decoration: const InputDecoration(labelText: 'Other names (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Required';
                    final phoneRe = RegExp(r'^[+0-9][0-9\-\s]{6,}$');
                    return phoneRe.hasMatch(value) ? null : 'Enter a valid phone';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Required';
                    final ok = EmailValidatorService().isValidFormat(value);
                    return ok ? null : 'Enter a valid email';
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

