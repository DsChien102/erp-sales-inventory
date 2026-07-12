import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_read_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_readiness_read_port.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'adjust_basic_stock_command.dart';
import 'adjust_basic_stock_command_validator.dart';
import 'adjust_basic_stock_result.dart';
import 'package:vet45_catalog_application/src/ports/i_catalog_stock_gateway.dart';

@CommandHandlerFor(AdjustBasicStockCommand)
final class AdjustBasicStockCommandHandler
    implements ICommandHandler<AdjustBasicStockCommand, AdjustBasicStockResult> {
  AdjustBasicStockCommandHandler({
    required ICatalogStockGateway stockGateway,
    required IProductReadinessReadPort readinessReadPort,
    required ICatalogReadGateway catalogReadGateway,
    AdjustBasicStockCommandValidator? validator,
  }) : _stockGateway = stockGateway,
       _readinessReadPort = readinessReadPort,
       _catalogReadGateway = catalogReadGateway,
       _validator = validator ?? AdjustBasicStockCommandValidator();

  final ICatalogStockGateway _stockGateway;
  final IProductReadinessReadPort _readinessReadPort;
  final ICatalogReadGateway _catalogReadGateway;
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

    final model = await _catalogReadGateway.loadControlCenter(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    final currentQty = model?.stockQuantity;

    ProductStockProfile.reconstitute(
      productId: ProductId(command.productId),
      tenantId: TenantId(command.tenantId),
      mode: facts.stockMode,
      basicStockQuantityBase: currentQty,
    ).adjust(
      newQuantity: command.newQuantity,
      hasBaseUnit: facts.hasBaseUnit,
      actorId: command.tenantId,
      expectedQuantity: command.expectedQuantity,
    );

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
