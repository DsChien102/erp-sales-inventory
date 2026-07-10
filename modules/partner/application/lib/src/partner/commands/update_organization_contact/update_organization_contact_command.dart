import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/person_profile_input.dart';

/// Updates OrganizationContact link and optionally the linked Person profile.
///
/// Per EP-01/US-05 API contract, PATCH contact may include person fields
/// (`full_name`, `phone`, `email`, …) without going through
/// [UpdatePartnerProfileCommand] (which requires `partner.update` + roles).
@RequiresPermission(PartnerPermissions.contactManage)
@RequiresTenant()
final class UpdateOrganizationContactCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  UpdateOrganizationContactCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.organizationPartnerId,
    required this.personPartnerId,
    this.contactRole,
    this.isPrimary,
    this.note,
    this.personProfile,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String organizationPartnerId;
  final String personPartnerId;
  final String? contactRole;
  final bool? isPrimary;
  final String? note;

  /// When set, updates the linked Person partner profile (name/phone/email/…).
  final PersonProfileInput? personProfile;
}
