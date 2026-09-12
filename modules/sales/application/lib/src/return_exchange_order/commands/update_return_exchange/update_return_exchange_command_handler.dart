import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_draft_dto.dart';
import '../../../shared/sales_contract_exception.dart';
import '../../ports/i_return_exchange_command_gateway.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import '../../ports/i_return_exchange_reference_port.dart';
import 'update_return_exchange_command.dart';

@CommandHandlerFor(UpdateReturnExchangeCommand)
final class UpdateReturnExchangeCommandHandler
    implements ICommandHandler<UpdateReturnExchangeCommand, ReturnExchangeDraftDto> {
  UpdateReturnExchangeCommandHandler({
    required IReturnExchangeReadGateway readGateway,
    required IReturnExchangeCommandGateway commandGateway,
    required IReturnExchangeReferencePort referencePort,
  }) : _readGateway = readGateway,
       _commandGateway = commandGateway,
       _referencePort = referencePort;

  final IReturnExchangeReadGateway _readGateway;
  final IReturnExchangeCommandGateway _commandGateway;
  final IReturnExchangeReferencePort _referencePort;

  @override
  Future<ReturnExchangeDraftDto> handle(UpdateReturnExchangeCommand command) async {
    final context = await _readGateway.getContext(
      tenantId: command.tenantId,
      actorId: command.actorId,
      returnExchangeId: command.returnExchangeId,
    );
    final decision = await _referencePort.evaluate(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: context.draft.salesOrderId,
      lines: command.lines,
      reserveExchangeStock: false,
    );
    if (!decision.allowed) {
      throw SalesContractException(
        'RETURN_EXCHANGE_BLOCKED',
        details: <String, Object?>{'blockers': decision.blockers},
      );
    }
    return _commandGateway.update(
      command,
      referenceDecision: decision,
    );
  }
}
