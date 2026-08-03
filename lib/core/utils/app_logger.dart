import 'package:flutter/foundation.dart';

/// Structured logging utility.
/// - In debug mode: prints to console with tag/context.
/// - In release mode: stays silent (or wire to Crashlytics/Sentry here)
///   so no sensitive data ever hits production logs.
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
  /// TODO: wire this to Firebase Crashlytics / Sentry before 100k-user launch:
  ///   FirebaseCrashlytics.instance.recordError(error, stack, reason: tag);
  static void error(String tag, Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] $error');
      if (stack != null) debugPrint(stack.toString());
    }
    // Release build: silently forward to crash reporting (not implemented yet).
  }
}
