import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

bool _loggingConfigured = false;

/// ERP app logging: verbose in debug, info in release/profile.
///
/// When [logLevelName] is set (e.g. from `.env`), it overrides [verbose].
void configureAppLogging({
  bool verbose = kDebugMode,
  String? logLevelName,
}) {
  final level = logLevelName != null && logLevelName.trim().isNotEmpty
      ? _parseLogLevel(logLevelName)
      : (verbose ? Level.FINE : Level.INFO);
  Logger.root.level = level;
  if (_loggingConfigured) return;
  _loggingConfigured = true;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}

/// Accepts `FINE`, `INFO`, `WARNING`, `SEVERE`, `OFF`, …
Level _parseLogLevel(String name) {
  final normalized = name.trim().toUpperCase();
  for (final level in Level.LEVELS) {
    if (level.name == normalized) return level;
  }
  throw ArgumentError.value(
    name,
    'name',
    'Unknown log level. Use one of: ${Level.LEVELS.map((l) => l.name).join(', ')}',
  );
}
