import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'store_price_rule_dto.dart';

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
