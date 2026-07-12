import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/shared/base_unit_selection.dart';
import 'set_product_base_unit_result.dart';

@RequiresPermission(CatalogPermissions.manageUnits)
@RequiresTenant()
final class SetProductBaseUnitCommand extends CommandBase<SetProductBaseUnitResult>
    implements ICommand<SetProductBaseUnitResult>, ITenantScopedCommand {
  SetProductBaseUnitCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.selection,
  }) : super(id);

  @override
  final String tenantId;

  final String productId;
  final BaseUnitSelection selection;
}
