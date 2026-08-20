import 'dart:convert';

import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Emits one-line JSON log records for the messaging worker host.
///
/// Does not change shared [LoggingLogger] line format — only the [message]
/// payload is JSON (`event` + fields).
final class WorkerStructuredLog {
  WorkerStructuredLog(this._logger);

  final ILogger _logger;

  void fine(String event, [Map<String, Object?> fields = const {}]) {
    _logger.fine(_encode(event, fields));
  }

  void info(String event, [Map<String, Object?> fields = const {}]) {
    _logger.info(_encode(event, fields));
  }

  void warning(String event, [Map<String, Object?> fields = const {}]) {
    _logger.warning(_encode(event, fields));
  }

  void severe(
    String event, [
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.severe(_encode(event, fields), error, stackTrace);
  }

  static String _encode(String event, Map<String, Object?> fields) {
    return jsonEncode(<String, Object?>{'event': event, ...fields});
  }
}

/// Creates the default worker logger (`messaging_worker` hierarchy).
ILogger createWorkerLogger([String suffix = '']) {
  final name = suffix.isEmpty ? 'messaging_worker' : 'messaging_worker.$suffix';
  return const LoggingLoggerFactory().named(name);
}

/// Short correlation id for one [MessagingWorkerLoop.runOnce] invocation.
String createWorkerTickId(int sequence) {
  final ms = DateTime.now().toUtc().millisecondsSinceEpoch;
  return 't$ms-$sequence';
}
