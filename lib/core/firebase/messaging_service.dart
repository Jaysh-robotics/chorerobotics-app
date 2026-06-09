import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_initializer.dart';

/// Thin wrapper around FirebaseMessaging. Handles token retrieval and
/// foreground / background notification routing.
class MessagingService {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// Request permission and return the FCM token for this install.
  /// Returns null when Firebase isn't configured or permission is denied.
  Future<String?> initAndGetToken() async {
    if (!FirebaseInitializer.isInitialized) return null;
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }
    final token = await _fcm.getToken();
    if (kDebugMode && token != null) {
      debugPrint('[FCM] Token: ${token.substring(0, 16)}...');
    }
    return token;
  }

  Stream<String> get onTokenRefresh =>
      FirebaseInitializer.isInitialized ? _fcm.onTokenRefresh : const Stream.empty();

  Stream<RemoteMessage> get onMessage =>
      FirebaseInitializer.isInitialized ? FirebaseMessaging.onMessage : const Stream.empty();

  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseInitializer.isInitialized
      ? FirebaseMessaging.onMessageOpenedApp
      : const Stream.empty();
}
