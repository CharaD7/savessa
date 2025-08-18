import 'package:savessa/services/database/database_service.dart';

class ContributionService {
  final DatabaseService _db = DatabaseService();

  Future<double> totalSavedForGroup(String groupId) async {
    try {
      final rows = await _db.query(
        """
        SELECT COALESCE(SUM(amount),0) AS total
        FROM contributions
        WHERE group_id = @gid
        """,
        {'gid': groupId},
      );
      final total = (rows.first['total'] ?? 0) as num;
      return total.toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> totalForMemberCurrentMonth(String groupId, String userId) async {
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
      return total.toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> monthlyTotals(String groupId, {int monthsBack = 6}) async {
    try {
      final rows = await _db.query(
        """
        SELECT TO_CHAR(date_trunc('month', date), 'YYYY-MM') AS ym, SUM(amount) AS total
        FROM contributions
        WHERE group_id = @gid
          AND date >= (date_trunc('month', CURRENT_DATE) - INTERVAL '5 months')
        GROUP BY 1
        ORDER BY 1 ASC
        """,
        {'gid': groupId},
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> distributionByMember(String groupId) async {
    try {
      final rows = await _db.query(
        '''
        SELECT u.first_name || ' ' || u.last_name AS name, SUM(c.amount) AS total
        FROM contributions c JOIN users u ON u.id = c.user_id
        WHERE c.group_id = @gid
        GROUP BY 1
        ORDER BY total DESC
        ''' ,
        {'gid': groupId},
      );
      return rows;
    } catch (_) {
      return [];
    }
  }
  Future<bool> addContribution({required String groupId, required String userId, required double amount, DateTime? date}) async {
    try {
      await _db.execute(
        '''
        INSERT INTO contributions (group_id, user_id, amount, date)
        VALUES (@gid, @uid, @amt, @dt)
        ''' ,
        {
          'gid': groupId,
          'uid': userId,
          'amt': amount,
          'dt': (date ?? DateTime.now()).toIso8601String(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> recentContributions(String groupId, {int limit = 20}) async {
    try {
      final rows = await _db.query(
        '''
        SELECT c.id, c.user_id, u.first_name, u.last_name, c.amount, c.date
        FROM contributions c
        JOIN users u ON u.id = c.user_id
        WHERE c.group_id = @gid
        ORDER BY c.date DESC
        LIMIT @lim
        ''' ,
        {'gid': groupId, 'lim': limit},
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> recentContributionsForMember(String groupId, String userId, {int limit = 20}) async {
    try {
      final rows = await _db.query(
        '''
        SELECT c.id, c.user_id, c.amount, c.date
        FROM contributions c
        WHERE c.group_id = @gid AND c.user_id = @uid
        ORDER BY c.date DESC
        LIMIT @lim
        ''',
        {'gid': groupId, 'uid': userId, 'lim': limit},
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<double> memberMonthlyRequirement(String groupId) async {
    try {
      final rows = await _db.query(
        '''
        SELECT mg.target_amount AS target, COUNT(gm.user_id) AS members
        FROM monthly_goals mg
        JOIN group_members gm ON gm.group_id = mg.group_id
        WHERE mg.group_id = @gid AND mg.year = EXTRACT(YEAR FROM CURRENT_DATE)::int AND mg.month = EXTRACT(MONTH FROM CURRENT_DATE)::int
        GROUP BY mg.target_amount
        ''',
        {'gid': groupId},
      );
      if (rows.isEmpty) return 0.0;
      final target = (rows.first['target'] ?? 0) as num;
      final members = (rows.first['members'] ?? 1) as num;
      if (members == 0) return 0.0;
      return (target / members).toDouble();
    } catch (_) {
      return 0.0;
    }
  }
}
