import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class CheckDuplicateMeasurementUnitNameQuery extends QueryBase<bool>
    implements IQuery<bool>, ITenantScopedCommand {
  CheckDuplicateMeasurementUnitNameQuery({
    String? id,
    required this.tenantId,
    required this.name,
  }) : super(id);

  @override
  final String tenantId;

  final String name;
}
