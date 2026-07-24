import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_readiness_view_dto.dart';

@RequiresPermission(CatalogPermissions.viewDetail)
@RequiresTenant()
final class GetProductReadinessQuery extends QueryBase<ProductReadinessViewDto>
    implements IQuery<ProductReadinessViewDto>, ITenantScopedCommand {
  GetProductReadinessQuery({
    String? id,
    required this.tenantId,
    required this.productId,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
}
