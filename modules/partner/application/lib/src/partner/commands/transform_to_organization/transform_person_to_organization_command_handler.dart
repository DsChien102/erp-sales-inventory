import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../services/partner_domain_mapper.dart';
import '../../../shared/partner_blocked_codes.dart';
import '../../../shared/partner_blocked_exception.dart';
import '../../../ports/i_partner_command_gateway.dart';
import 'transform_person_to_organization_command.dart';
import 'transform_partner_result.dart';

@CommandHandlerFor(TransformPersonToOrganizationCommand)
final class TransformPersonToOrganizationCommandHandler
    implements
        ICommandHandler<
          TransformPersonToOrganizationCommand,
          TransformPartnerResult
        > {
  TransformPersonToOrganizationCommandHandler({
    required IPartnerRepository repository,
    required IPartnerCommandGateway commandGateway,
  })  : _repository = repository,
        _commandGateway = commandGateway;

  final IPartnerRepository _repository;
  final IPartnerCommandGateway _commandGateway;

  @override
  Future<TransformPartnerResult> handle(
    TransformPersonToOrganizationCommand command,
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

    partner.transformToOrganization(
      organizationProfile: PartnerDomainMapper.toOrganizationProfile(
        command.organizationProfile,
      )!,
      formerPersonPartnerId: PartnerId(command.partnerId),
    );

    return _commandGateway.transformPersonToOrganization(command);
  }
}
