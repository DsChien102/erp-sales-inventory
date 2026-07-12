import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/ports/i_product_readiness_read_port.dart';
import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'set_basic_stock_quantity_base_command.dart';
import 'package:vet45_catalog_application/src/product_stock_profile/commands/set_basic_stock_quantity_base/set_basic_stock_quantity_base_result.dart';

@CommandHandlerFor(SetBasicStockQuantityBaseCommand)
final class SetBasicStockQuantityBaseCommandHandler
    implements ICommandHandler<SetBasicStockQuantityBaseCommand, SetBasicStockQuantityBaseResult> {
  SetBasicStockQuantityBaseCommandHandler({
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
  Future<SetBasicStockQuantityBaseResult> handle(
    SetBasicStockQuantityBaseCommand command,
  ) async {
    if (command.mode != 'basic') {
      throw NotBasicStockModeException();
    }

    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }

    final profile =
        ProductStockProfile.reconstitute(
          productId: ProductId(command.productId),
          tenantId: TenantId(command.tenantId),
          mode: facts.stockMode,
          basicStockQuantityBase: null,
        ).setBasicQuantity(
          quantity: command.quantity,
          hasBaseUnit: facts.hasBaseUnit,
          actorId: command.tenantId,
        );

    await _commandGateway.setBasicStockQuantityBase(
      productId: command.productId,
      tenantId: command.tenantId,
      profile: profile,
    );

    final refreshedFacts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );

    if (refreshedFacts == null) {
      throw ApplicationException('Product not found');
    }

    final units = await _unitGateway.listProductUnits(
      query: ListProductUnitsQuery(
        tenantId: command.tenantId,
        productId: command.productId,
      ),
    );

    final readiness = ProductReadinessEvaluator.compute(refreshedFacts);

    return SetBasicStockQuantityBaseResult(
      productId: command.productId,
      quantity: command.quantity,
      unitName: units.baseUnitName,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
    );
  }
}
