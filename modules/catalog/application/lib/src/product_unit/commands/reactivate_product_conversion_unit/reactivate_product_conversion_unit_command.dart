import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_mutation_result.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class ReactivateProductConversionUnitCommand extends CommandBase<ProductUnitMutationResult>
    implements ICommand<ProductUnitMutationResult>, ITenantScopedCommand {
  ReactivateProductConversionUnitCommand({
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
