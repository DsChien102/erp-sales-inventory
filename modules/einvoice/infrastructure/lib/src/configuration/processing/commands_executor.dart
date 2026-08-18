import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Executes commands via the E-Invoice [CommandBus] bound in [EinvoiceStartup].
abstract final class EinvoiceCommandsExecutor {
  static CommandBus? _commandBus;

  static void bind(CommandBus commandBus) {
    _commandBus = commandBus;
  }

  static Future<TResult> execute<TResult>(ICommand<TResult> command) {
    final bus = _commandBus;
    if (bus == null) {
      throw StateError(
        'EinvoiceCommandsExecutor.bind must be called during EinvoiceStartup',
      );
    }
    return bus.execute(command);
  }
}
