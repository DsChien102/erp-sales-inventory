import 'package:vet45_shared_application/application.dart';

import '../../dto/session_dto.dart';
import '../../ports/i_iam_session_port.dart';
import 'get_current_session_query.dart';

final class GetCurrentSessionQueryHandler
    implements IQueryHandler<GetCurrentSessionQuery, SessionDto> {
  GetCurrentSessionQueryHandler({required IIamSessionPort sessionPort})
    : _sessionPort = sessionPort;

  final IIamSessionPort _sessionPort;

  @override
  Future<SessionDto> handle(GetCurrentSessionQuery query) {
    return Future.value(_sessionPort.snapshot);
  }
}
