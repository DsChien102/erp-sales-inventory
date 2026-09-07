import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// ERP app logging: verbose in debug, info in release/profile.
///
/// When [logLevelName] is set (e.g. from `.env`), it overrides [verbose].
void configureAppLogging({
  bool verbose = kDebugMode,
  String? logLevelName,
}) {
  final level = logLevelName != null && logLevelName.trim().isNotEmpty
      ? parseLogLevel(logLevelName)
      : (verbose ? Level.FINE : Level.INFO);
  configurePackageLogging(
    level: level,
    onRecord: (record) {
      developer.log(
        record.message,
        time: record.time,
        sequenceNumber: record.sequenceNumber,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    },
  );
}
