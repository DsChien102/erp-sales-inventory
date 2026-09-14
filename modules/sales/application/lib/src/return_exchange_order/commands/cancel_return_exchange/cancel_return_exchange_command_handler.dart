import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_result_dto.dart';
import '../../ports/i_return_exchange_command_gateway.dart';
import 'cancel_return_exchange_command.dart';

@CommandHandlerFor(CancelReturnExchangeCommand)
final class CancelReturnExchangeCommandHandler
    implements ICommandHandler<CancelReturnExchangeCommand, ReturnExchangeResultDto> {
  CancelReturnExchangeCommandHandler({
    required IReturnExchangeCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IReturnExchangeCommandGateway _commandGateway;

  @override
  Future<ReturnExchangeResultDto> handle(CancelReturnExchangeCommand command) =>
      _commandGateway.cancel(command);
}
