import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../services/partner_domain_mapper.dart';
import '../../../shared/partner_blocked_codes.dart';
import '../../../shared/partner_blocked_exception.dart';
import '../../../ports/i_partner_command_gateway.dart';
import 'update_partner_profile_command.dart';
import 'update_partner_profile_result.dart';

@CommandHandlerFor(UpdatePartnerProfileCommand)
final class UpdatePartnerProfileCommandHandler
    implements
        ICommandHandler<UpdatePartnerProfileCommand, UpdatePartnerProfileResult> {
  UpdatePartnerProfileCommandHandler({
    required IPartnerRepository repository,
    required IPartnerCommandGateway commandGateway,
  })  : _repository = repository,
        _commandGateway = commandGateway;

  final IPartnerRepository _repository;
  final IPartnerCommandGateway _commandGateway;

  @override
  Future<UpdatePartnerProfileResult> handle(
    UpdatePartnerProfileCommand command,
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

    partner.updateProfile(
      personProfile: PartnerDomainMapper.toPersonProfile(command.personProfile),
      organizationProfile: PartnerDomainMapper.toOrganizationProfile(
        command.organizationProfile,
      ),
      roleTypes: command.roles,
    );

    return _commandGateway.updatePartnerProfile(command);
  }
}
