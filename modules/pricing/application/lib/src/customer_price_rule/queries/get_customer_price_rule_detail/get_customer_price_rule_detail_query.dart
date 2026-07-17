import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_detail_dto.dart';

@RequiresPermission(PricingPermissions.viewCustomerPriceRule)
@RequiresTenant()
final class GetCustomerPriceRuleDetailQuery
    extends QueryBase<CustomerPriceRuleDetailDto>
    implements IQuery<CustomerPriceRuleDetailDto>, ITenantScopedCommand {
  GetCustomerPriceRuleDetailQuery({
    String? id,
    this.tenantId = '',
    required this.ruleId,
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
  final DateTime businessDate;

  GetCustomerPriceRuleDetailQuery withExecutionContext({
    required String tenantId,
  }) => GetCustomerPriceRuleDetailQuery(
    id: id,
    tenantId: tenantId,
    ruleId: ruleId,
    businessDate: businessDate,
  );
}
