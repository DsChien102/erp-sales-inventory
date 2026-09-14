import 'package:vet45_shared_application/application.dart';

import '../../shared/sign_out_result_dto.dart';
import '../../../ports/i_authenticator.dart';
import '../../../ports/i_iam_session_port.dart';
import 'sign_out_command.dart';

@CommandHandlerFor(SignOutCommand)
final class SignOutCommandHandler implements ICommandHandler<SignOutCommand, SignOutResultDto> {
  SignOutCommandHandler({
    required IAuthenticator authenticator,
    required IIamSessionPort sessionPort,
  }) : _authenticator = authenticator,
       _sessionPort = sessionPort;

  final IAuthenticator _authenticator;
  final IIamSessionPort _sessionPort;

  @override
  Future<SignOutResultDto> handle(SignOutCommand command) async {
    var remoteSucceeded = false;
    try {
      await _authenticator.signOut();
      remoteSucceeded = true;
    } catch (_) {
      remoteSucceeded = false;
    } finally {
      _sessionPort.clear();
    }
    return SignOutResultDto(
      localCleared: true,
      remoteSucceeded: remoteSucceeded,
    );
  }
}
