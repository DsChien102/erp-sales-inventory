import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'create_tenant_onboarding_command.dart';

final class CreateTenantOnboardingCommandValidator
    implements ICommandValidator<CreateTenantOnboardingCommand> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<void> validate(CreateTenantOnboardingCommand command) async {
    if (command.organizationName.trim().isEmpty) {
      throw ValidationException('Organization name is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }

    final hasLegal = (command.legalName ?? '').trim().isNotEmpty &&
        (command.taxCode ?? '').trim().isNotEmpty;
    if (hasLegal) {
      final type = LegalEntityTypeCodes.fromCode(command.legalEntityType);
      if (type == null) {
        throw ValidationException('Legal entity type is required');
      }
      if (TaxCodeFormatRule(entityType: type, taxCode: command.taxCode!)
          .isBroken()) {
        throw ValidationException('Tax code must be 10-13 digits');
      }
    }

    final owner = command.owner;
    if (owner.isExisting) {
      if (owner.existingUserId == null || owner.existingUserId!.trim().isEmpty) {
        throw ValidationException('Existing owner userId is required');
      }
      return;
    }

    if (!owner.isNewUser) {
      throw ValidationException(
        'Owner must be either an existing user or a new user',
      );
    }

    if ((owner.firstName ?? '').trim().isEmpty ||
        (owner.lastName ?? '').trim().isEmpty) {
      throw ValidationException('New owner first name and last name are required');
    }

    final email = owner.email?.trim() ?? '';
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      throw ValidationException('Valid owner email is required');
    }
  }
}
