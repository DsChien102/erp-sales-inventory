import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_stock_profile/commands/set_basic_stock_quantity_base/set_basic_stock_quantity_base_result.dart';

@RequiresPermission(CatalogPermissions.manageStock)
@RequiresTenant()
final class SetBasicStockQuantityBaseCommand extends CommandBase<SetBasicStockQuantityBaseResult>
    implements ICommand<SetBasicStockQuantityBaseResult>, ITenantScopedCommand {
  SetBasicStockQuantityBaseCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.quantity,
    this.mode = 'basic',
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final int quantity;
  final String mode;
}
