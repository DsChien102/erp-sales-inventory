import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'set_initial_stock_command.dart';

@CommandHandlerFor(SetInitialStockCommand)
final class SetInitialStockCommandHandler
    implements ICommandHandler<SetInitialStockCommand, void> {
  SetInitialStockCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<void> handle(SetInitialStockCommand command) async {
    if (command.mode != 'basic') {
      throw NotBasicStockModeException();
    }

    final profile = ProductStockProfile.basic(
      initialStock: command.quantity.toDouble(),
    );

    await _commandGateway.setInitialStock(
      productId: command.productId,
      tenantId: command.tenantId,
      profile: profile,
    );
  }
}
