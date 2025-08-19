import 'dart:convert';
import 'package:savessa/services/database/database_service.dart';

class AuditLogService {
  final DatabaseService _db = DatabaseService();

  Future<void> logAction({
    required String userId,
    required String action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final ip = await _getPublicIp();
      final uidInt = int.tryParse(userId);
      await _db.execute(
        'INSERT INTO admin_audit_log (user_id, action, target_type, target_id, metadata, ip) VALUES (@uid, @a, @tt, @tid, @meta::jsonb, @ip)',
        {
          'uid': uidInt ?? userId,
          'a': action,
          'tt': targetType,
          'tid': targetId,
          'meta': jsonEncode(metadata ?? {}),
          'ip': ip,
        },
      );
    } catch (_) {
      // swallow in client; do not block UI
    }
  }

  Future<String> _getPublicIp() async {
    // Avoid network dependency; return placeholder. If server adds IP via RLS, remove this field entirely.
    return '0.0.0.0';
  }
}
