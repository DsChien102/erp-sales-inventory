import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'create_customer_price_rule_result.dart';

@RequiresPermission(PricingPermissions.createCustomerPriceRule)
@RequiresTenant()
final class CreateCustomerPriceRuleCommand
    extends CommandBase<CreateCustomerPriceRuleResult>
    implements ICommand<CreateCustomerPriceRuleResult>, ITenantScopedCommand {
  CreateCustomerPriceRuleCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.rulePriceMinor,
    required this.currencyCode,
    required this.effectiveFrom,
    required this.acknowledgeFloorWarning,
    required this.idempotencyKey,
    this.effectiveTo,
    this.note,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String customerId;
  final String productId;
  final String productUnitId;
  final int rulePriceMinor;
  final String currencyCode;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? note;
  final bool acknowledgeFloorWarning;
  final String idempotencyKey;

  CreateCustomerPriceRuleCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => CreateCustomerPriceRuleCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    customerId: customerId,
    productId: productId,
    productUnitId: productUnitId,
    rulePriceMinor: rulePriceMinor,
    currencyCode: currencyCode,
    effectiveFrom: effectiveFrom,
    effectiveTo: effectiveTo,
    note: note,
    acknowledgeFloorWarning: acknowledgeFloorWarning,
    idempotencyKey: idempotencyKey,
  );
}
