import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_unit_price_band/queries/get_product_price_band_snapshot/product_price_band_snapshot_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/get_product_price_band_snapshot/product_price_band_snapshot_request.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class GetProductPriceBandSnapshotQuery extends QueryBase<ProductPriceBandSnapshotDto>
    implements IQuery<ProductPriceBandSnapshotDto>, ITenantScopedCommand {
  GetProductPriceBandSnapshotQuery({
    String? id,
    required this.tenantId,
    required this.items,
  }) : super(id);

  @override
  final String tenantId;
  final List<ProductPriceBandSnapshotRequest> items;
}
