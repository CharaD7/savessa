import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;

import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/user/user_data_service.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/services/audit/audit_log_service.dart';
import 'package:savessa/core/constants/icon_mapping.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _otherNamesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _otherNamesCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = Provider.of<UserDataService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    String? uuid = session.id ?? auth.postgresUserId; // Postgres UUID
    String? email = session.user?['email']?.toString() ?? auth.currentUser?.email;

    bool looksLikeUuid(String s) {
      final re = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      return re.hasMatch(s);
    }

    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      Map<String, dynamic>? row;
      if (uuid != null && uuid.isNotEmpty && looksLikeUuid(uuid)) {
        try {
          row = await db.getUserById(uuid);
        } catch (_) {
          row = null; // ignore and try fallbacks
        }
      }
      if (row == null && (email != null && email.isNotEmpty)) {
        try { row = await db.getUserByEmail(email); } catch (_) {}
      }
      if (row == null && auth.currentUser?.phoneNumber != null && auth.currentUser!.phoneNumber!.isNotEmpty) {
        try { row = await db.getUserByEmailOrPhone(auth.currentUser!.phoneNumber!); } catch (_) {}
      }
      if (!mounted) return;
      if (row == null) {
        _firstNameCtrl.text = (session.user?['first_name'] ?? '').toString();
        _lastNameCtrl.text = (session.user?['last_name'] ?? '').toString();
        _otherNamesCtrl.text = (session.user?['other_names'] ?? '').toString();
        _phoneCtrl.text = (session.user?['phone'] ?? '').toString();
        _emailCtrl.text = (session.user?['email'] ?? (auth.currentUser?.email ?? '')).toString();
      } else {
        _firstNameCtrl.text = (row['first_name'] ?? '').toString();
        _lastNameCtrl.text = (row['last_name'] ?? '').toString();
        _otherNamesCtrl.text = (row['other_names'] ?? '').toString();
        _phoneCtrl.text = (row['phone'] ?? '').toString();
        _emailCtrl.text = (row['email'] ?? '').toString();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load user profile')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _resolveUserUuid() async {
    final session = Provider.of<UserDataService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    // Try session id (UUID)
    final sessId = session.id;
    if (sessId != null && sessId.isNotEmpty) return sessId;
    // Try auth service id (UUID)
    final authId = auth.postgresUserId;
    if (authId != null && authId.isNotEmpty) return authId;
    // Fallback: resolve by email
    final email = session.user?['email']?.toString() ?? auth.currentUser?.email;
    if (email != null && email.isNotEmpty) {
      try {
        final row = await DatabaseService().getUserByEmail(email);
        final rid = row?['id']?.toString();
        if (rid != null && rid.isNotEmpty) return rid;
      } catch (_) {}
    }
    // Fallback: resolve by phone
    final phone = auth.currentUser?.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      try {
        final row = await DatabaseService().getUserByEmailOrPhone(phone);
        final rid = row?['id']?.toString();
        if (rid != null && rid.isNotEmpty) return rid;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _confirmAndSaveField(String field, String value) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            const Icon(IconMapping.infoOutline, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Confirm changes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to update "$field" to:'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(ctx).dividerColor.withValues(alpha: 0.3)),
              ),
              child: Text(value, style: Theme.of(ctx).textTheme.titleMedium),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      final uid = await _resolveUserUuid();
      if (uid == null) {
        throw Exception('Unable to determine user ID');
      }
      final sanitized = value.trim();
      await db.updateUserProfile(
        userId: uid,
        firstName: field == 'first_name' ? sanitized : null,
        lastName: field == 'last_name' ? sanitized : null,
        otherNames: field == 'other_names' ? sanitized : null,
        phone: field == 'phone' ? sanitized : null,
        email: field == 'email' ? sanitized : null,
      );
      try {
        await AuditLogService().logAction(
          userId: auth.postgresUserId!,
          action: 'profile_update',
          metadata: {field: value},
        );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final session = Provider.of<UserDataService>(context);
    final u = auth.currentUser;
    final userUuid = session.id ?? auth.postgresUserId;
    return ScreenScaffold(
      title: 'Profile',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      showBackHomeFab: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with role chip
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: const Icon(IconMapping.profile, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (u?.email?.isNotEmpty ?? false)
                          Text(
                            u!.email!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (u?.email?.isNotEmpty ?? false) const SizedBox(height: 6),
                        if (userUuid != null && userUuid.isNotEmpty) ...[
                          SelectableText(
                            userUuid,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Builder(builder: (context) {
                          final roleRaw = session.role;
                          final isManager = roleRaw == 'admin';
                          final label = isManager ? 'Savings Manager' : 'Savings Contributor';
                          final color = isManager ? Colors.deepPurple : Colors.teal;
                          final icon = isManager ? IconMapping.award : IconMapping.person;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: color, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: _loading ? null : _load,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role: ${session.role}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _EditableProfileRow(
              label: 'First Name',
              initialValue: _firstNameCtrl.text,
              onSave: (val) => _confirmAndSaveField('first_name', val),
            ),
            const SizedBox(height: 8),
            _EditableProfileRow(
              label: 'Last Name',
              initialValue: _lastNameCtrl.text,
              onSave: (val) => _confirmAndSaveField('last_name', val),
            ),
            const SizedBox(height: 8),
            _EditableProfileRow(
              label: 'Other Names',
              initialValue: _otherNamesCtrl.text,
              onSave: (val) => _confirmAndSaveField('other_names', val),
            ),
            const SizedBox(height: 8),
            _EditableProfileRow(
              label: 'Phone',
              initialValue: _phoneCtrl.text,
              keyboardType: TextInputType.phone,
              onSave: (val) => _confirmAndSaveField('phone', val),
            ),
            const SizedBox(height: 8),
            _EditableProfileRow(
              label: 'Email',
              initialValue: _emailCtrl.text,
              keyboardType: TextInputType.emailAddress,
              onSave: (val) => _confirmAndSaveField('email', val),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableProfileRow extends StatefulWidget {
  final String label;
  final String initialValue;
  final TextInputType? keyboardType;
  final Future<void> Function(String) onSave;
  const _EditableProfileRow({required this.label, required this.initialValue, required this.onSave, this.keyboardType});

  @override
  State<_EditableProfileRow> createState() => _EditableProfileRowState();
}

class _EditableProfileRowState extends State<_EditableProfileRow> {
  late TextEditingController _ctrl;
  bool _editing = false;
  String _original = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _original = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant _EditableProfileRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_editing) {
      _ctrl.text = widget.initialValue;
      _original = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changed = _ctrl.text != _original;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (_editing)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: widget.keyboardType,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  )
                else
                  Text(
                    _ctrl.text.isEmpty ? '-' : _ctrl.text,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_editing && changed)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await widget.onSave(_ctrl.text.trim());
                    setState(() {
                      _original = _ctrl.text;
                      _editing = false;
                    });
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save'),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    if (_editing) {
                      _ctrl.text = _original; // revert changes
                    }
                    _editing = !_editing;
                  });
                },
                icon: Icon(_editing ? Icons.close : Icons.edit, size: 18),
                label: Text(_editing ? 'Cancel' : 'Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
