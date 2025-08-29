import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Group data model that matches the database schema
class GroupModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double monthlyGoal;
  final bool smartContractEnabled;
  final String? inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.monthlyGoal,
    required this.smartContractEnabled,
    this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create GroupModel from database Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      monthlyGoal: (map['monthly_goal'] as num?)?.toDouble() ?? 0.0,
      smartContractEnabled: map['smart_contract_enabled'] == true,
      inviteCode: map['invite_code']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert GroupModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthly_goal': monthlyGoal,
      'smart_contract_enabled': smartContractEnabled,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if group has description
  bool get hasDescription => description?.isNotEmpty == true;

  /// Check if group has invite code
  bool get hasInviteCode => inviteCode?.isNotEmpty == true;

  /// Format monthly goal as GHS currency
  String get formattedMonthlyGoal => 'GHS ${monthlyGoal.toStringAsFixed(2)}';

  /// Create a copy with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    double? monthlyGoal,
    bool? smartContractEnabled,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      smartContractEnabled: smartContractEnabled ?? this.smartContractEnabled,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        monthlyGoal,
        smartContractEnabled,
        inviteCode,
        createdBy,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'GroupModel(id: $id, name: $name, goal: $formattedMonthlyGoal)';
}

/// Group member data model
class GroupMemberModel extends Equatable {
  final String groupId;
  final String userId;
  final String role;
  final String status;
  final DateTime joinedAt;
  final UserModel? user; // Optional populated user data

  const GroupMemberModel({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.user,
  });

  /// Create GroupMemberModel from database Map
  factory GroupMemberModel.fromMap(Map<String, dynamic> map, {UserModel? user}) {
    return GroupMemberModel(
      groupId: map['group_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'active',
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? '') ?? DateTime.now(),
      user: user,
    );
  }

  /// Convert GroupMemberModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Check if member is admin
  bool get isAdmin => role == 'admin';

  /// Check if member is active
  bool get isActive => status == 'active';

  /// Get display name (from user if available, otherwise userId)
  String get displayName => user?.displayName ?? 'User $userId';

  /// Create a copy with updated fields
  GroupMemberModel copyWith({
    String? groupId,
    String? userId,
    String? role,
    String? status,
    DateTime? joinedAt,
    UserModel? user,
  }) {
    return GroupMemberModel(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [groupId, userId, role, status, joinedAt, user];

  @override
  String toString() => 'GroupMemberModel(groupId: $groupId, userId: $userId, role: $role)';
}

/// Monthly goal data model
class MonthlyGoalModel extends Equatable {
  final String groupId;
  final int month;
  final int year;
  final double targetAmount;
  final double achievedAmount;
  final DateTime? achievedAt;

  const MonthlyGoalModel({
    required this.groupId,
    required this.month,
    required this.year,
    required this.targetAmount,
    required this.achievedAmount,
    this.achievedAt,
  });

  /// Create MonthlyGoalModel from database Map
  factory MonthlyGoalModel.fromMap(Map<String, dynamic> map) {
    return MonthlyGoalModel(
      groupId: map['group_id']?.toString() ?? '',
      month: (map['month'] as num?)?.toInt() ?? 1,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      achievedAmount: (map['achieved_amount'] as num?)?.toDouble() ?? 0.0,
      achievedAt: DateTime.tryParse(map['achieved_at']?.toString() ?? ''),
    );
  }

  /// Convert MonthlyGoalModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'month': month,
      'year': year,
      'target_amount': targetAmount,
      'achieved_amount': achievedAmount,
      'achieved_at': achievedAt?.toIso8601String(),
    };
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (achievedAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Calculate progress percentage as display string
  String get progressPercentage => '${(progress * 100).toStringAsFixed(1)}%';

  /// Check if goal is achieved
  bool get isAchieved => achievedAmount >= targetAmount;

  /// Get remaining amount to achieve goal
  double get remainingAmount => (targetAmount - achievedAmount).clamp(0.0, targetAmount);

  /// Format target amount as GHS currency
  String get formattedTargetAmount => 'GHS ${targetAmount.toStringAsFixed(2)}';

  /// Format achieved amount as GHS currency
  String get formattedAchievedAmount => 'GHS ${achievedAmount.toStringAsFixed(2)}';

  /// Format remaining amount as GHS currency
  String get formattedRemainingAmount => 'GHS ${remainingAmount.toStringAsFixed(2)}';

  /// Get month name
  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month.clamp(1, 12)];
  }

  /// Get display period (e.g., "January 2024")
  String get displayPeriod => '$monthName $year';

  /// Create a copy with updated fields
  MonthlyGoalModel copyWith({
    String? groupId,
    int? month,
    int? year,
    double? targetAmount,
    double? achievedAmount,
    DateTime? achievedAt,
  }) {
    return MonthlyGoalModel(
      groupId: groupId ?? this.groupId,
      month: month ?? this.month,
      year: year ?? this.year,
      targetAmount: targetAmount ?? this.targetAmount,
      achievedAmount: achievedAmount ?? this.achievedAmount,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  @override
  List<Object?> get props => [groupId, month, year, targetAmount, achievedAmount, achievedAt];

  @override
  String toString() => 'MonthlyGoalModel(period: $displayPeriod, progress: $progressPercentage)';
}

/// Group with additional metadata for display
class GroupWithMetadata extends Equatable {
  final GroupModel group;
  final int memberCount;
  final double totalSaved;
  final double currentMonthSaved;
  final List<GroupMemberModel> members;
  final MonthlyGoalModel? currentGoal;

  const GroupWithMetadata({
    required this.group,
    required this.memberCount,
    required this.totalSaved,
    required this.currentMonthSaved,
    required this.members,
    this.currentGoal,
  });

  /// Format total saved as GHS currency
  String get formattedTotalSaved => 'GHS ${totalSaved.toStringAsFixed(2)}';

  /// Format current month saved as GHS currency
  String get formattedCurrentMonthSaved => 'GHS ${currentMonthSaved.toStringAsFixed(2)}';

  /// Get current month progress (if goal exists)
  double get currentMonthProgress {
    if (currentGoal == null) return 0.0;
    return currentGoal!.progress;
  }

  /// Check if current month goal is achieved
  bool get isCurrentGoalAchieved => currentGoal?.isAchieved ?? false;

  @override
  List<Object?> get props => [group, memberCount, totalSaved, currentMonthSaved, members, currentGoal];
}
