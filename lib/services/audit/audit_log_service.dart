import 'dart:convert';
import 'package:http/http.dart' as http;
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
      await _db.execute(
        'INSERT INTO admin_audit_log (user_id, action, target_type, target_id, metadata, ip) VALUES (@uid, @a, @tt, @tid, @meta::jsonb, @ip)',
        {
          'uid': userId,
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
    try {
      final r = await http.get(Uri.parse('https://api.ipify.org?format=text'));
      if (r.statusCode == 200) return r.body.trim();
    } catch (_) {}
    return '0.0.0.0';
  }
}
