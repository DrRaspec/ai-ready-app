/// Enumeration of log severity levels used by [AppLogger].
///
/// Levels are ordered from least to most severe: debug, info, warn, error.
/// Each level can be enabled/disabled via [LogConfig].
///
/// Example usage:
/// ```dart
/// AppLogger.log(LogLevel.info, 'This is an info message.');
/// ```
enum LogLevel { debug, info, warn, error }
