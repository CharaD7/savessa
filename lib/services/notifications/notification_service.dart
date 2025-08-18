import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging; // lazy init to avoid errors before Firebase.initializeApp
  bool _initialized = false;

  // Expose last known token for read-only usage in-app (e.g., debugging display)
  String? _lastToken;
  String? get lastToken => _lastToken;

  Future<void> init() async {
    if (_initialized) return;

    // Ensure Firebase is available and initialized
    try {
      // If no default app, attempt a no-op use; caller is already initializing in main
      Firebase.app();
    } catch (_) {
      // Not initialized; skip FCM on unsupported/uninitialized platforms
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;
    } catch (_) {
      return; // skip if messaging not available
    }

    // iOS/Android notification permissions
    await _requestPermission();

    // Get FCM token (can be stored later in Postgres device_trust)
    try {
      _lastToken = await _messaging!.getToken();
      // Do not log tokens in production; consider sending to backend securely.
      if (kDebugMode) {
        debugPrint('FCM token: $_lastToken');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get FCM token: $e');
      }
    }

    // Listen for token refreshes
    _messaging!.onTokenRefresh.listen((newToken) {
      _lastToken = newToken;
      if (kDebugMode) {
        debugPrint('FCM token refreshed: $newToken');
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM onMessage: ${message.messageId}');
    });

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    if (_messaging == null) return;
    try {
      // On iOS/macOS, prompt; on Android 13+, permissions may also be needed.
      await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (Platform.isIOS) {
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification permission request failed: $e');
      }
      // Swallow errors to avoid app termination due to platform issues
    }
  }

  Future<String?> getToken() => _messaging?.getToken() ?? Future.value(null);
}
