import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_detail_dto.dart';

@RequiresPermission(PricingPermissions.updateCustomerPriceRule)
@RequiresTenant()
final class UpdateCustomerPriceRuleCommand
    extends CommandBase<CustomerPriceRuleDetailDto>
    implements ICommand<CustomerPriceRuleDetailDto>, ITenantScopedCommand {
  UpdateCustomerPriceRuleCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.ruleId,
    required this.expectedVersion,
    required this.rulePriceMinor,
    required this.effectiveFrom,
    this.effectiveTo,
    this.note,
    required this.acknowledgeFloorWarning,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String ruleId;
  final int expectedVersion;
  final int rulePriceMinor;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? note;
  final bool acknowledgeFloorWarning;

  UpdateCustomerPriceRuleCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => UpdateCustomerPriceRuleCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    ruleId: ruleId,
    expectedVersion: expectedVersion,
    rulePriceMinor: rulePriceMinor,
    effectiveFrom: effectiveFrom,
    effectiveTo: effectiveTo,
    note: note,
    acknowledgeFloorWarning: acknowledgeFloorWarning,
  );
}
