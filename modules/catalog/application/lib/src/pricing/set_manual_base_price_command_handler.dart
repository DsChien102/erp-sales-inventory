import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_catalog_unit_gateway.dart';
import '../ports/i_product_command_gateway.dart';
import '../ports/i_product_readiness_read_port.dart';
import '../readiness/readiness_summary_dto.dart';
import '../units/list_product_units_query.dart';
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
    await _ensureBaseUnit(command.tenantId, command.productId);

    final profile = ProductBasePriceProfile.manual(
      basePrice: BasePrice(amount: command.basePrice),
    );

    await _commandGateway.setManualBasePrice(
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
