import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_detail_dto.dart';

@RequiresPermission(PricingPermissions.reenableCustomerPriceRule)
@RequiresTenant()
final class ReenableCustomerPriceRuleCommand
    extends CommandBase<CustomerPriceRuleDetailDto>
    implements ICommand<CustomerPriceRuleDetailDto>, ITenantScopedCommand {
  ReenableCustomerPriceRuleCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.ruleId,
    required this.expectedVersion,
    required DateTime businessDate,
    this.precheckToken,
    required this.acknowledgeFloorWarning,
    this.acknowledgeOverwrite = false,
  }) : businessDate = DateTime.utc(
         businessDate.year,
         businessDate.month,
         businessDate.day,
       ),
       super(id);

  @override
  final String tenantId;
  final String actorId;
  final String ruleId;
  final int expectedVersion;
  final DateTime businessDate;
  final String? precheckToken;
  final bool acknowledgeFloorWarning;
  final bool acknowledgeOverwrite;

  ReenableCustomerPriceRuleCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => ReenableCustomerPriceRuleCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    ruleId: ruleId,
    expectedVersion: expectedVersion,
    businessDate: businessDate,
    precheckToken: precheckToken,
    acknowledgeFloorWarning: acknowledgeFloorWarning,
    acknowledgeOverwrite: acknowledgeOverwrite,
  );
}
