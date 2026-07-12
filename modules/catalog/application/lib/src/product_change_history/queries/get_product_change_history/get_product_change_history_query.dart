import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_category.dart';
import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_result_dto.dart';

@RequiresPermission(CatalogPermissions.viewHistory)
@RequiresTenant()
final class GetProductChangeHistoryQuery extends QueryBase<ProductChangeHistoryResultDto>
    implements IQuery<ProductChangeHistoryResultDto>, ITenantScopedCommand {
  GetProductChangeHistoryQuery({
    String? id,
    required this.tenantId,
    required this.productId,
    this.limit = 50,
    this.offset = 0,
    this.changeCategories = const [],
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final int limit;
  final int offset;
  final List<ProductChangeCategory> changeCategories;
}
