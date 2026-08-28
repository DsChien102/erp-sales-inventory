import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_command_gateway.dart';
import '../connect_provider/connect_provider_result.dart';
import 'reconnect_provider_command.dart';

@CommandHandlerFor(ReconnectProviderCommand)
final class ReconnectProviderCommandHandler
    implements ICommandHandler<ReconnectProviderCommand, ProviderConnectionResultDto> {
  ReconnectProviderCommandHandler({
    required IProviderConnectionCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProviderConnectionCommandGateway _commandGateway;

  @override
  Future<ProviderConnectionResultDto> handle(
    ReconnectProviderCommand command,
  ) {
    return _commandGateway.reconnect(command);
  }
}
