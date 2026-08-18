import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_command_gateway.dart';
import '../connect_provider/connect_provider_result.dart';
import 'disconnect_provider_command.dart';

@CommandHandlerFor(DisconnectProviderCommand)
final class DisconnectProviderCommandHandler
    implements
        ICommandHandler<DisconnectProviderCommand, ProviderConnectionResultDto> {
  DisconnectProviderCommandHandler({
    required IProviderConnectionCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProviderConnectionCommandGateway _commandGateway;

  @override
  Future<ProviderConnectionResultDto> handle(
    DisconnectProviderCommand command,
  ) {
    return _commandGateway.disconnect(command);
  }
}
