import 'i_logger.dart';

/// Creates [ILogger] instances scoped by hierarchical [name].
///
/// Typical names: `app.services.contact`, `app.services.app_settings`.
abstract interface class ILoggerFactory {
  /// Returns a logger for the given hierarchical [name].
  ILogger named(String name);
}
