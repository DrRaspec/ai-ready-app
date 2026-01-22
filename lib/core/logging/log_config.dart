import 'package:flutter/foundation.dart';

/// Configuration class for controlling logging behavior in [AppLogger].
///
/// This class provides static getters to enable/disable log levels and features
/// based on the build mode (debug vs. release). It ensures sensitive information
/// like caller details and stack traces are only exposed in debug builds.
///
/// Usage:
/// ```dart
/// if (LogConfig.enableDebugLogs) {
///   // Custom logic if needed
/// }
/// ```
/// Note: [AppLogger] uses these internally; no manual checks required for logging.
class LogConfig {
  /// Only true in debug builds
  static const bool _isDebug = kDebugMode;

  /// Whether debug-level logs are enabled. Only true in debug mode.
  static bool get enableDebugLogs => _isDebug;

  /// Whether info-level logs are enabled. Only true in debug mode.
  static bool get enableInfoLogs => _isDebug;

  /// Whether warn-level logs are enabled. Always true.
  static bool get enableWarnLogs => true;

  /// Whether error-level logs are enabled. Always true.
  static bool get enableErrorLogs => true;

  /// Whether caller information (file, line, member) is included in logs. Only true in debug mode.
  static bool get allowCallerInfo => _isDebug;

  /// Whether stack traces are allowed in logs. Only true in debug mode.
  static bool get allowStackTrace => _isDebug;
}
