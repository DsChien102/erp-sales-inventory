import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_detail_dto.dart';

@RequiresPermission(PricingPermissions.disableCustomerPriceRule)
@RequiresTenant()
final class DisableCustomerPriceRuleCommand
    extends CommandBase<CustomerPriceRuleDetailDto>
    implements ICommand<CustomerPriceRuleDetailDto>, ITenantScopedCommand {
  DisableCustomerPriceRuleCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.ruleId,
    required this.expectedVersion,
    this.reason,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String ruleId;
  final int expectedVersion;
  final String? reason;

  DisableCustomerPriceRuleCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => DisableCustomerPriceRuleCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    ruleId: ruleId,
    expectedVersion: expectedVersion,
    reason: reason,
  );
}
