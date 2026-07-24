import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_store_price_rule_result.dart';
import 'package:vet45_catalog_application/src/store_price_rule/shared/store_price_rule_status.dart';

@RequiresPermission(CatalogPermissions.manageStorePriceRule)
@RequiresTenant()
final class SetStorePriceRuleCommand extends CommandBase<SetStorePriceRuleResult>
    implements ICommand<SetStorePriceRuleResult>, ITenantScopedCommand {
  SetStorePriceRuleCommand({
    String? id,
    required this.tenantId,
    required this.name,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
    this.status = StorePriceRuleStatus.active,
  }) : super(id);

  @override
  final String tenantId;
  final String name;
  final double listMarkupRatio;
  final double floorMarkupRatio;
  final StorePriceRuleStatus status;
}
