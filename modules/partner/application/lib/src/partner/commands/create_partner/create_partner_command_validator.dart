import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'create_partner_command.dart';

final class CreatePartnerCommandValidator
    implements ICommandValidator<CreatePartnerCommand> {
  @override
  Future<void> validate(CreatePartnerCommand command) async {
    if (command.partnerType == PartnerType.person &&
        command.personProfile == null) {
      throw ArgumentError('personProfile is required for person partners');
    }
    if (command.partnerType == PartnerType.organization &&
        command.organizationProfile == null) {
      throw ArgumentError(
        'organizationProfile is required for organization partners',
      );
    }
    if (command.roles.isEmpty) {
      throw ArgumentError('roles must not be empty');
    }
  }
}
