import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_custom_field_values_dto.dart';

@RequiresPermission(CatalogPermissions.viewDetail)
@RequiresTenant()
final class GetProductCustomFieldValuesQuery extends QueryBase<ProductCustomFieldValuesDto>
    implements IQuery<ProductCustomFieldValuesDto>, ITenantScopedCommand {
  GetProductCustomFieldValuesQuery({
    String? id,
    required this.tenantId,
    required this.productId,
    this.includeInactiveValues = false,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
  final bool includeInactiveValues;
}
