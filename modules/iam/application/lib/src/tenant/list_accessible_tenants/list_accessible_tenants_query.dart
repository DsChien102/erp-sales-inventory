import 'package:vet45_shared_application/application.dart';

import '../../dto/accessible_tenant_dto.dart';

/// Lists tenants the authenticated actor can access (EP-05/US-01).
///
/// Authenticated-only — no tenant scope / permission annotation.
/// RPC enforces via `auth.uid()`.
final class ListAccessibleTenantsQuery
    extends QueryBase<List<AccessibleTenantDto>>
    implements IQuery<List<AccessibleTenantDto>> {
  ListAccessibleTenantsQuery({String? id}) : super(id);
}
