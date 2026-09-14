import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_draft_dto.dart';
import '../../../shared/sales_contract_exception.dart';
import '../../ports/i_return_exchange_command_gateway.dart';
import '../../ports/i_return_exchange_reference_port.dart';
import 'start_return_exchange_command.dart';

@CommandHandlerFor(StartReturnExchangeCommand)
final class StartReturnExchangeCommandHandler
    implements ICommandHandler<StartReturnExchangeCommand, ReturnExchangeDraftDto> {
  StartReturnExchangeCommandHandler({
    required IReturnExchangeCommandGateway commandGateway,
    required IReturnExchangeReferencePort referencePort,
  }) : _commandGateway = commandGateway,
       _referencePort = referencePort;

  final IReturnExchangeCommandGateway _commandGateway;
  final IReturnExchangeReferencePort _referencePort;

  @override
  Future<ReturnExchangeDraftDto> handle(StartReturnExchangeCommand command) async {
    final decision = await _referencePort.evaluate(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: command.salesOrderId,
      lines: command.lines,
      reserveExchangeStock: false,
    );
    if (!decision.allowed) {
      throw SalesContractException(
        'RETURN_EXCHANGE_BLOCKED',
        details: <String, Object?>{'blockers': decision.blockers},
      );
    }
    return _commandGateway.start(
      command,
      referenceDecision: decision,
    );
  }
}
