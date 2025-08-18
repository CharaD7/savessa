import 'package:savessa/services/database/database_service.dart';

enum MemberPayStatus { paid, pending, overdue }

class MemberService {
  final DatabaseService _db = DatabaseService();

  Future<List<Map<String, dynamic>>> fetchMembers(String groupId) async {
    try {
      final rows = await _db.query(
        'SELECT gm.user_id, gm.role, u.first_name, u.last_name, u.phone FROM group_members gm JOIN users u ON u.id = gm.user_id WHERE gm.group_id = @gid ORDER BY u.first_name',
        {'gid': groupId},
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<MemberPayStatus> computeStatusForCurrentPeriod(String groupId, String userId, {required num requiredAmount, required DateTime now, int graceDays = 5}) async {
    try {
      final rows = await _db.query(
        """
        SELECT COALESCE(SUM(amount),0) AS total
        FROM contributions
        WHERE group_id = @gid
          AND user_id = @uid
          AND date >= date_trunc('month', CURRENT_DATE)
          AND date <  (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month')
        """,
        {'gid': groupId, 'uid': userId},
      );
      final total = (rows.first['total'] ?? 0) as num;
      if (total >= requiredAmount) return MemberPayStatus.paid;
      // overdue if past day 28 + grace
      final dueDay = DateTime(now.year, now.month, 28).add(Duration(days: graceDays));
      if (now.isAfter(dueDay)) return MemberPayStatus.overdue;
      return MemberPayStatus.pending;
    } catch (_) {
      return MemberPayStatus.pending;
    }
  }
}
