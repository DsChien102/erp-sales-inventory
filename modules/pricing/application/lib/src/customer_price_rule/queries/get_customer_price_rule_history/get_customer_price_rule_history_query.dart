import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/cursor_page_dto.dart';
import 'customer_price_rule_activity_dto.dart';

@RequiresPermission(PricingPermissions.viewCustomerPriceRuleHistory)
@RequiresTenant()
final class GetCustomerPriceRuleHistoryQuery
    extends QueryBase<CursorPageDto<CustomerPriceRuleActivityDto>>
    implements
        IQuery<CursorPageDto<CustomerPriceRuleActivityDto>>,
        ITenantScopedCommand {
  GetCustomerPriceRuleHistoryQuery({
    String? id,
    this.tenantId = '',
    required this.ruleId,
    String? cursor,
    this.limit = 50,
  }) : cursor = _normalizeOptionalText(cursor),
       super(id);

  @override
  final String tenantId;
  final String ruleId;
  final String? cursor;
  final int limit;

  GetCustomerPriceRuleHistoryQuery withExecutionContext({
    required String tenantId,
  }) => GetCustomerPriceRuleHistoryQuery(
    id: id,
    tenantId: tenantId,
    ruleId: ruleId,
    cursor: cursor,
    limit: limit,
  );
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
