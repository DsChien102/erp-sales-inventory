import '../logging/i_logger.dart';

abstract final class BusExecutionLogger {
  static Future<T> run<T>({
    required ILogger? logger,
    required String kind,
    required String type,
    String? id,
    required Future<T> Function() action,
  }) async {
    final stopwatch = Stopwatch()..start();
    final idSuffix = id == null ? '' : ' id=$id';
    logger?.fine('$kind start type=$type$idSuffix');

    try {
      final result = await action();
      logger?.info(
        '$kind success type=$type$idSuffix '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return result;
    } catch (error, stackTrace) {
      logger?.severe(
        '$kind failed type=$type$idSuffix '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
