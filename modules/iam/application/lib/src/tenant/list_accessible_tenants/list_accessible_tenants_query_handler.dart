import 'package:vet45_shared_application/application.dart';

import '../../dto/accessible_tenant_dto.dart';
import '../../ports/i_iam_access_gateway.dart';
import 'list_accessible_tenants_query.dart';

@QueryHandlerFor(ListAccessibleTenantsQuery)
final class ListAccessibleTenantsQueryHandler
    implements
        IQueryHandler<ListAccessibleTenantsQuery, List<AccessibleTenantDto>> {
  ListAccessibleTenantsQueryHandler({
    required IIamAccessGateway accessGateway,
    required ICurrentTenant currentTenant,
  }) : _accessGateway = accessGateway,
       _currentTenant = currentTenant;

  final IIamAccessGateway _accessGateway;
  final ICurrentTenant _currentTenant;

  @override
  Future<List<AccessibleTenantDto>> handle(
    ListAccessibleTenantsQuery query,
  ) async {
    final tenants = await _accessGateway.listAccessibleTenants();
    final currentTenantId = _currentTenant.tenantId;
    return tenants
        .map(
          (tenant) => tenant.copyWith(
            isCurrent: currentTenantId != null &&
                tenant.tenantId == currentTenantId,
          ),
        )
        .toList(growable: false);
  }
}
