import 'package:vet45_shared_application/application.dart';

import '../../shared/session_dto.dart';

@PublicAccess()
final class GetCurrentSessionQuery extends QueryBase<SessionDto>
    implements IQuery<SessionDto> {
  GetCurrentSessionQuery({String? id}) : super(id);
}
