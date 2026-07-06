import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_unit_price_bands_dto.dart';

@RequiresPermission(CatalogPermissions.viewDetail)
@RequiresTenant()
final class ListProductUnitPriceBandsQuery extends QueryBase<ProductUnitPriceBandsDto>
    implements IQuery<ProductUnitPriceBandsDto>, ITenantScopedCommand {
  ListProductUnitPriceBandsQuery({
    String? id,
    required this.tenantId,
    required this.productId,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
}
