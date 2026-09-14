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
        final snapshot = _sessionPort.snapshot;
        return SessionDto(
          isAuthenticated: snapshot.isAuthenticated,
          userId: snapshot.userId,
          email: _authenticator.currentEmail,
          tenantId: snapshot.tenantId,
          activeStoreId: snapshot.activeStoreId,
          role: snapshot.role,
          isOwner: snapshot.isOwner,
          permissions: snapshot.permissions,
        );
      case AuthSessionState.expired:
        _sessionPort.clear();
        throw IamBlockedException(IamBlockedCodes.sessionExpired);
    }
  }
}
