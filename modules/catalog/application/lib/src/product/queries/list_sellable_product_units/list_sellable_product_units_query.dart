import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_unit_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class ListSellableProductUnitsQuery extends QueryBase<List<SellableProductUnitDto>>
    implements IQuery<List<SellableProductUnitDto>>, ITenantScopedCommand {
  ListSellableProductUnitsQuery({
    String? id,
    required this.tenantId,
    required this.storeId,
    required this.productId,
  }) : super(id);

  @override
  final String tenantId;
  final String storeId;
  final String productId;
}
