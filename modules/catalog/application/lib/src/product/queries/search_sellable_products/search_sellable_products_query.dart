import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class SearchSellableProductsQuery extends QueryBase<List<SellableProductDto>>
    implements IQuery<List<SellableProductDto>>, ITenantScopedCommand {
  SearchSellableProductsQuery({
    String? id,
    required this.tenantId,
    required this.storeId,
    required this.keyword,
    this.limit = 50,
    this.offset = 0,
  }) : super(id);

  @override
  final String tenantId;
  final String storeId;
  final String keyword;
  final int limit;
  final int offset;
}
