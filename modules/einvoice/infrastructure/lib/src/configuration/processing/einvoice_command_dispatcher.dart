import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class EinvoiceCommandDispatcher implements IEinvoiceCommandDispatcher {
  EinvoiceCommandDispatcher({required CommandBus commandBus})
    : _commandBus = commandBus;

  final CommandBus _commandBus;

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) {
    return _commandBus.execute(command);
  }
}
