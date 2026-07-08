import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_stock_history_dto.dart';

@RequiresPermission(CatalogPermissions.viewHistory)
@RequiresTenant()
final class GetProductStockHistoryQuery extends QueryBase<ProductStockHistoryDto>
    implements IQuery<ProductStockHistoryDto>, ITenantScopedCommand {
  GetProductStockHistoryQuery({
    String? id,
    required this.tenantId,
    required this.productId,
    this.limit = 50,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final int limit;
}
