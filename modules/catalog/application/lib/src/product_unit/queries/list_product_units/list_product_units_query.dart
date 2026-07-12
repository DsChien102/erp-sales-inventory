import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_unit/shared/product_units_dto.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class ListProductUnitsQuery extends QueryBase<ProductUnitsDto>
    implements IQuery<ProductUnitsDto>, ITenantScopedCommand {
  ListProductUnitsQuery({
    String? id,
    required this.tenantId,
    required this.productId,
    this.includeInactive = false,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
  final bool includeInactive;
}
