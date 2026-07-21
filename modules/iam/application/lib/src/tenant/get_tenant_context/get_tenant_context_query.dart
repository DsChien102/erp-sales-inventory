import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_context_dto.dart';

/// Reads / validates TenantContext (EP-05/US-03 + US-04).
///
/// When [bootstrapFromLastSelected] is true, BE reads LastSelectedTenant
/// preference then re-validates server-side (preference ≠ access grant).
/// OQ-07: on invalid preference with other accessible tenants, return
/// [TenantContextStatus.none] — do not auto-pick another tenant.
final class GetTenantContextQuery extends QueryBase<TenantContextDto>
    implements IQuery<TenantContextDto> {
  GetTenantContextQuery({
    String? id,
    this.bootstrapFromLastSelected = false,
  }) : super(id);

  /// US-03: app startup path — prefer LastSelectedTenant then validate.
  final bool bootstrapFromLastSelected;
}
