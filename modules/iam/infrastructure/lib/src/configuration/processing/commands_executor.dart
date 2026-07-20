import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Executes commands via the IAM [CommandBus] bound in [IamStartup].
abstract final class CommandsExecutor {
  static CommandBus? _commandBus;

  static void bind(CommandBus commandBus) {
    _commandBus = commandBus;
  }

  static Future<TResult> execute<TResult>(ICommand<TResult> command) {
    final bus = _commandBus;
    if (bus == null) {
      throw StateError('CommandsExecutor.bind must be called during IamStartup');
    }
    return bus.execute(command);
  }
}
