import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import '../ports/i_product_readiness_read_port.dart';
import 'set_manual_base_price_command.dart';

@CommandHandlerFor(SetManualBasePriceCommand)
final class SetManualBasePriceCommandHandler
    implements ICommandHandler<SetManualBasePriceCommand, void> {
  SetManualBasePriceCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductReadinessReadPort readinessReadPort,
  }) : _commandGateway = commandGateway,
       _readinessReadPort = readinessReadPort;

  final IProductCommandGateway _commandGateway;
  final IProductReadinessReadPort _readinessReadPort;

  @override
  Future<void> handle(SetManualBasePriceCommand command) async {
    if (command.mode != 'manual') {
      throw NotManualBasePriceModeException();
    }
    await _ensureBaseUnit(command.tenantId, command.productId);

    final profile = ProductBasePriceProfile.manual(
      basePrice: BasePrice(amount: command.basePrice),
    );

    await _commandGateway.setManualBasePrice(
      productId: command.productId,
      tenantId: command.tenantId,
      profile: profile,
    );
  }

  Future<void> _ensureBaseUnit(String tenantId, String productId) async {
    final facts = await _readinessReadPort.loadFacts(
      tenantId: tenantId,
      productId: productId,
    );
    if (facts == null || !facts.hasBaseUnit) {
      throw MissingBaseUnitException();
    }
  }
}
