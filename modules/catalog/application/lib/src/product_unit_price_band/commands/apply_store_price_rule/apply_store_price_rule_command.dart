import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'apply_store_price_rule_result.dart';

@RequiresPermission(CatalogPermissions.managePricing)
@RequiresTenant()
final class ApplyStorePriceRuleCommand extends CommandBase<ApplyStorePriceRuleResult>
    implements ICommand<ApplyStorePriceRuleResult>, ITenantScopedCommand {
  ApplyStorePriceRuleCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    this.storePriceRuleId,
    this.confirmOverwrite = false,
    this.basePriceVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final String? productUnitId;
  final String? storePriceRuleId;
  final bool confirmOverwrite;
  final int? basePriceVersion;
}
