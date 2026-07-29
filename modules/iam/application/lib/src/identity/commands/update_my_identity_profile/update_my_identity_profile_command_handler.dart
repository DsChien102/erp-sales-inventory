import 'package:vet45_shared_application/application.dart';

import '../../ports/i_identity_self_service_gateway.dart';
import '../../shared/my_identity_profile_dto.dart';
import 'update_my_identity_profile_command.dart';

@CommandHandlerFor(UpdateMyIdentityProfileCommand)
final class UpdateMyIdentityProfileCommandHandler
    implements
        ICommandHandler<UpdateMyIdentityProfileCommand, MyIdentityProfileDto> {
  UpdateMyIdentityProfileCommandHandler({
    required IIdentitySelfServiceGateway identityGateway,
  }) : _identityGateway = identityGateway;

  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<MyIdentityProfileDto> handle(
    UpdateMyIdentityProfileCommand command,
  ) {
    return _identityGateway.updateMyIdentityProfile(
      firstName: command.firstName.trim(),
      lastName: command.lastName.trim(),
      phoneNumber: command.phoneNumber?.trim(),
      avatarUrl: command.avatarUrl?.trim(),
    );
  }
}
