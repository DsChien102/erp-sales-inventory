import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_custom_field_snapshot_dto.dart';

@RequiresPermission(CatalogPermissions.viewDetail)
@RequiresTenant()
final class GetProductCustomFieldSnapshotQuery
    extends QueryBase<ProductCustomFieldSnapshotDto>
    implements IQuery<ProductCustomFieldSnapshotDto>, ITenantScopedCommand {
  GetProductCustomFieldSnapshotQuery({
    String? id,
    required this.tenantId,
    required this.productIds,
    this.includeInactiveValues = false,
  }) : super(id);

  @override
  final String tenantId;
  final List<String> productIds;
  final bool includeInactiveValues;
}
