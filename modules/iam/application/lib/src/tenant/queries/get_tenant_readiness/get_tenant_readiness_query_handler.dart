import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_readiness_dto.dart';
import '../../../ports/i_tenant_readiness_gateway.dart';
import 'get_tenant_readiness_query.dart';

@QueryHandlerFor(GetTenantReadinessQuery)
final class GetTenantReadinessQueryHandler
    implements IQueryHandler<GetTenantReadinessQuery, TenantReadinessDto> {
  GetTenantReadinessQueryHandler({
    required ITenantReadinessGateway readinessGateway,
  }) : _readinessGateway = readinessGateway;

  final ITenantReadinessGateway _readinessGateway;

  @override
  Future<TenantReadinessDto> handle(GetTenantReadinessQuery query) {
    return _readinessGateway.getReadiness(tenantId: query.tenantId);
  }
}
