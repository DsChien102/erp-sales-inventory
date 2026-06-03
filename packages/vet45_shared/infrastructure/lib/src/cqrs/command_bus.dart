import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';

import '../logging/i_logger.dart';
import 'bus_execution_logger.dart';
import 'typed_bus.dart';

typedef CommandHandlerFn = Future<dynamic> Function(ICommand<dynamic> command);

final class CommandBus {
  CommandBus({ILogger? logger, GetIt? container})
    : _logger = logger,
      _container = container,
      _bus = TypedBus<Object, dynamic>();

  final ILogger? _logger;
  final GetIt? _container;
  final TypedBus<Object, dynamic> _bus;

  void register<TCommand extends ICommand<TResult>, TResult>(
    Future<TResult> Function(TCommand command) handler,
  ) {
    _bus.register<TCommand, TResult>(handler);
  }

  void registerFromGetIt<TCommand extends ICommand<TResult>, TResult,
      THandler extends Object>({
    required Future<TResult> Function(TCommand command, THandler handler) invoke,
  }) {
    final container = _container;
    if (container == null) {
      throw StateError('GetIt container is required for registerFromGetIt');
    }

    register<TCommand, TResult>(
      (command) => invoke(command, container.get<THandler>()),
    );
  }

  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    if (command is! IRecurringCommand) {
      return await _bus.execute(command) as TResult;
    }

    final type = command.runtimeType.toString();
    return BusExecutionLogger.run(
      logger: _logger,
      kind: 'Command',
      type: type,
      id: command.id,
      action: () async => await _bus.execute(command) as TResult,
    );
  }
}
