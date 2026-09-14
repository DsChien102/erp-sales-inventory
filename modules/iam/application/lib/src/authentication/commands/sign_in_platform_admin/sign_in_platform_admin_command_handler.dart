import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_authenticator.dart';
import '../../../ports/i_iam_session_port.dart';
import '../../../ports/i_platform_admin_gateway.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import 'sign_in_platform_admin_command.dart';

@CommandHandlerFor(SignInPlatformAdminCommand)
final class SignInPlatformAdminCommandHandler
    implements ICommandHandler<SignInPlatformAdminCommand, void> {
  SignInPlatformAdminCommandHandler({
    required IAuthenticator authenticator,
    required IIamSessionPort sessionPort,
    required IPlatformAdminGateway platformAdminGateway,
  }) : _authenticator = authenticator,
       _sessionPort = sessionPort,
       _platformAdminGateway = platformAdminGateway;

  final IAuthenticator _authenticator;
  final IIamSessionPort _sessionPort;
  final IPlatformAdminGateway _platformAdminGateway;

  @override
  Future<void> handle(SignInPlatformAdminCommand command) async {
    await _authenticator.signIn(
      email: command.email,
      password: command.password,
    );

    final allowed = await _platformAdminGateway.hasPlatformPermission(
      IamPlatformPermissions.userView,
    );
    if (!allowed) {
      await _authenticator.signOut();
      _sessionPort.clear();
      throw const IamBlockedException(IamBlockedCodes.platformPermissionDenied);
    }

    final userId = _authenticator.currentUserId;
    if (userId == null || userId.trim().isEmpty) {
      await _authenticator.signOut();
      _sessionPort.clear();
      throw ApplicationException('Not authenticated');
    }
    _sessionPort.applyAuthenticatedUser(userId);
  }
}
