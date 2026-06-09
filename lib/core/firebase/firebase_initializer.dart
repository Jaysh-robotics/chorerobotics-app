import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase safely at app startup.
///
/// If `firebase_options.dart` is still a placeholder (i.e. the user hasn't
/// run `flutterfire configure`), this returns `false` and the rest of the app
/// can fall back to unauthenticated behaviour. Consumers should check
/// [isInitialized] before calling Firebase SDKs.
class FirebaseInitializer {
  static bool _initialized = false;
  static String? _lastError;

  static bool get isInitialized => _initialized;
  static String? get lastError => _lastError;

  static Future<bool> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[Firebase] Initialized');
      }
      return true;
    } catch (e) {
      _lastError = '$e';
      _initialized = false;
      if (kDebugMode) {
        debugPrint('[Firebase] NOT initialized: $e');
        debugPrint('[Firebase] Run: flutterfire configure');
      }
      return false;
    }
  }
}
