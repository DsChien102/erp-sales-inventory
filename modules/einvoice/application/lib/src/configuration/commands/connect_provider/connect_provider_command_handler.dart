import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_command_gateway.dart';
import 'connect_provider_command.dart';
import 'connect_provider_result.dart';

@CommandHandlerFor(ConnectProviderCommand)
final class ConnectProviderCommandHandler
    implements ICommandHandler<ConnectProviderCommand, ProviderConnectionResultDto> {
  ConnectProviderCommandHandler({
    required IProviderConnectionCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProviderConnectionCommandGateway _commandGateway;

  @override
  Future<ProviderConnectionResultDto> handle(
    ConnectProviderCommand command,
  ) {
    return _commandGateway.connect(command);
  }
}
