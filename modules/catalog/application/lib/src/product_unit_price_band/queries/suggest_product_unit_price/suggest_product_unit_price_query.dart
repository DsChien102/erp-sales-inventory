import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_unit_price_suggestion_dto.dart';

@RequiresPermission(CatalogPermissions.managePricing)
@RequiresTenant()
final class SuggestProductUnitPriceQuery extends QueryBase<ProductUnitPriceSuggestionDto>
    implements IQuery<ProductUnitPriceSuggestionDto>, ITenantScopedCommand {
  SuggestProductUnitPriceQuery({
    String? id,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final String? productUnitId;
}
