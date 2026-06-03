/// Application-facing logging contract for services and infrastructure.
///
/// Implementations wrap `package:logging` in the Flutter app shell. Callers
/// should pass contextual [message] strings; use [error] and [stackTrace]
/// when reporting failures so sinks can persist stack traces.
abstract interface class ILogger {
  void fine(Object? message, [Object? error, StackTrace? stackTrace]);

  void info(Object? message, [Object? error, StackTrace? stackTrace]);

  void warning(Object? message, [Object? error, StackTrace? stackTrace]);

  void severe(Object? message, [Object? error, StackTrace? stackTrace]);
}
