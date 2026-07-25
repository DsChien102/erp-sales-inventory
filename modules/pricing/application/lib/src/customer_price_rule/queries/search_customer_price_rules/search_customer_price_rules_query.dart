import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'customer_price_rule_search_enums.dart';
import 'customer_price_rule_search_result_dto.dart';

@RequiresPermission(PricingPermissions.viewCustomerPriceRule)
@RequiresTenant()
final class SearchCustomerPriceRulesQuery
    extends QueryBase<CustomerPriceRuleSearchResultDto>
    implements IQuery<CustomerPriceRuleSearchResultDto>, ITenantScopedCommand {
  SearchCustomerPriceRulesQuery({
    String? id,
    this.tenantId = '',
    String? q,
    this.quickFilter = CustomerPriceRuleQuickFilter.all,
    List<CustomerPriceRuleDerivedStatus> statuses = const [],
    List<CustomerPriceRuleSourceType> sources = const [],
    this.customerId,
    this.productId,
    required DateTime businessDate,
    String? cursor,
    this.limit = 20,
  }) : q = _normalizeOptionalText(q),
       statuses = List.unmodifiable(statuses),
       sources = List.unmodifiable(sources),
       businessDate = _calendarDateUtc(businessDate),
       cursor = _normalizeOptionalText(cursor),
       super(id);

  @override
  final String tenantId;
  final String? q;
  final CustomerPriceRuleQuickFilter quickFilter;
  final List<CustomerPriceRuleDerivedStatus> statuses;
  final List<CustomerPriceRuleSourceType> sources;
  final String? customerId;
  final String? productId;
  final DateTime businessDate;
  final String? cursor;
  final int limit;

  SearchCustomerPriceRulesQuery withExecutionContext({
    required String tenantId,
  }) => SearchCustomerPriceRulesQuery(
    id: id,
    tenantId: tenantId,
    q: q,
    quickFilter: quickFilter,
    statuses: statuses,
    sources: sources,
    customerId: customerId,
    productId: productId,
    businessDate: businessDate,
    cursor: cursor,
    limit: limit,
  );
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

DateTime _calendarDateUtc(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
