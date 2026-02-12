import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'log_config.dart';
import 'log_level.dart';

/// A static logging utility designed for Flutter applications, providing structured logging
/// with configurable levels, automatic caller resolution, and integration with Dart's developer tools.
///
/// This logger abstracts the `dart:developer.log` API to offer a clean, type-safe interface
/// while maintaining performance and debuggability. It supports conditional logging based on
/// build mode and automatically captures caller information for precise tracing.
///
/// Example usage:
/// ```dart
/// AppLogger.log(LogLevel.info, 'User logged in successfully.');
/// AppLogger.log(LogLevel.error, 'Login failed', error: exception, stackTrace: s);
/// ```
class AppLogger {
  /// Logs a message with the specified [level], with optional tagging, sanitization,
  /// error details, and stack trace support.
  ///
  /// ### Safety & Privacy
  /// - All log messages are **sanitized** before output to prevent accidental leakage
  ///   of sensitive data (e.g. tokens, passwords, API keys).
  /// - Caller information (file, line, member) is only included when
  ///   [LogConfig.allowCallerInfo] is enabled and is automatically disabled in release builds.
  /// - Stack traces are only attached when [LogConfig.allowStackTrace] is enabled.
  ///
  /// ### Behavior
  /// - The log is emitted **only if** the corresponding level is enabled in [LogConfig].
  /// - Each log entry is timestamped using ISO-8601 format.
  /// - Logs are routed through `dart:developer.log` for proper IDE and tooling integration.
  ///
  /// ### Parameters
  /// - [level]: The severity level of the log (`debug`, `info`, `warn`, `error`).
  /// - [message]: The log message to output (automatically sanitized).
  /// - [tag]: Optional logical scope or feature tag (e.g. `Auth`, `Network`, `Controller`).
  /// - [error]: Optional error object to attach.
  /// - [stackTrace]: Optional stack trace (respected only if enabled in [LogConfig]).
  ///
  /// ### Example
  /// ```dart
  /// AppLogger.log(LogLevel.info, 'User logged in', tag: 'Auth');
  /// AppLogger.log(
  ///   LogLevel.error,
  ///   'Login failed',
  ///   tag: 'Auth',
  ///   error: exception,
  ///   stackTrace: stack,
  /// );
  /// ```
  static void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isLogEnabled(level)) return;

    final scope = tag != null ? '[$tag] ' : '';
    final safeMessage = _sanitize(message);

    final callerInfo = LogConfig.allowCallerInfo ? _resolveCaller() : null;

    final timestamp = DateTime.now().toIso8601String();

    final logMessage = callerInfo != null
        ? '[$timestamp] [${level.name.toUpperCase()}] '
              '[${callerInfo.file}:${callerInfo.line} ${callerInfo.member}] '
              '$scope$safeMessage'
        : '[$timestamp] [${level.name.toUpperCase()}] '
              '$scope$safeMessage';

    developer.log(
      logMessage,
      level: _mapLevel(level),
      name: tag ?? 'AppLogger',
      error: error,
      stackTrace: LogConfig.allowStackTrace ? stackTrace : null,
    );
  }

  static String _sanitize(String msg) {
    return msg
        .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***')
        .replaceAll(RegExp(r'password=\S+'), 'password=***')
        .replaceAll(
          RegExp(r'api[_-]?key=\S+', caseSensitive: false),
          'apiKey=***',
        );
  }

  static bool _isLogEnabled(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return LogConfig.enableDebugLogs;
      case LogLevel.info:
        return LogConfig.enableInfoLogs;
      case LogLevel.warn:
        return LogConfig.enableWarnLogs;
      case LogLevel.error:
        return LogConfig.enableErrorLogs;
    }
  }

  static int _mapLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  /// Debug-only caller resolution
  static _CallerInfo _resolveCaller() {
    // Extra safety: never run in release
    if (!kDebugMode) return _CallerInfo.unknown();

    final frames = StackTrace.current.toString().split('\n');
    for (final frame in frames) {
      if (!frame.contains('AppLogger') && frame.contains('.dart')) {
        return _CallerInfo.fromFrame(frame);
      }
    }
    return _CallerInfo.unknown();
  }

  /// Convenience methods
  static void d(String msg) => log(LogLevel.debug, msg);
  static void i(String msg) => log(LogLevel.info, msg);
  static void w(String msg) => log(LogLevel.warn, msg);
  static void e(String msg, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, msg, error: error, stackTrace: stackTrace);
}

class _CallerInfo {
  final String file;
  final String member;
  final int line;

  _CallerInfo(this.file, this.member, this.line);

  factory _CallerInfo.fromFrame(String frame) {
    final regex = RegExp(r'(.+\.dart):(\d+):\d+\s+(.+)');
    final match = regex.firstMatch(frame);

    if (match == null) {
      return _CallerInfo.unknown();
    }

    return _CallerInfo(
      match.group(1)!.split('/').last,
      match.group(3)!,
      int.parse(match.group(2)!),
    );
  }

  factory _CallerInfo.unknown() => _CallerInfo('unknown', 'unknown', 0);
}
