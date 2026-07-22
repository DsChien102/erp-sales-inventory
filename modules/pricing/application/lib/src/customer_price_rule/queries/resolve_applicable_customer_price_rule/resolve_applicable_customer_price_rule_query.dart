import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'resolve_applicable_customer_price_rule_result_dto.dart';

@RequiresPermission(PricingPermissions.viewCustomerPriceRule)
@RequiresTenant()
final class ResolveApplicableCustomerPriceRuleQuery
    extends QueryBase<ResolveApplicableCustomerPriceRuleResultDto>
    implements
        IQuery<ResolveApplicableCustomerPriceRuleResultDto>,
        ITenantScopedCommand {
  ResolveApplicableCustomerPriceRuleQuery({
    String? id,
    this.tenantId = '',
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required DateTime businessDate,
  }) : businessDate = DateTime.utc(
         businessDate.year,
         businessDate.month,
         businessDate.day,
       ),
       super(id);

  @override
  final String tenantId;
  final String customerId;
  final String productId;
  final String productUnitId;
  final DateTime businessDate;

  ResolveApplicableCustomerPriceRuleQuery withExecutionContext({
    required String tenantId,
  }) => ResolveApplicableCustomerPriceRuleQuery(
    id: id,
    tenantId: tenantId,
    customerId: customerId,
    productId: productId,
    productUnitId: productUnitId,
    businessDate: businessDate,
  );
}
