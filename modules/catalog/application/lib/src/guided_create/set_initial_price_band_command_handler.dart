import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'set_initial_price_band_command.dart';

@CommandHandlerFor(SetInitialPriceBandCommand)
final class SetInitialPriceBandCommandHandler
    implements ICommandHandler<SetInitialPriceBandCommand, void> {
  SetInitialPriceBandCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<void> handle(SetInitialPriceBandCommand command) async {
    final useRule = command.useStoreRule ?? false;

    if (useRule && (command.listPrice == null || command.floorPrice == null)) {
      throw MissingBasePriceException();
    }

    final listPriceVal = command.listPrice ?? 0.0;
    final floorPriceVal = command.floorPrice ?? 0.0;

    final rule = FloorPriceNotGreaterThanListPriceRule(
      floorPrice: FloorPrice(amount: floorPriceVal),
      listPrice: ListPrice(amount: listPriceVal),
    );
    if (rule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(rule.message);
    }

    final unitId = command.productUnitId ?? 'base_unit';
    final priceBand = ProductUnitPriceBand(
      id: '${command.productId}_$unitId',
      tenantId: command.tenantId,
      productId: command.productId,
      productUnitId: unitId,
      listPrice: ListPrice(amount: listPriceVal),
      floorPrice: FloorPrice(amount: floorPriceVal),
    );

    await _commandGateway.setInitialPriceBand(
      productId: command.productId,
      tenantId: command.tenantId,
      priceBand: priceBand,
    );
  }
}
