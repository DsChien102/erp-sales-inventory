import 'package:vet45_shared_application/application.dart';

import '../../shared/auth_session_state.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import '../../shared/session_dto.dart';
import '../../../ports/i_authenticator.dart';
import '../../../ports/i_iam_session_port.dart';
import 'get_current_session_query.dart';

@QueryHandlerFor(GetCurrentSessionQuery)
final class GetCurrentSessionQueryHandler
    implements IQueryHandler<GetCurrentSessionQuery, SessionDto> {
  GetCurrentSessionQueryHandler({
    required IAuthenticator authenticator,
    required IIamSessionPort sessionPort,
  }) : _authenticator = authenticator,
       _sessionPort = sessionPort;

  final IAuthenticator _authenticator;
  final IIamSessionPort _sessionPort;

  @override
  Future<SessionDto> handle(GetCurrentSessionQuery query) async {
    switch (_authenticator.sessionState) {
      case AuthSessionState.absent:
        return const SessionDto(isAuthenticated: false);
      case AuthSessionState.active:
        return _sessionPort.snapshot;
      case AuthSessionState.expired:
        await _sessionPort.clear();
        throw IamBlockedException(IamBlockedCodes.sessionExpired);
    }
  }
}
