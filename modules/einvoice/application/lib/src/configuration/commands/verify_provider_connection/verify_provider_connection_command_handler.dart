import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_command_gateway.dart';
import 'verify_provider_connection_command.dart';
import 'verify_provider_connection_result.dart';

@CommandHandlerFor(VerifyProviderConnectionCommand)
final class VerifyProviderConnectionCommandHandler
    implements ICommandHandler<VerifyProviderConnectionCommand, ProviderConnectionCheckResultDto> {
  VerifyProviderConnectionCommandHandler({
    required IProviderConnectionCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProviderConnectionCommandGateway _commandGateway;

  @override
  Future<ProviderConnectionCheckResultDto> handle(
    VerifyProviderConnectionCommand command,
  ) {
    return _commandGateway.verify(command);
  }
}
