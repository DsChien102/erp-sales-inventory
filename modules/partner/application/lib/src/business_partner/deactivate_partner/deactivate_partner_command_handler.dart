import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ports/i_partner_command_gateway.dart';
import 'deactivate_partner_command.dart';
import 'deactivate_partner_result.dart';

@CommandHandlerFor(DeactivatePartnerCommand)
final class DeactivatePartnerCommandHandler
    implements ICommandHandler<DeactivatePartnerCommand, DeactivatePartnerResult> {
  DeactivatePartnerCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<DeactivatePartnerResult> handle(
    DeactivatePartnerCommand command,
  ) async {
    final transientPartner = _rehydrateForStatusChange(command);
    final deactivated = transientPartner.deactivate(
      actorId: command.actorId,
      statusNote: command.statusNote,
    );

    final newVersion = await _commandGateway.deactivate(
      partner: deactivated,
      expectedVersion: command.expectedVersion,
      actorId: command.actorId,
      statusNote: command.statusNote,
    );

    return DeactivatePartnerResult(
      businessPartnerId: command.partnerId,
      version: newVersion,
    );
  }

  BusinessPartner _rehydrateForStatusChange(DeactivatePartnerCommand command) {
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
