import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Admin app logging: verbose in debug, info in release/profile.
///
/// When [logLevelName] is set (e.g. from `.env`), it overrides [verbose].
void configureAppLogging({
  bool verbose = kDebugMode,
  String? logLevelName,
}) {
  final level = logLevelName != null && logLevelName.trim().isNotEmpty
      ? parseLogLevel(logLevelName)
      : (verbose ? Level.FINE : Level.INFO);
  configurePackageLogging(level: level);
}
