import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_control_center_dto.dart';

@RequiresPermission(CatalogPermissions.viewDetail)
@RequiresTenant()
final class GetProductControlCenterQuery extends QueryBase<ProductControlCenterDto>
    implements IQuery<ProductControlCenterDto>, ITenantScopedCommand {
  GetProductControlCenterQuery({
    String? id,
    required this.tenantId,
    required this.productId,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
}
