import 'package:flutter/foundation.dart';

abstract class AppLogger {
  static void d(String message, {String tag = 'TesterMandi'}) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  → $error');
      if (stackTrace != null) debugPrint('  StackTrace: $stackTrace');
    }
  }

  static void w(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  static void i(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }
}
