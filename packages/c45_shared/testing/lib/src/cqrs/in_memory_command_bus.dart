import 'package:c45_shared_application/application.dart';
import 'package:c45_shared_infrastructure/infrastructure.dart';

/// In-memory [CommandBus] for handler and pipeline tests.
final class InMemoryCommandBus {
  InMemoryCommandBus() : _bus = CommandBus();

  final CommandBus _bus;

  void registerHandler<TCommand extends ICommand<TResult>, TResult>(
    ICommandHandler<TCommand, TResult> handler,
  ) {
    _bus.register<TCommand, TResult>(handler.handle);
  }

  void register<TCommand extends ICommand<TResult>, TResult>(
    Future<TResult> Function(TCommand command) handler,
  ) {
    _bus.register<TCommand, TResult>(handler);
  }

  Future<TResult> execute<TResult>(ICommand<TResult> command) {
    return _bus.execute(command);
  }
}
