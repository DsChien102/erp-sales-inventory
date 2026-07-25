import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_detail_dto.dart';

@RequiresPermission(PricingPermissions.deleteCustomerPriceRule)
@RequiresTenant()
final class DeleteCustomerPriceRuleCommand
    extends CommandBase<CustomerPriceRuleDetailDto>
    implements ICommand<CustomerPriceRuleDetailDto>, ITenantScopedCommand {
  DeleteCustomerPriceRuleCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.ruleId,
    required this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String ruleId;
  final int expectedVersion;

  DeleteCustomerPriceRuleCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => DeleteCustomerPriceRuleCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    ruleId: ruleId,
    expectedVersion: expectedVersion,
  );
}
