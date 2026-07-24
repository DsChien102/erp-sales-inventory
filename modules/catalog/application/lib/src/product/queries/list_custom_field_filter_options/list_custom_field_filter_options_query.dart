import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'custom_field_filter_option_dto.dart';

@RequiresPermission(CatalogPermissions.view)
@RequiresTenant()
final class ListCustomFieldFilterOptionsQuery extends QueryBase<List<CustomFieldFilterOptionDto>>
    implements IQuery<List<CustomFieldFilterOptionDto>>, ITenantScopedCommand {
  ListCustomFieldFilterOptionsQuery({
    String? id,
    required this.tenantId,
    this.maxOptionsPerField = 50,
  }) : super(id);

  @override
  final String tenantId;
  final int maxOptionsPerField;
}
