import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class DeleteProductConversionUnitCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  DeleteProductConversionUnitCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.productUnitId,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
  final String productUnitId;
}
