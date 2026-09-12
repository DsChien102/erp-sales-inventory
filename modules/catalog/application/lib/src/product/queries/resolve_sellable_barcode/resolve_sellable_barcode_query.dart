import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class ResolveSellableBarcodeQuery extends QueryBase<List<SellableProductDto>>
    implements IQuery<List<SellableProductDto>>, ITenantScopedCommand {
  ResolveSellableBarcodeQuery({
    String? id,
    required this.tenantId,
    required this.storeId,
    required this.barcode,
  }) : super(id);

  @override
  final String tenantId;
  final String storeId;
  final String barcode;
}
