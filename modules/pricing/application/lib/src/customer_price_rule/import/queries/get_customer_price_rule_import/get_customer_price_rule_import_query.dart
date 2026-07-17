import 'package:vet45_pricing_domain/domain.dart'
    hide CustomerPriceRuleImportRowStatus;
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_import_detail_dto.dart';
import '../../shared/customer_price_rule_import_enums.dart';

@RequiresPermission(PricingPermissions.importCustomerPriceRule)
@RequiresTenant()
final class GetCustomerPriceRuleImportQuery
    extends QueryBase<CustomerPriceRuleImportDetailDto>
    implements IQuery<CustomerPriceRuleImportDetailDto>, ITenantScopedCommand {
  GetCustomerPriceRuleImportQuery({
    String? id,
    this.tenantId = '',
    required this.importId,
    this.rowStatus,
    String? cursor,
    this.limit = 50,
  }) : cursor = _normalizeOptional(cursor),
       super(id);

  @override
  final String tenantId;
  final String importId;
  final CustomerPriceRuleImportRowStatus? rowStatus;
  final String? cursor;
  final int limit;

  GetCustomerPriceRuleImportQuery withExecutionContext({
    required String tenantId,
  }) => GetCustomerPriceRuleImportQuery(
    id: id,
    tenantId: tenantId,
    importId: importId,
    rowStatus: rowStatus,
    cursor: cursor,
    limit: limit,
  );
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
