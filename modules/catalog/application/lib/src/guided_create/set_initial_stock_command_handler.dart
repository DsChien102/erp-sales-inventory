import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_readiness_read_port.dart';
import '../ports/i_product_command_gateway.dart';
import '../readiness/readiness_summary_dto.dart';
import 'set_initial_stock_command.dart';
import '../stock/set_initial_stock_result.dart';

@CommandHandlerFor(SetInitialStockCommand)
final class SetInitialStockCommandHandler
    implements ICommandHandler<SetInitialStockCommand, SetInitialStockResult> {
  SetInitialStockCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductReadinessReadPort readinessReadPort,
  }) : _commandGateway = commandGateway,
       _readinessReadPort = readinessReadPort;

  final IProductCommandGateway _commandGateway;
  final IProductReadinessReadPort _readinessReadPort;

  @override
  Future<SetInitialStockResult> handle(SetInitialStockCommand command) async {
    if (command.mode != 'basic') {
      throw NotBasicStockModeException();
    }
    await _ensureBaseUnit(command.tenantId, command.productId);

    final profile = ProductStockProfile.basic(
      initialStock: command.quantity,
    );

    await _commandGateway.setInitialStock(
      productId: command.productId,
      tenantId: command.tenantId,
      profile: profile,
    );

    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }
    final readiness = ProductReadinessEvaluator.compute(facts);

    return SetInitialStockResult(
      productId: command.productId,
      quantity: command.quantity,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
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
