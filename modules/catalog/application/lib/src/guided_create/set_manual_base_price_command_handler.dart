import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'set_manual_base_price_command.dart';

@CommandHandlerFor(SetManualBasePriceCommand)
final class SetManualBasePriceCommandHandler
    implements ICommandHandler<SetManualBasePriceCommand, void> {
  SetManualBasePriceCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<void> handle(SetManualBasePriceCommand command) async {
    if (command.mode != 'manual') {
      throw NotManualBasePriceModeException();
    }

    final profile = ProductBasePriceProfile.manual(
      basePrice: BasePrice(amount: command.basePrice),
    );

    await _commandGateway.setManualBasePrice(
      productId: command.productId,
      tenantId: command.tenantId,
      profile: profile,
    );
  }
}
