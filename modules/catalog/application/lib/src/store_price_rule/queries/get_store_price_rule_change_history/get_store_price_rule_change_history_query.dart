import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/store_price_rule/queries/get_store_price_rule_change_history/store_price_rule_change_history_result_dto.dart';

@RequiresPermission(CatalogPermissions.manageStorePriceRule)
@RequiresTenant()
final class GetStorePriceRuleChangeHistoryQuery
    extends QueryBase<StorePriceRuleChangeHistoryResultDto>
    implements IQuery<StorePriceRuleChangeHistoryResultDto>, ITenantScopedCommand {
  GetStorePriceRuleChangeHistoryQuery({
    String? id,
    required this.tenantId,
    this.limit = 50,
    this.offset = 0,
  }) : super(id);

  @override
  final String tenantId;
  final int limit;
  final int offset;
}
