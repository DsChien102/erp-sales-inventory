import 'package:vet45_shared_application/application.dart';

import '../../logging/i_logger.dart';

final class LoggingCommandHandlerDecorator<TCommand extends ICommand<TResult>, TResult> {
  LoggingCommandHandlerDecorator({
    required Future<TResult> Function(TCommand command) inner,
    ILogger? logger,
  }) : _inner = inner,
       _logger = logger;

  final Future<TResult> Function(TCommand command) _inner;
  final ILogger? _logger;

  Future<TResult> handle(TCommand command) async {
    if (command is IRecurringCommand) {
      return _inner(command);
    }

    final type = command.runtimeType.toString();
    final stopwatch = Stopwatch()..start();
    _logger?.fine('Handler start type=$type id=${command.id}');

    try {
      final result = await _inner(command);
      _logger?.fine(
        'Handler success type=$type id=${command.id} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return result;
    } catch (error, stackTrace) {
      _logger?.severe(
        'Handler failed type=$type id=${command.id} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
