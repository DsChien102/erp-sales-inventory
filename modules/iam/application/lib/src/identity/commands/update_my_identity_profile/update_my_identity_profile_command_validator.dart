import 'package:vet45_shared_application/application.dart';

import 'update_my_identity_profile_command.dart';

final class UpdateMyIdentityProfileCommandValidator
    implements ICommandValidator<UpdateMyIdentityProfileCommand> {
  @override
  Future<void> validate(UpdateMyIdentityProfileCommand command) async {
    if (command.firstName.trim().isEmpty) {
      throw ValidationException('firstName is required');
    }
    if (command.lastName.trim().isEmpty) {
      throw ValidationException('lastName is required');
    }
  }
}
