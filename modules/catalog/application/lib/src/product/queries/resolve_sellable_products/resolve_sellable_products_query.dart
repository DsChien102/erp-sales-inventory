import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_resolution_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class ResolveSellableProductsQuery
    extends QueryBase<List<SellableProductResolutionDto>>
    implements IQuery<List<SellableProductResolutionDto>>, ITenantScopedCommand {
  ResolveSellableProductsQuery({
    String? id,
    required this.tenantId,
    required this.storeId,
    required List<String> productIds,
  }) : productIds = List.unmodifiable(productIds),
       super(id);

  /// Maximum ids accepted in one batch.
  static const maxProductIds = 200;

  @override
  final String tenantId;
  final String storeId;
  final List<String> productIds;
}
