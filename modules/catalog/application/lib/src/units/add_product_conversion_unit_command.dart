import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_unit_mutation_result.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class AddProductConversionUnitCommand extends CommandBase<ProductUnitMutationResult>
    implements ICommand<ProductUnitMutationResult>, ITenantScopedCommand {
  AddProductConversionUnitCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.unitName,
    required this.conversionRateToBase,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
  final String unitName;
  final double conversionRateToBase;
}
