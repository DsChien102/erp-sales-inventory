import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_readiness_read_port.dart';
import '../ports/i_product_command_gateway.dart';
import 'set_initial_stock_command.dart';

@CommandHandlerFor(SetInitialStockCommand)
final class SetInitialStockCommandHandler implements ICommandHandler<SetInitialStockCommand, void> {
  SetInitialStockCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductReadinessReadPort readinessReadPort,
  }) : _commandGateway = commandGateway,
       _readinessReadPort = readinessReadPort;

  final IProductCommandGateway _commandGateway;
  final IProductReadinessReadPort _readinessReadPort;

  @override
  Future<void> handle(SetInitialStockCommand command) async {
    if (command.mode != 'basic') {
      throw NotBasicStockModeException();
    }
    await _ensureBaseUnit(command.tenantId, command.productId);

    final profile = ProductStockProfile.basic(
      initialStock: command.quantity.toDouble(),
    );

    await _commandGateway.setInitialStock(
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
