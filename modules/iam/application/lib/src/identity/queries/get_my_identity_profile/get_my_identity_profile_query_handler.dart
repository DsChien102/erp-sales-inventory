import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_identity_self_service_port.dart';
import '../../shared/my_identity_profile_dto.dart';
import '../../shared/my_identity_profile_mapper.dart';
import 'get_my_identity_profile_query.dart';

@QueryHandlerFor(GetMyIdentityProfileQuery)
final class GetMyIdentityProfileQueryHandler
    implements IQueryHandler<GetMyIdentityProfileQuery, MyIdentityProfileDto> {
  GetMyIdentityProfileQueryHandler({
    required IPlatformIdentitySelfServicePort identityPort,
  }) : _identityPort = identityPort;

  final IPlatformIdentitySelfServicePort _identityPort;

  @override
  Future<MyIdentityProfileDto> handle(GetMyIdentityProfileQuery query) async {
    final account = await _identityPort.getMyAccount();
    return myIdentityProfileFromAccount(account);
  }
}
