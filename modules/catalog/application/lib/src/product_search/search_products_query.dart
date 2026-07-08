import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_search_result_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class SearchProductsQuery extends QueryBase<ProductSearchResultDto>
    implements IQuery<ProductSearchResultDto>, ITenantScopedCommand {
  SearchProductsQuery({
    String? id,
    required this.tenantId,
    required this.criteria,
    this.limit = 50,
    this.offset = 0,
  }) : super(id);

  @override
  final String tenantId;
  final ProductSearchCriteria criteria;
  final int limit;
  final int offset;
}
