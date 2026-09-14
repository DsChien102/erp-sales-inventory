import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_result_dto.dart';
import '../../ports/i_return_exchange_command_gateway.dart';
import 'complete_return_exchange_command.dart';

@CommandHandlerFor(CompleteReturnExchangeCommand)
final class CompleteReturnExchangeCommandHandler
    implements ICommandHandler<CompleteReturnExchangeCommand, ReturnExchangeResultDto> {
  CompleteReturnExchangeCommandHandler({
    required IReturnExchangeCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IReturnExchangeCommandGateway _commandGateway;

  @override
  Future<ReturnExchangeResultDto> handle(CompleteReturnExchangeCommand command) =>
      _commandGateway.complete(command);
}
