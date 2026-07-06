import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_readiness_read_port.dart';
import '../readiness/readiness_summary_dto.dart';
import 'adjust_basic_stock_command.dart';
import 'adjust_basic_stock_command_validator.dart';
import 'adjust_basic_stock_result.dart';
import 'ports/i_catalog_stock_gateway.dart';

@CommandHandlerFor(AdjustBasicStockCommand)
final class AdjustBasicStockCommandHandler
    implements ICommandHandler<AdjustBasicStockCommand, AdjustBasicStockResult> {
  AdjustBasicStockCommandHandler({
    required ICatalogStockGateway stockGateway,
    required IProductReadinessReadPort readinessReadPort,
    AdjustBasicStockCommandValidator? validator,
  }) : _stockGateway = stockGateway,
       _readinessReadPort = readinessReadPort,
       _validator = validator ?? AdjustBasicStockCommandValidator();

  final ICatalogStockGateway _stockGateway;
  final IProductReadinessReadPort _readinessReadPort;
  final AdjustBasicStockCommandValidator _validator;

  @override
  Future<AdjustBasicStockResult> handle(AdjustBasicStockCommand command) async {
    await _validator.validate(command);
    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }
    if (facts.stockMode.isAdvanced) {
      throw NotBasicStockModeException();
    }
    if (!facts.hasBaseUnit) {
      throw MissingBaseUnitException();
    }

    final result = await _stockGateway.adjustBasicStock(command: command);
    final refreshedFacts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (refreshedFacts == null) {
      throw ApplicationException('Product not found');
    }

    final readiness = ProductReadinessEvaluator.compute(refreshedFacts);
    return AdjustBasicStockResult(
      productId: command.productId,
      previousQuantity: result.previousQuantity,
      newQuantity: result.newQuantity,
      unitName: result.unitName,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
    );
  }
}
