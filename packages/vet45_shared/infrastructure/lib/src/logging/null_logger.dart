import 'i_logger.dart';
import 'i_logger_factory.dart';

/// [ILogger] that discards all output — useful in tests.
///
/// In `flutter_test`, prefer registering [NullLoggerFactory] before
/// [configureDependencies], or pass a mock [ILoggerFactory] into services:
/// `getIt.registerSingleton<ILoggerFactory>(const NoOpLoggerFactory());`
final class NullLogger implements ILogger {
  const NullLogger();

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {}
}

/// [ILoggerFactory] that always returns [NullLogger].
final class NullLoggerFactory implements ILoggerFactory {
  const NullLoggerFactory();

  static const ILogger _singleton = NullLogger();

  @override
  ILogger named(String name) => _singleton;
}
