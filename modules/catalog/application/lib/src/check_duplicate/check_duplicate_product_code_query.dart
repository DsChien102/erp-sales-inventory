import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_duplicate_match_dto.dart';

@RequiresPermission(CatalogPermissions.create)
@RequiresTenant()
final class CheckDuplicateProductCodeQuery
    extends QueryBase<List<ProductDuplicateMatchDto>>
    implements IQuery<List<ProductDuplicateMatchDto>>, ITenantScopedCommand {
  CheckDuplicateProductCodeQuery({
    String? id,
    required this.tenantId,
    this.sku,
    this.barcode,
    this.excludeProductId,
  }) : super(id);

  @override
  final String tenantId;

  final String? sku;
  final String? barcode;
  final String? excludeProductId;
}
