import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_command_gateway.dart';
import 'record_connection_verified_command.dart';

@CommandHandlerFor(RecordConnectionVerifiedCommand)
final class RecordConnectionVerifiedCommandHandler
    implements ICommandHandler<RecordConnectionVerifiedCommand, void> {
  RecordConnectionVerifiedCommandHandler({
    required IProviderConnectionCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProviderConnectionCommandGateway _commandGateway;

  @override
  Future<void> handle(RecordConnectionVerifiedCommand command) async {
    await _commandGateway.recordConnectionVerified(command);
  }
}
