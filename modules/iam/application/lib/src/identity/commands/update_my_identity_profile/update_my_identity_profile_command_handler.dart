import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_identity_self_service_port.dart';
import '../../shared/my_identity_profile_dto.dart';
import '../../shared/my_identity_profile_mapper.dart';
import 'update_my_identity_profile_command.dart';

@CommandHandlerFor(UpdateMyIdentityProfileCommand)
final class UpdateMyIdentityProfileCommandHandler
    implements
        ICommandHandler<UpdateMyIdentityProfileCommand, MyIdentityProfileDto> {
  UpdateMyIdentityProfileCommandHandler({
    required IPlatformIdentitySelfServicePort identityPort,
  }) : _identityPort = identityPort;

  final IPlatformIdentitySelfServicePort _identityPort;

  @override
  Future<MyIdentityProfileDto> handle(
    UpdateMyIdentityProfileCommand command,
  ) async {
    final account = await _identityPort.updateMyAccount(
      avatarReference: command.avatarUrl?.trim(),
      givenName: command.firstName.trim(),
      familyName: command.lastName.trim(),
      phone: command.phoneNumber?.trim(),
    );
    return myIdentityProfileFromAccount(account);
  }
}
