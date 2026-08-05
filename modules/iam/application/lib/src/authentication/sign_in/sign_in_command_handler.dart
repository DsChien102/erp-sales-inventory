import 'package:vet45_shared_application/application.dart';

import '../../ports/i_authenticator.dart';
import '../../ports/i_iam_session_port.dart';
import 'sign_in_command.dart';

@CommandHandlerFor(SignInCommand)
final class SignInCommandHandler implements ICommandHandler<SignInCommand, void> {
  SignInCommandHandler({
    required IAuthenticator authenticator,
    required IIamSessionPort sessionPort,
  }) : _authenticator = authenticator,
       _sessionPort = sessionPort;

  final IAuthenticator _authenticator;
  final IIamSessionPort _sessionPort;

  @override
  Future<void> handle(SignInCommand command) async {
    await _authenticator.signIn(
      email: command.email,
      password: command.password,
    );
    await _sessionPort.establishAfterSignIn(
      requireTenantContext: command.requireTenantContext,
    );
  }
}
