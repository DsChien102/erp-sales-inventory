import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_member_detail_dto.dart';
import '../../../ports/i_tenant_membership_command_gateway.dart';
import 'deactivate_membership_command.dart';

@CommandHandlerFor(DeactivateMembershipCommand)
final class DeactivateMembershipCommandHandler
    implements
        ICommandHandler<DeactivateMembershipCommand, TenantMemberDetailDto> {
  DeactivateMembershipCommandHandler({
    required ITenantMembershipCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantMembershipCommandGateway _commandGateway;

  @override
  Future<TenantMemberDetailDto> handle(DeactivateMembershipCommand command) {
    return _commandGateway.deactivate(
      tenantId: command.tenantId,
      membershipId: command.membershipId,
      expectedVersion: command.expectedVersion,
    );
  }
}
