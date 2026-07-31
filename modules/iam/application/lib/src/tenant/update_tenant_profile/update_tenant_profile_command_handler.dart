import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_dto.dart';
import '../../ports/i_tenant_profile_command_gateway.dart';
import 'update_tenant_profile_command.dart';

@CommandHandlerFor(UpdateTenantProfileCommand)
final class UpdateTenantProfileCommandHandler
    implements ICommandHandler<UpdateTenantProfileCommand, TenantDto> {
  UpdateTenantProfileCommandHandler({
    required ITenantProfileCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantProfileCommandGateway _commandGateway;

  @override
  Future<TenantDto> handle(UpdateTenantProfileCommand command) {
    return _commandGateway.updateProfile(
      tenantId: command.tenantId,
      displayName: command.displayName,
      contactEmail: command.contactEmail,
      contactPhone: command.contactPhone,
      contactAddressText: command.contactAddressText,
      provinceCode: command.provinceCode,
      communeCode: command.communeCode,
      expectedVersion: command.expectedVersion,
    );
  }
}
