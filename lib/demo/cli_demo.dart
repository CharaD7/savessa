#!/usr/bin/env dart

import 'package:intl/intl.dart';

// Simplified versions of our core models for CLI demo
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  
  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });
  
  String get displayName => '$firstName $lastName';
  String get fullName => '$firstName $lastName';
  bool get isAdmin => role == 'admin';
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      email: map['email'],
      role: map['role'],
    );
  }
  
  @override
  String toString() => 'UserModel(id: $id, name: $fullName, email: $email, role: $role)';
}

class GroupModel {
  final String id;
  final String name;
  final double monthlyGoal;
  final bool smartContractEnabled;
  
  GroupModel({
    required this.id,
    required this.name,
    required this.monthlyGoal,
    required this.smartContractEnabled,
  });
  
  String get formattedMonthlyGoal => 'GHS ${monthlyGoal.toStringAsFixed(2)}';
  
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'],
      monthlyGoal: map['monthly_goal']?.toDouble() ?? 0.0,
      smartContractEnabled: map['smart_contract_enabled'] ?? false,
    );
  }
  
  @override
  String toString() => 'GroupModel(id: $id, name: $name, goal: $formattedMonthlyGoal)';
}

class ContributionModel {
  final String id;
  final String groupId;
  final String userId;
  final double amount;
  final DateTime date;
  final String status;
  
  ContributionModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.status,
  });
  
  String get formattedAmount => 'GHS ${amount.toStringAsFixed(2)}';
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM dd').format(date);
  }
  
  factory ContributionModel.fromMap(Map<String, dynamic> map) {
    return ContributionModel(
      id: map['id'],
      groupId: map['group_id'],
      userId: map['user_id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      status: map['status'] ?? 'pending',
    );
  }
  
  @override
  String toString() => 'ContributionModel(id: $id, amount: $formattedAmount, date: $formattedDate)';
}

void main() {
  print('\\n${'🎉' * 30}');
  print('🎉  SAVESSA MODELS CLI DEMO  🎉');
  print('🎉' * 30 + '\\n');
  
  _demonstrateUserModel();
  _demonstrateGroupModel();
  _demonstrateContributionModel();
  _showArchitectureBenefits();
  _showNextSteps();
  
  print('\\n${'✅' * 30}');
  print('✅     DEMO COMPLETED      ✅');
  print('✅' * 30 + '\\n');
  
  print('💡 Run the Flutter app and navigate to /home/enhanced to see the full implementation!');
}

void _demonstrateUserModel() {
  _printSection('👤 USER MODEL DEMONSTRATION');
  
  final userData = {
    'id': 'user-123',
    'first_name': 'Kwame',
    'last_name': 'Asante',
    'email': 'kwame.asante@example.com',
    'role': 'member',
  };
  
  final user = UserModel.fromMap(userData);
  
  print('✓ User created: ${user.displayName}');
  print('✓ Full name: ${user.fullName}');
  print('✓ Email: ${user.email}');
  print('✓ Role: ${user.role}');
  print('✓ Is admin: ${user.isAdmin}');
  print('✓ String representation: $user');
  print('');
}

void _demonstrateGroupModel() {
  _printSection('👥 GROUP MODEL DEMONSTRATION');
  
  final groupData = {
    'id': 'group-456',
    'name': 'Accra Savings Circle',
    'monthly_goal': 2500.0,
    'smart_contract_enabled': true,
  };
  
  final group = GroupModel.fromMap(groupData);
  
  print('✓ Group name: ${group.name}');
  print('✓ Monthly goal: ${group.formattedMonthlyGoal}');
  print('✓ Smart contract: ${group.smartContractEnabled ? 'Enabled ⚡' : 'Disabled'}');
  print('✓ String representation: $group');
  print('');
}

void _demonstrateContributionModel() {
  _printSection('💰 CONTRIBUTION MODEL DEMONSTRATION');
  
  final contributionData = {
    'id': 'contrib-789',
    'group_id': 'group-456',
    'user_id': 'user-123',
    'amount': 250.0,
    'date': DateTime.now().toIso8601String(),
    'status': 'recorded',
  };
  
  final contribution = ContributionModel.fromMap(contributionData);
  
  print('✓ Contribution amount: ${contribution.formattedAmount}');
  print('✓ Date: ${contribution.formattedDate}');
  print('✓ Status: ${contribution.status}');
  print('✓ Group ID: ${contribution.groupId}');
  print('✓ User ID: ${contribution.userId}');
  print('✓ String representation: $contribution');
  print('');
}

void _showArchitectureBenefits() {
  _printSection('🚀 ARCHITECTURE BENEFITS');
  
  final benefits = [
    'Type Safety: No more Map<String, dynamic> guessing!',
    'Consistency: Standardized data handling',
    'Validation: Built-in formatting and validation',
    'Maintainability: Easy to extend and modify',
    'Testing: Simple to mock and test',
    'Performance: Optimized data operations',
    'Error Handling: Proper exception management',
    'Documentation: Self-documenting code',
  ];
  
  for (final benefit in benefits) {
    print('✅ $benefit');
  }
  print('');
}

void _showNextSteps() {
  _printSection('📋 IMPLEMENTATION ROADMAP');
  
  final steps = [
    'Enhanced Home Screen ✅ (Complete - at /home/enhanced)',
    'Migrate existing screens to use new models',
    'Implement offline data synchronization',
    'Add real-time data updates with WebSocket/Firebase',
    'Create comprehensive unit test suite',
    'Add performance monitoring and analytics',
    'Implement advanced caching strategies',
    'Add data validation middleware',
  ];
  
  for (int i = 0; i < steps.length; i++) {
    print('${i + 1}. ${steps[i]}');
  }
  print('');
}

void _printSection(String title) {
  print('=' * (title.length + 4));
  print('  $title  ');
  print('=' * (title.length + 4));
  print('');
}
