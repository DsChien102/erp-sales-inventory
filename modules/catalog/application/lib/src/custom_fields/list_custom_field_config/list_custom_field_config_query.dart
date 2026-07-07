import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../shared/custom_field_config_view_dto.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class ListCustomFieldConfigQuery extends QueryBase<CustomFieldConfigViewDto>
    implements IQuery<CustomFieldConfigViewDto>, ITenantScopedCommand {
  ListCustomFieldConfigQuery({String? id, required this.tenantId}) : super(id);

  @override
  final String tenantId;
}
