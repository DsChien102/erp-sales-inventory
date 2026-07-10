import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/partner_blocked_codes.dart';
import '../../../shared/partner_blocked_exception.dart';
import '../../../ports/i_partner_command_gateway.dart';
import '../../../ports/i_partner_read_gateway.dart';
import '../../queries/check_delete_eligibility/check_delete_eligibility_query.dart';
import 'soft_delete_partner_command.dart';
import 'soft_delete_partner_result.dart';

@CommandHandlerFor(SoftDeletePartnerCommand)
final class SoftDeletePartnerCommandHandler
    implements ICommandHandler<SoftDeletePartnerCommand, SoftDeletePartnerResult> {
  SoftDeletePartnerCommandHandler({
    required IPartnerRepository repository,
    required IPartnerReadGateway readGateway,
    required IPartnerCommandGateway commandGateway,
  })  : _repository = repository,
        _readGateway = readGateway,
        _commandGateway = commandGateway;

  final IPartnerRepository _repository;
  final IPartnerReadGateway _readGateway;
  final IPartnerCommandGateway _commandGateway;

  @override
  Future<SoftDeletePartnerResult> handle(
    SoftDeletePartnerCommand command,
  ) async {
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

    final eligibility = await _readGateway.checkDeleteEligibility(
      CheckDeleteEligibilityQuery(
        tenantId: command.tenantId,
        partnerId: command.partnerId,
      ),
    );
    partner.softDelete(hasTransactions: !eligibility.eligible);

    return _commandGateway.softDeletePartner(command);
  }
}
