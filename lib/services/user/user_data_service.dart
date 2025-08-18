import 'package:flutter/foundation.dart';

class UserDataService with ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  String get role => (_user?['role'] as String?) ?? 'member';
  String get firstName => (_user?['first_name'] as String?) ?? '';
  String? get id => _user?['id']?.toString();

  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}

