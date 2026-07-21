import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_user_detail_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'get_platform_user_query.dart';

@QueryHandlerFor(GetPlatformUserQuery)
final class GetPlatformUserQueryHandler
    implements IQueryHandler<GetPlatformUserQuery, PlatformUserDetailDto> {
  GetPlatformUserQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<PlatformUserDetailDto> handle(GetPlatformUserQuery query) {
    return _platformGateway.getPlatformUser(query.userId);
  }
}
