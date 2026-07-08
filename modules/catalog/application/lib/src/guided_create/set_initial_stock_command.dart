import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../stock/set_initial_stock_result.dart';

@RequiresPermission(CatalogPermissions.manageStock)
@RequiresTenant()
final class SetInitialStockCommand extends CommandBase<SetInitialStockResult>
    implements ICommand<SetInitialStockResult>, ITenantScopedCommand {
  SetInitialStockCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.quantity,
    this.mode = 'basic',
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final double quantity;
  final String mode;
}
