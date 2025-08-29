import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'group_model.dart';

/// Contribution data model that matches the database schema
class ContributionModel extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final double amount;
  final DateTime date;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user; // Optional populated user data
  final GroupModel? group; // Optional populated group data

  const ContributionModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.group,
  });

  /// Create ContributionModel from database Map
  factory ContributionModel.fromMap(Map<String, dynamic> map, {UserModel? user, GroupModel? group}) {
    return ContributionModel(
      id: map['id']?.toString() ?? '',
      groupId: map['group_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      status: map['status']?.toString() ?? 'recorded',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      user: user,
      group: group,
    );
  }

  /// Convert ContributionModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0], // Store as date only
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Format amount as GHS currency
  String get formattedAmount => 'GHS ${amount.toStringAsFixed(2)}';

  /// Get display name for the contributor
  String get contributorName => user?.displayName ?? 'User $userId';

  /// Get display name for the group
  String get groupName => group?.name ?? 'Group $groupId';

  /// Check if contribution is recorded
  bool get isRecorded => status == 'recorded';

  /// Check if contribution is pending
  bool get isPending => status == 'pending';

  /// Check if contribution is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Format date as readable string
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final contributionDate = DateTime(date.year, date.month, date.day);

    if (contributionDate == today) {
      return 'Today';
    } else if (contributionDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get month and year for grouping
  String get monthYear => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Check if contribution is from current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if contribution is from current year
  bool get isCurrentYear => date.year == DateTime.now().year;

  /// Create a copy with updated fields
  ContributionModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    double? amount,
    DateTime? date,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
    GroupModel? group,
  }) {
    return ContributionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      group: group ?? this.group,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        amount,
        date,
        status,
        createdAt,
        updatedAt,
        user,
        group,
      ];

  @override
  String toString() => 'ContributionModel(id: $id, amount: $formattedAmount, date: $formattedDate)';
}

/// Contribution statistics model
class ContributionStatsModel extends Equatable {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final DateTime? firstContribution;
  final DateTime? lastContribution;
  final Map<String, double> monthlyTotals;
  final Map<String, double> memberTotals;

  const ContributionStatsModel({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    this.firstContribution,
    this.lastContribution,
    required this.monthlyTotals,
    required this.memberTotals,
  });

  /// Format total amount as GHS currency
  String get formattedTotalAmount => 'GHS ${totalAmount.toStringAsFixed(2)}';

  /// Format average amount as GHS currency
  String get formattedAverageAmount => 'GHS ${averageAmount.toStringAsFixed(2)}';

  /// Check if there are any contributions
  bool get hasContributions => totalCount > 0;

  /// Get the highest monthly total
  double get highestMonthlyTotal => monthlyTotals.values.isEmpty ? 0.0 : monthlyTotals.values.reduce((a, b) => a > b ? a : b);

  /// Get the lowest monthly total
  double get lowestMonthlyTotal => monthlyTotals.values.isEmpty ? 0.0 : monthlyTotals.values.reduce((a, b) => a < b ? a : b);

  /// Get top contributor (member with highest total)
  String? get topContributor {
    if (memberTotals.isEmpty) return null;
    return memberTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get top contributor amount
  double get topContributorAmount {
    if (memberTotals.isEmpty) return 0.0;
    return memberTotals.values.reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [
        totalAmount,
        totalCount,
        averageAmount,
        firstContribution,
        lastContribution,
        monthlyTotals,
        memberTotals,
      ];
}

/// Contribution filter criteria
class ContributionFilter extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;
  final String? groupId;
  final String? status;
  final double? minAmount;
  final double? maxAmount;
  final int limit;
  final int offset;

  const ContributionFilter({
    this.startDate,
    this.endDate,
    this.userId,
    this.groupId,
    this.status,
    this.minAmount,
    this.maxAmount,
    this.limit = 50,
    this.offset = 0,
  });

  /// Create filter for current month
  factory ContributionFilter.currentMonth({String? groupId, String? userId}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    
    return ContributionFilter(
      startDate: startDate,
      endDate: endDate,
      groupId: groupId,
      userId: userId,
    );
  }

  /// Create filter for current year
  factory ContributionFilter.currentYear({String? groupId, String? userId}) {
    final now = DateTime.now();
    return ContributionFilter(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31),
      groupId: groupId,
      userId: userId,
    );
  }

  /// Create filter for last N months
  factory ContributionFilter.lastMonths(int months, {String? groupId, String? userId}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    
    return ContributionFilter(
      startDate: startDate,
      endDate: now,
      groupId: groupId,
      userId: userId,
    );
  }

  /// Check if filter has date range
  bool get hasDateRange => startDate != null || endDate != null;

  /// Check if filter has amount range
  bool get hasAmountRange => minAmount != null || maxAmount != null;

  /// Create a copy with updated fields
  ContributionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? groupId,
    String? status,
    double? minAmount,
    double? maxAmount,
    int? limit,
    int? offset,
  }) {
    return ContributionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        userId,
        groupId,
        status,
        minAmount,
        maxAmount,
        limit,
        offset,
      ];
}
