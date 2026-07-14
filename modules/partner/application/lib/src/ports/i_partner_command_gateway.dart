import '../partner/commands/add_organization_contact/add_organization_contact_command.dart';
import '../partner/commands/add_organization_contact/add_organization_contact_result.dart';
import '../partner/commands/create_partner/create_partner_command.dart';
import '../partner/commands/create_partner/create_partner_result.dart';
import '../partner/commands/deactivate_partner/deactivate_partner_command.dart';
import '../partner/commands/deactivate_partner/deactivate_partner_result.dart';
import '../partner/commands/reactivate_partner/reactivate_partner_command.dart';
import '../partner/commands/reactivate_partner/reactivate_partner_result.dart';
import '../partner/commands/remove_organization_contact/remove_organization_contact_command.dart';
import '../partner/commands/soft_delete_partner/soft_delete_partner_command.dart';
import '../partner/commands/soft_delete_partner/soft_delete_partner_result.dart';
import '../partner/commands/transform_to_organization/transform_partner_result.dart';
import '../partner/commands/transform_to_organization/transform_person_to_organization_command.dart';
import '../partner/commands/update_organization_contact/update_organization_contact_command.dart';
import '../partner/commands/update_partner_profile/update_partner_profile_command.dart';
import '../partner/commands/update_partner_profile/update_partner_profile_result.dart';

/// Mutation port — infrastructure implements via Supabase RPC.
abstract interface class IPartnerCommandGateway {
  Future<CreatePartnerResult> createPartner(CreatePartnerCommand command);

  Future<UpdatePartnerProfileResult> updatePartnerProfile(
    UpdatePartnerProfileCommand command,
  );

  Future<TransformPartnerResult> transformPersonToOrganization(
    TransformPersonToOrganizationCommand command,
  );

  Future<AddOrganizationContactResult> addOrganizationContact(
    AddOrganizationContactCommand command,
  );

  Future<void> updateOrganizationContact(
    UpdateOrganizationContactCommand command,
  );

  Future<void> removeOrganizationContact(
    RemoveOrganizationContactCommand command,
  );

  Future<DeactivatePartnerResult> deactivatePartner(
    DeactivatePartnerCommand command,
  );

  Future<ReactivatePartnerResult> reactivatePartner(
    ReactivatePartnerCommand command,
  );

  Future<SoftDeletePartnerResult> softDeletePartner(
    SoftDeletePartnerCommand command,
  );
}
