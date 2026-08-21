import 'package:uuid/uuid.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../../ports/i_remembered_price_gateway.dart';
import 'remembered_price_outcome_dto.dart';
import 'save_remembered_price_from_order_command.dart';

@CommandHandlerFor(SaveRememberedPriceFromOrderCommand)
final class SaveRememberedPriceFromOrderCommandHandler
    implements
        ICommandHandler<
          SaveRememberedPriceFromOrderCommand,
          RememberedPriceOutcomeDto
        > {
  SaveRememberedPriceFromOrderCommandHandler({
    required IRememberedPriceGateway gateway,
  }) : _gateway = gateway;

  final IRememberedPriceGateway _gateway;

  @override
  Future<RememberedPriceOutcomeDto> handle(
    SaveRememberedPriceFromOrderCommand command,
  ) async {
    final request = RememberedPriceRequest.receive(
      id: const Uuid().v4(),
      tenantId: command.tenantId,
      actorId: command.actorId,
      sourceOrderId: command.sourceOrderId,
      sourceOrderLineId: command.sourceOrderLineId,
      customerId: command.customerId,
      productId: command.productId,
      productUnitId: command.productUnitId,
      soldPrice: Money(
        amountMinor: command.soldPriceMinor,
        currencyCode: command.currencyCode,
      ),
      soldAt: command.soldAt,
      idempotencyKey: command.idempotencyKey,
    );
    final outcome = await _gateway.save(request);
    request.recordOutcome(
      resultType: outcome.resultType,
      ruleId: outcome.ruleId,
      ruleVersion: outcome.ruleVersion,
      reasonCode: outcome.reasonCode,
    );
    return outcome;
  }
}
