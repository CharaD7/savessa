import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/user/user_data_service.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/app_card.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Prefer app session user from UserDataService; fallback to AuthService postgres id
      final session = Provider.of<UserDataService>(context, listen: false);
      String? uid = session.id;
      uid ??= Provider.of<AuthService>(context, listen: false).postgresUserId;
      if (uid == null) {
        setState(() {
          _logs = const [];
        });
      } else {
        final db = DatabaseService();
        final rows = await db.getAuditLogs(userId: uid, limit: 200);
        setState(() {
          _logs = rows;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load activity log: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Activity Log',
      showBackHomeFab: true,
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        )
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No activity yet'))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = _logs[index];
                    final action = (row['action'] ?? '').toString();
                    final ip = (row['ip'] ?? '').toString();
                    final created = (row['created_at'] ?? '').toString();
                    Map<String, dynamic>? meta;
                    try {
                      final m = row['metadata'];
                      if (m is String && m.isNotEmpty) {
                        meta = jsonDecode(m) as Map<String, dynamic>;
                      } else if (m is Map<String, dynamic>) {
                        meta = m;
                      }
                    } catch (_) {}
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          if (meta != null && meta.isNotEmpty)
                            Text(
                              meta.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 4),
                          Text('IP: $ip • $created', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
