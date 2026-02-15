import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shadow_log/shadow_log.dart';

class ShadowLogSetup {
  static void initialize() {
    ShadowLog.configure(
      ShadowLogConfig(
        name: 'ai_chat_bot',
        minLevel: kReleaseMode ? ShadowLogLevel.warning : ShadowLogLevel.debug,
        outputs: const <ShadowLogOutput>[SafeShadowDeveloperLogOutput()],
        formatter: const ShadowPrettyFormatter(
          includeTimestamp: true,
          includeLevel: true,
          includeLoggerName: true,
          includeFields: true,
        ),
      ),
    );

    ShadowLog.installFlutterErrorHandler();
  }
}

class SafeShadowDeveloperLogOutput implements ShadowLogOutput {
  const SafeShadowDeveloperLogOutput();

  @override
  void write(ShadowLogRecord record, String formattedMessage) {
    final safeMessage = _ShadowSanitizer.sanitize(formattedMessage);
    final safeError = record.error == null
        ? null
        : _ShadowSanitizer.sanitize(record.error.toString());

    final message = safeError == null
        ? safeMessage
        : '$safeMessage | error=$safeError';

    developer.log(
      message,
      name: record.loggerName,
      level: record.level.value,
      stackTrace: kDebugMode ? record.stackTrace : null,
    );
  }
}

class _ShadowSanitizer {
  static String sanitize(String message) {
    var sanitized = message;

    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(Bearer\s+)(\S+)', caseSensitive: false),
      (match) => '${match.group(1)}***',
    );

    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'((?:access|refresh)[_-]?token"?\s*[:=]\s*"?)([^",\s}]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}***',
    );

    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'((?:password|passcode|pin|api[_-]?key|secret|client[_-]?secret)"?\s*[:=]\s*"?)([^",\s}]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}***',
    );

    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'(([?&](?:access_token|refresh_token|password|api_key|client_secret)=))([^&\s]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}***',
    );

    return sanitized;
  }
}
