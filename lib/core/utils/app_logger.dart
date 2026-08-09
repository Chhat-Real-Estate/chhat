import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Structured logging utility.
/// - In debug mode: prints to console with tag/context.
/// - In release mode: silently forwards to Firebase Crashlytics.
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] $message');
    }
  }

  static void warning(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[WARN][$tag] $message');
    }
  }

  /// Use for caught exceptions. Pass the original error + stack trace.
  static void error(String tag, Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] $error');
      if (stack != null) debugPrint(stack.toString());
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: tag);
    }
  }
}
