import 'package:vet45_shared_application/application.dart';

import '../../shared/my_identity_profile_dto.dart';

@PublicAccess()
final class GetMyIdentityProfileQuery extends QueryBase<MyIdentityProfileDto>
    implements IQuery<MyIdentityProfileDto> {
  GetMyIdentityProfileQuery({String? id}) : super(id);
}
