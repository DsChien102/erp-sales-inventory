import 'i_logger.dart';
import 'i_logger_factory.dart';

/// Simple [ILogger] that prints to stdout — prefer [LoggingLoggerFactory] in apps.
class PrintLogger implements ILogger {
  final String _name;

  PrintLogger({required String name}) : _name = name;

  String get time => DateTime.now().toIso8601String();

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print("[$time] |FINE| ($_name ): $message $error $stackTrace");
  }

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print("[$time] |INFO| ($_name ): $message $error $stackTrace");
  }

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print("[$time] |SEVERE| ($_name ): $message $error $stackTrace");
  }

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print("[$time] |WARNING| ($_name ): $message $error $stackTrace");
  }
}

class PrintLoggerFactory implements ILoggerFactory {
  const PrintLoggerFactory();

  @override
  ILogger named(String name) {
    return PrintLogger(name: name);
  }
}
