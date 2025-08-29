import 'package:equatable/equatable.dart';

/// Notification data model
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  /// Create NotificationModel from database Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: NotificationType.fromString(map['type']?.toString() ?? ''),
      data: (map['data'] as Map<String, dynamic>?) ?? {},
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: DateTime.tryParse(map['read_at']?.toString() ?? ''),
    );
  }

  /// Convert NotificationModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.toString(),
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// Format creation time as readable string
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get icon for notification type
  String get typeIcon {
    switch (type) {
      case NotificationType.contribution:
        return '💰';
      case NotificationType.goal:
        return '🎯';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.security:
        return '🔒';
      case NotificationType.group:
        return '👥';
      case NotificationType.system:
        return '🔧';
      case NotificationType.achievement:
        return '🏆';
    }
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, body, type, data, isRead, createdAt, readAt];

  @override
  String toString() => 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
}

/// Notification types
enum NotificationType {
  contribution,
  goal,
  reminder,
  security,
  group,
  system,
  achievement;

  /// Create from string
  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'contribution':
        return NotificationType.contribution;
      case 'goal':
        return NotificationType.goal;
      case 'reminder':
        return NotificationType.reminder;
      case 'security':
        return NotificationType.security;
      case 'group':
        return NotificationType.group;
      case 'system':
        return NotificationType.system;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.system;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NotificationType.contribution:
        return 'contribution';
      case NotificationType.goal:
        return 'goal';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.security:
        return 'security';
      case NotificationType.group:
        return 'group';
      case NotificationType.system:
        return 'system';
      case NotificationType.achievement:
        return 'achievement';
    }
  }
}

/// Audit log data model
class AuditLogModel extends Equatable {
  final String id;
  final String userId;
  final String action;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic> metadata;
  final String? ip;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    this.targetType,
    this.targetId,
    required this.metadata,
    this.ip,
    required this.createdAt,
  });

  /// Create AuditLogModel from database Map
  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      targetType: map['target_type']?.toString(),
      targetId: map['target_id']?.toString(),
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      ip: map['ip']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert AuditLogModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'metadata': metadata,
      'ip': ip,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Format creation time as readable string
  String get formattedTime {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get action icon
  String get actionIcon {
    if (action.contains('login')) return '🔑';
    if (action.contains('create')) return '➕';
    if (action.contains('update')) return '✏️';
    if (action.contains('delete')) return '🗑️';
    if (action.contains('security')) return '🔒';
    return '📝';
  }

  /// Get severity level
  AuditSeverity get severity {
    if (action.contains('delete') || action.contains('security')) {
      return AuditSeverity.high;
    } else if (action.contains('create') || action.contains('update')) {
      return AuditSeverity.medium;
    }
    return AuditSeverity.low;
  }

  @override
  List<Object?> get props => [id, userId, action, targetType, targetId, metadata, ip, createdAt];

  @override
  String toString() => 'AuditLogModel(id: $id, action: $action, time: $formattedTime)';
}

/// Audit severity levels
enum AuditSeverity { low, medium, high }

/// Sync status data model
class SyncStatusModel extends Equatable {
  final String id;
  final SyncType type;
  final SyncStatus status;
  final DateTime lastSync;
  final DateTime? nextSync;
  final int pendingCount;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const SyncStatusModel({
    required this.id,
    required this.type,
    required this.status,
    required this.lastSync,
    this.nextSync,
    required this.pendingCount,
    this.errorMessage,
    required this.metadata,
  });

  /// Create SyncStatusModel from Map
  factory SyncStatusModel.fromMap(Map<String, dynamic> map) {
    return SyncStatusModel(
      id: map['id']?.toString() ?? '',
      type: SyncType.fromString(map['type']?.toString() ?? ''),
      status: SyncStatus.fromString(map['status']?.toString() ?? ''),
      lastSync: DateTime.tryParse(map['last_sync']?.toString() ?? '') ?? DateTime.now(),
      nextSync: DateTime.tryParse(map['next_sync']?.toString() ?? ''),
      pendingCount: (map['pending_count'] as num?)?.toInt() ?? 0,
      errorMessage: map['error_message']?.toString(),
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'status': status.toString(),
      'last_sync': lastSync.toIso8601String(),
      'next_sync': nextSync?.toIso8601String(),
      'pending_count': pendingCount,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  /// Format last sync time
  String get formattedLastSync {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just synced';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case SyncStatus.synced:
        return '✅';
      case SyncStatus.syncing:
        return '🔄';
      case SyncStatus.pending:
        return '⏳';
      case SyncStatus.error:
        return '❌';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case SyncStatus.synced:
        return '#4CAF50'; // Green
      case SyncStatus.syncing:
        return '#2196F3'; // Blue
      case SyncStatus.pending:
        return '#FF9800'; // Orange
      case SyncStatus.error:
        return '#F44336'; // Red
    }
  }

  /// Check if sync is needed
  bool get needsSync => status == SyncStatus.pending || status == SyncStatus.error;

  @override
  List<Object?> get props => [id, type, status, lastSync, nextSync, pendingCount, errorMessage, metadata];

  @override
  String toString() => 'SyncStatusModel(type: $type, status: $status, lastSync: $formattedLastSync)';
}

/// Sync types
enum SyncType {
  contributions,
  groups,
  members,
  notifications,
  security,
  all;

  static SyncType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'contributions':
        return SyncType.contributions;
      case 'groups':
        return SyncType.groups;
      case 'members':
        return SyncType.members;
      case 'notifications':
        return SyncType.notifications;
      case 'security':
        return SyncType.security;
      case 'all':
        return SyncType.all;
      default:
        return SyncType.all;
    }
  }

  @override
  String toString() {
    switch (this) {
      case SyncType.contributions:
        return 'contributions';
      case SyncType.groups:
        return 'groups';
      case SyncType.members:
        return 'members';
      case SyncType.notifications:
        return 'notifications';
      case SyncType.security:
        return 'security';
      case SyncType.all:
        return 'all';
    }
  }
}

/// Sync statuses
enum SyncStatus {
  synced,
  syncing,
  pending,
  error;

  static SyncStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'synced':
        return SyncStatus.synced;
      case 'syncing':
        return SyncStatus.syncing;
      case 'pending':
        return SyncStatus.pending;
      case 'error':
        return SyncStatus.error;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.error:
        return 'error';
    }
  }
}
