import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'tenant_measurement_unit_dto.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class ListTenantMeasurementUnitsQuery
    extends QueryBase<List<TenantMeasurementUnitDto>>
    implements IQuery<List<TenantMeasurementUnitDto>>, ITenantScopedCommand {
  ListTenantMeasurementUnitsQuery({
    String? id,
    required this.tenantId,
    this.keyword,
    this.limit = 50,
  }) : super(id);

  @override
  final String tenantId;

  final String? keyword;
  final int limit;
}
