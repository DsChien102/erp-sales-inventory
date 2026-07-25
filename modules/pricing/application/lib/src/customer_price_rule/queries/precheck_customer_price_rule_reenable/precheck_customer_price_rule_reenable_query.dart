import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'customer_price_rule_reenable_precheck_dto.dart';

@RequiresPermission(PricingPermissions.reenableCustomerPriceRule)
@RequiresTenant()
final class PrecheckCustomerPriceRuleReenableQuery
    extends QueryBase<CustomerPriceRuleReenablePrecheckDto>
    implements
        IQuery<CustomerPriceRuleReenablePrecheckDto>,
        ITenantScopedCommand {
  PrecheckCustomerPriceRuleReenableQuery({
    String? id,
    this.tenantId = '',
    required this.ruleId,
    required this.expectedVersion,
    required DateTime businessDate,
  }) : businessDate = DateTime.utc(
         businessDate.year,
         businessDate.month,
         businessDate.day,
       ),
       super(id);

  @override
  final String tenantId;
  final String ruleId;
  final int expectedVersion;
  final DateTime businessDate;

  PrecheckCustomerPriceRuleReenableQuery withExecutionContext({
    required String tenantId,
  }) => PrecheckCustomerPriceRuleReenableQuery(
    id: id,
    tenantId: tenantId,
    ruleId: ruleId,
    expectedVersion: expectedVersion,
    businessDate: businessDate,
  );
}
