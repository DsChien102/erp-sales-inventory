import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_member_detail_dto.dart';
import '../../../ports/i_tenant_membership_command_gateway.dart';
import 'remove_membership_command.dart';

@CommandHandlerFor(RemoveMembershipCommand)
final class RemoveMembershipCommandHandler
    implements ICommandHandler<RemoveMembershipCommand, TenantMemberDetailDto> {
  RemoveMembershipCommandHandler({
    required ITenantMembershipCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantMembershipCommandGateway _commandGateway;

  @override
  Future<TenantMemberDetailDto> handle(RemoveMembershipCommand command) {
    return _commandGateway.remove(
      tenantId: command.tenantId,
      membershipId: command.membershipId,
      expectedVersion: command.expectedVersion,
    );
  }
}
