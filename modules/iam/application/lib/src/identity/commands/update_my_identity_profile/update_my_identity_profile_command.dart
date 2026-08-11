import 'package:vet45_shared_application/application.dart';

import '../../shared/my_identity_profile_dto.dart';

@PublicAccess()
final class UpdateMyIdentityProfileCommand
    extends CommandBase<MyIdentityProfileDto>
    implements ICommand<MyIdentityProfileDto> {
  UpdateMyIdentityProfileCommand({
    String? id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
  }) : super(id);

  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarUrl;
}
