import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ports/i_partner_command_gateway.dart';
import 'delete_partner_command.dart';
import 'delete_partner_result.dart';

@CommandHandlerFor(DeletePartnerCommand)
final class DeletePartnerCommandHandler
    implements ICommandHandler<DeletePartnerCommand, DeletePartnerResult> {
  DeletePartnerCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<DeletePartnerResult> handle(DeletePartnerCommand command) async {
    final transientPartner = _rehydrateForDelete(command);
    final deleted = transientPartner.delete(
      actorId: command.actorId,
      hasTransactionHistory: command.hasBusinessData,
    );

    await _commandGateway.delete(
      partner: deleted,
      expectedVersion: command.expectedVersion,
      actorId: command.actorId,
    );

    return DeletePartnerResult(
      businessPartnerId: command.partnerId,
    );
  }

  BusinessPartner _rehydrateForDelete(DeletePartnerCommand command) {
    return BusinessPartner.rehydrate(
      id: BusinessPartnerId(command.partnerId),
      tenantId: TenantId(command.tenantId),
      entityType: EntityType.individual,
      displayName: PartnerName('delete'),
      phone: PhoneNumber('00000000'),
      roles: {PartnerRole.customer},
      status: PartnerStatus.active,
      createdBy: command.actorId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedBy: command.actorId,
      updatedAt: DateTime.now(),
      version: command.expectedVersion,
    );
  }
}
