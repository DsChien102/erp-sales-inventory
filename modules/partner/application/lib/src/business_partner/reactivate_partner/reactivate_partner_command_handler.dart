import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ports/i_partner_command_gateway.dart';
import 'reactivate_partner_command.dart';
import 'reactivate_partner_result.dart';

@CommandHandlerFor(ReactivatePartnerCommand)
final class ReactivatePartnerCommandHandler
    implements ICommandHandler<ReactivatePartnerCommand, ReactivatePartnerResult> {
  ReactivatePartnerCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<ReactivatePartnerResult> handle(
    ReactivatePartnerCommand command,
  ) async {
    final transientPartner = _rehydrateForStatusChange(command);
    final reactivated = transientPartner.reactivate(
      actorId: command.actorId,
    );

    final newVersion = await _commandGateway.reactivate(
      partner: reactivated,
      expectedVersion: command.expectedVersion,
      actorId: command.actorId,
    );

    return ReactivatePartnerResult(
      businessPartnerId: command.partnerId,
      version: newVersion,
    );
  }

  BusinessPartner _rehydrateForStatusChange(ReactivatePartnerCommand command) {
    return BusinessPartner.rehydrate(
      id: BusinessPartnerId(command.partnerId),
      tenantId: TenantId(command.tenantId),
      entityType: EntityType.individual,
      displayName: PartnerName('status-change'),
      phone: PhoneNumber('00000000'),
      roles: {PartnerRole.customer},
      status: command.currentStatus,
      createdBy: command.actorId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedBy: command.actorId,
      updatedAt: DateTime.now(),
      version: command.expectedVersion,
    );
  }
}
