import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_readiness_read_port.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'set_manual_base_price_command.dart';
import 'set_manual_base_price_result.dart';

@CommandHandlerFor(SetManualBasePriceCommand)
final class SetManualBasePriceCommandHandler
    implements ICommandHandler<SetManualBasePriceCommand, SetManualBasePriceResult> {
  SetManualBasePriceCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductReadinessReadPort readinessReadPort,
    required ICatalogUnitGateway unitGateway,
  }) : _commandGateway = commandGateway,
       _readinessReadPort = readinessReadPort,
       _unitGateway = unitGateway;

  final IProductCommandGateway _commandGateway;
  final IProductReadinessReadPort _readinessReadPort;
  final ICatalogUnitGateway _unitGateway;

  @override
  Future<SetManualBasePriceResult> handle(SetManualBasePriceCommand command) async {
    if (command.mode != 'manual') {
      throw NotManualBasePriceModeException();
    }

    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }
    if (!facts.hasBaseUnit) {
      throw MissingBaseUnitException();
    }

    final profile =
        ProductBasePriceProfile.reconstitute(
          productId: ProductId(command.productId),
          tenantId: TenantId(command.tenantId),
          mode: facts.basePriceMode,
          basePrice: null,
        ).setManual(
          amount: command.basePrice,
          actorId: command.tenantId,
          currency: command.currency,
        );

    await _commandGateway.setManualBasePrice(
      productId: command.productId,
      tenantId: command.tenantId,
      profile: profile,
      currency: command.currency,
    );

    final refreshedFacts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (refreshedFacts == null) {
      throw ApplicationException('Product not found');
    }
    final readiness = ProductReadinessEvaluator.compute(refreshedFacts);
    final units = await _unitGateway.listProductUnits(
      query: ListProductUnitsQuery(
        tenantId: command.tenantId,
        productId: command.productId,
      ),
    );

    return SetManualBasePriceResult(
      productId: command.productId,
      basePrice: command.basePrice,
      currency: command.currency,
      unitName: units.baseUnitName,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
    );
  }
}
