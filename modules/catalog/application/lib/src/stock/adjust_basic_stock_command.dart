import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'adjust_basic_stock_result.dart';

@RequiresPermission(CatalogPermissions.manageStock)
@RequiresTenant()
final class AdjustBasicStockCommand extends CommandBase<AdjustBasicStockResult>
    implements ICommand<AdjustBasicStockResult>, ITenantScopedCommand {
  AdjustBasicStockCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.newQuantity,
    this.reason,
    this.expectedQuantity,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final double newQuantity;
  final String? reason;
  final double? expectedQuantity;
}
