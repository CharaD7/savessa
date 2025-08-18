import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityPrefsService with ChangeNotifier {
  static const _kRequireBiometricKey = 'require_biometric_sensitive_actions';

  bool _loaded = false;
  bool get loaded => _loaded;

  bool _requireBiometric = false;
  bool get requireBiometric => _requireBiometric;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _requireBiometric = prefs.getBool(_kRequireBiometricKey) ?? false;
    } catch (_) {
      _requireBiometric = false;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setRequireBiometric(bool value) async {
    _requireBiometric = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRequireBiometricKey, value);
    } catch (_) {
      // ignore persistence errors
    }
  }
}
