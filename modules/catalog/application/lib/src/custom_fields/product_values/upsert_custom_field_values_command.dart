import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_custom_field_value_input.dart';
import 'upsert_custom_field_values_result.dart';

@RequiresPermission(CatalogPermissions.update)
@RequiresTenant()
final class UpsertCustomFieldValuesCommand extends CommandBase<UpsertCustomFieldValuesResult>
    implements ICommand<UpsertCustomFieldValuesResult>, ITenantScopedCommand {
  UpsertCustomFieldValuesCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    this.values = const [],
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
  final List<ProductCustomFieldValueInput> values;
}
