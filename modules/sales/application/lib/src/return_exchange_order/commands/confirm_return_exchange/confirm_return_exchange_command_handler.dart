import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_result_dto.dart';
import '../../../shared/sales_contract_exception.dart';
import '../../ports/i_return_exchange_command_gateway.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import '../../ports/i_return_exchange_reference_port.dart';
import 'confirm_return_exchange_command.dart';

@CommandHandlerFor(ConfirmReturnExchangeCommand)
final class ConfirmReturnExchangeCommandHandler
    implements ICommandHandler<ConfirmReturnExchangeCommand, ReturnExchangeResultDto> {
  ConfirmReturnExchangeCommandHandler({
    required IReturnExchangeReadGateway readGateway,
    required IReturnExchangeReferencePort referencePort,
    required IReturnExchangeCommandGateway commandGateway,
  }) : _readGateway = readGateway,
       _referencePort = referencePort,
       _commandGateway = commandGateway;

  final IReturnExchangeReadGateway _readGateway;
  final IReturnExchangeReferencePort _referencePort;
  final IReturnExchangeCommandGateway _commandGateway;

  @override
  Future<ReturnExchangeResultDto> handle(ConfirmReturnExchangeCommand command) async {
    final context = await _readGateway.getContext(
      tenantId: command.tenantId,
      actorId: command.actorId,
      returnExchangeId: command.returnExchangeId,
    );
    final decision = await _referencePort.evaluate(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: context.draft.salesOrderId,
      lines: context.draft.lines,
      reserveExchangeStock: false,
    );
    if (!decision.allowed) {
      throw SalesContractException(
        'RETURN_EXCHANGE_BLOCKED',
        details: <String, Object?>{'blockers': decision.blockers},
      );
    }
    return _commandGateway.confirm(
      command,
      referenceDecision: decision,
    );
  }
}
