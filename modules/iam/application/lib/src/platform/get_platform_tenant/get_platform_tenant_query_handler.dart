import 'package:vet45_shared_application/application.dart';

import '../../dto/platform_tenant_detail_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import 'get_platform_tenant_query.dart';

@QueryHandlerFor(GetPlatformTenantQuery)
final class GetPlatformTenantQueryHandler
    implements IQueryHandler<GetPlatformTenantQuery, PlatformTenantDetailDto> {
  GetPlatformTenantQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<PlatformTenantDetailDto> handle(GetPlatformTenantQuery query) {
    return _platformGateway.getPlatformTenant(query.tenantId);
  }
}
