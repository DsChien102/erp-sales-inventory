import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'initialize_custom_field_template_result.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class InitializeCustomFieldTemplateCommand
    extends CommandBase<InitializeCustomFieldTemplateResult>
    implements ICommand<InitializeCustomFieldTemplateResult>, ITenantScopedCommand {
  InitializeCustomFieldTemplateCommand({
    String? id,
    required this.tenantId,
    this.templateId,
  }) : super(id);

  @override
  final String tenantId;

  final String? templateId;
}
