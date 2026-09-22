import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logger service for MindFlow.
/// Wraps the `logger` package to provide production-safe, structured logging.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  /// Log debug messages (ignored in release mode).
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log informational messages.
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages.
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
