import 'package:vet45_shared_application/application.dart';

import '../../dto/session_dto.dart';

@PublicAccess()
final class GetCurrentSessionQuery extends QueryBase<SessionDto> {
  GetCurrentSessionQuery({String? id}) : super(id);
}
