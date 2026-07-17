import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'remembered_price_outcome_dto.dart';

@RequiresPermission(PricingPermissions.savePriceMemory)
@RequiresTenant()
final class SaveRememberedPriceFromOrderCommand
    extends CommandBase<RememberedPriceOutcomeDto>
    implements ICommand<RememberedPriceOutcomeDto>, ITenantScopedCommand {
  SaveRememberedPriceFromOrderCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.sourceOrderId,
    required this.sourceOrderLineId,
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.soldPriceMinor,
    required String currencyCode,
    required DateTime soldAt,
    required String idempotencyKey,
  }) : currencyCode = currencyCode.trim().toUpperCase(),
       soldAt = soldAt.toUtc(),
       idempotencyKey = idempotencyKey.trim(),
       super(id);

  @override
  final String tenantId;
  final String actorId;
  final String sourceOrderId;
  final String sourceOrderLineId;
  final String? customerId;
  final String productId;
  final String productUnitId;
  final int soldPriceMinor;
  final String currencyCode;
  final DateTime soldAt;
  final String idempotencyKey;

  SaveRememberedPriceFromOrderCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => SaveRememberedPriceFromOrderCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    sourceOrderId: sourceOrderId,
    sourceOrderLineId: sourceOrderLineId,
    customerId: customerId,
    productId: productId,
    productUnitId: productUnitId,
    soldPriceMinor: soldPriceMinor,
    currencyCode: currencyCode,
    soldAt: soldAt,
    idempotencyKey: idempotencyKey,
  );
}
