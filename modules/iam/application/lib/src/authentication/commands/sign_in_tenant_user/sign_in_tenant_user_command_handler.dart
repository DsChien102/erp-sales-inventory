import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_authenticator.dart';
import '../../../ports/i_iam_session_port.dart';
import 'sign_in_tenant_user_command.dart';

@CommandHandlerFor(SignInTenantUserCommand)
final class SignInTenantUserCommandHandler
    implements ICommandHandler<SignInTenantUserCommand, void> {
  SignInTenantUserCommandHandler({
    required IAuthenticator authenticator,
    required IIamSessionPort sessionPort,
  }) : _authenticator = authenticator,
       _sessionPort = sessionPort;

  final IAuthenticator _authenticator;
  final IIamSessionPort _sessionPort;

  @override
  Future<void> handle(SignInTenantUserCommand command) async {
    await _authenticator.signIn(
      email: command.email,
      password: command.password,
    );
    final userId = _authenticator.currentUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw ApplicationException('Not authenticated');
    }
    _sessionPort.applyAuthenticatedUser(userId);
  }
}
