import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_deletion_eligibility_dto.dart';

@RequiresPermission(CatalogPermissions.delete)
@RequiresTenant()
final class CheckProductDeletionEligibilityQuery extends QueryBase<ProductDeletionEligibilityDto>
    implements IQuery<ProductDeletionEligibilityDto>, ITenantScopedCommand {
  CheckProductDeletionEligibilityQuery({
    String? id,
    required this.tenantId,
    required this.productId,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
}
