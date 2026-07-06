import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_list_item_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class ScanBarcodeQuery extends QueryBase<ProductListItemDto?>
    implements IQuery<ProductListItemDto?>, ITenantScopedCommand {
  ScanBarcodeQuery({
    String? id,
    required this.tenantId,
    required this.barcode,
  }) : super(id);

  @override
  final String tenantId;
  final String barcode;
}
