import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/store_price_rule/shared/store_price_rule_dto.dart';

@RequiresPermission(CatalogPermissions.manageStorePriceRule)
@RequiresTenant()
final class GetStorePriceRuleQuery extends QueryBase<StorePriceRuleDto?>
    implements IQuery<StorePriceRuleDto?>, ITenantScopedCommand {
  GetStorePriceRuleQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
