import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_member_detail_dto.dart';
import '../../ports/i_tenant_membership_command_gateway.dart';
import 'reactivate_membership_command.dart';

@CommandHandlerFor(ReactivateMembershipCommand)
final class ReactivateMembershipCommandHandler
    implements
        ICommandHandler<ReactivateMembershipCommand, TenantMemberDetailDto> {
  ReactivateMembershipCommandHandler({
    required ITenantMembershipCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantMembershipCommandGateway _commandGateway;

  @override
  Future<TenantMemberDetailDto> handle(ReactivateMembershipCommand command) {
    return _commandGateway.reactivate(
      tenantId: command.tenantId,
      membershipId: command.membershipId,
      expectedVersion: command.expectedVersion,
    );
  }
}
