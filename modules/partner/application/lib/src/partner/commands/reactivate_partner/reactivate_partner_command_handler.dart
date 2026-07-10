import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/partner_blocked_codes.dart';
import '../../../shared/partner_blocked_exception.dart';
import '../../../ports/i_partner_command_gateway.dart';
import 'reactivate_partner_command.dart';
import 'reactivate_partner_result.dart';

@CommandHandlerFor(ReactivatePartnerCommand)
final class ReactivatePartnerCommandHandler
    implements ICommandHandler<ReactivatePartnerCommand, ReactivatePartnerResult> {
  ReactivatePartnerCommandHandler({
    required IPartnerRepository repository,
    required IPartnerCommandGateway commandGateway,
  })  : _repository = repository,
        _commandGateway = commandGateway;

  final IPartnerRepository _repository;
  final IPartnerCommandGateway _commandGateway;

  @override
  Future<ReactivatePartnerResult> handle(ReactivatePartnerCommand command) async {
    final partner = await _repository.findById(
      tenantId: TenantId(command.tenantId),
      partnerId: PartnerId(command.partnerId),
    );
    if (partner == null) {
      throw const PartnerBlockedException(PartnerBlockedCodes.notFound);
    }
    if (partner.version != command.expectedVersion) {
      throw const PartnerBlockedException(PartnerBlockedCodes.stateChanged);
    }
    partner.reactivate();
    return _commandGateway.reactivatePartner(command);
  }
}
