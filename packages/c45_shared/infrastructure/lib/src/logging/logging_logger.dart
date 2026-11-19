import 'package:logging/logging.dart';

import 'i_logger.dart';
import 'i_logger_factory.dart';

/// Custom handler for emitted log records.
typedef LogRecordHandler = void Function(LogRecord record);

LogRecordHandler? _customOnRecord;

/// Wires [Logger.root] once so [LoggingLogger] output is routed to stdout or [onRecord].
///
/// Call from `main()` before creating any [LoggingLoggerFactory] instances.
void configurePackageLogging({
  Level level = Level.INFO,
  LogRecordHandler? onRecord,
}) {
  _customOnRecord = onRecord ?? _customOnRecord;
  if (_loggingConfigured) {
    Logger.root.level = level;
    return;
  }

  _loggingConfigured = true;
  Logger.root.level = level;
  Logger.root.onRecord.listen(_emitLogRecord);
}

/// Parses a [package:logging](https://pub.dev/packages/logging) level name.
///
/// Accepts values such as `FINE`, `INFO`, `WARNING`, `SEVERE`, or `OFF`.
Level parseLogLevel(String name) {
  final normalized = name.trim().toUpperCase();
  for (final level in Level.LEVELS) {
    if (level.name == normalized) {
      return level;
    }
  }

  throw ArgumentError.value(
    name,
    'name',
    'Unknown log level. Use one of: ${Level.LEVELS.map((l) => l.name).join(', ')}',
  );
}

bool _loggingConfigured = false;

void _emitLogRecord(LogRecord record) {
  final custom = _customOnRecord;
  if (custom != null) {
    custom(record);
  } else {
    // ignore: avoid_print
    print(_formatLine(record));
  }
}

/// Formats a [LogRecord] into a single structured line.
String formatLogRecord(LogRecord r) => _formatLine(r);

String _formatLine(LogRecord r) {
  final ts = r.time.toUtc().toIso8601String();
  final err = r.error != null ? ' | error=${r.error}' : '';
  final st = r.stackTrace != null ? ' | stack=${r.stackTrace}' : '';
  return '[$ts] |${r.level.name}| (${r.loggerName}): ${r.message}$err$st';
}

/// [ILogger] backed by [package:logging](https://pub.dev/packages/logging).
final class LoggingLogger implements ILogger {
  LoggingLogger(this._logger);

  final Logger _logger;

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
}

/// Creates [LoggingLogger] instances scoped by hierarchical [name].
final class LoggingLoggerFactory implements ILoggerFactory {
  const LoggingLoggerFactory();

  @override
  ILogger named(String name) => LoggingLogger(Logger(name));
}
