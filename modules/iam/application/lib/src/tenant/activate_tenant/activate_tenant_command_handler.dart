import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_activation_result_dto.dart';
import '../../ports/i_tenant_activation_command_gateway.dart';
import 'activate_tenant_command.dart';

@CommandHandlerFor(ActivateTenantCommand)
final class ActivateTenantCommandHandler
    implements ICommandHandler<ActivateTenantCommand, TenantActivationResultDto> {
  ActivateTenantCommandHandler({
    required ITenantActivationCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantActivationCommandGateway _commandGateway;

  @override
  Future<TenantActivationResultDto> handle(ActivateTenantCommand command) {
    return _commandGateway.activate(
      tenantId: command.tenantId,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
