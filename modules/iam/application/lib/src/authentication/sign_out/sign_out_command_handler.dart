import 'package:vet45_shared_application/application.dart';

import '../../ports/i_authenticator.dart';
import '../../ports/i_iam_session_port.dart';
import 'sign_out_command.dart';

@CommandHandlerFor(SignOutCommand)
final class SignOutCommandHandler
    implements ICommandHandler<SignOutCommand, void> {
  SignOutCommandHandler({
    required IAuthenticator authenticator,
    required IIamSessionPort sessionPort,
  }) : _authenticator = authenticator,
       _sessionPort = sessionPort;

  final IAuthenticator _authenticator;
  final IIamSessionPort _sessionPort;

  @override
  Future<void> handle(SignOutCommand command) async {
    await _authenticator.signOut();
    await _sessionPort.clear();
  }
}
