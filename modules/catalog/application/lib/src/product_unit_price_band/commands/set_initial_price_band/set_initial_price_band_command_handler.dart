import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_readiness_read_port.dart';
import 'set_initial_price_band_command.dart';

@CommandHandlerFor(SetInitialPriceBandCommand)
final class SetInitialPriceBandCommandHandler
    implements ICommandHandler<SetInitialPriceBandCommand, void> {
  SetInitialPriceBandCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductReadinessReadPort readinessReadPort,
  }) : _commandGateway = commandGateway,
       _readinessReadPort = readinessReadPort;

  final IProductCommandGateway _commandGateway;
  final IProductReadinessReadPort _readinessReadPort;

  @override
  Future<void> handle(SetInitialPriceBandCommand command) async {
    final useRule = command.useStoreRule ?? false;

    if (useRule && (command.listPrice == null || command.floorPrice == null)) {
      throw MissingBasePriceException();
    }

    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null || !facts.hasBaseUnit) {
      throw MissingBaseUnitException();
    }

    final listPriceVal = command.listPrice ?? 0.0;
    final floorPriceVal = command.floorPrice ?? 0.0;
    final unitSuffix = command.productUnitId ?? 'initial';

    final priceBand = ProductUnitPriceBand.set(
      id: '${command.productId}_$unitSuffix',
      tenantId: TenantId(command.tenantId),
      productId: ProductId(command.productId),
      productUnitId: command.productUnitId,
      listPrice: listPriceVal,
      floorPrice: floorPriceVal,
    );

    await _commandGateway.setInitialPriceBand(
      productId: command.productId,
      tenantId: command.tenantId,
      priceBand: priceBand,
    );
  }
}
