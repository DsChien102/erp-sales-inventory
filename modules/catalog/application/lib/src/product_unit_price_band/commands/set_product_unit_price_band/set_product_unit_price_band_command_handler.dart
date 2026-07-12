import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

@CommandHandlerFor(SetProductUnitPriceBandCommand)
final class SetProductUnitPriceBandCommandHandler
    implements ICommandHandler<SetProductUnitPriceBandCommand, SetProductUnitPriceBandResult> {
  SetProductUnitPriceBandCommandHandler({
    required IProductPriceBandGateway priceBandGateway,
    required IProductReadinessReadPort readinessReadPort,
    required ICatalogUnitGateway unitGateway,
    required ICatalogReadGateway catalogReadGateway,
  }) : _priceBandGateway = priceBandGateway,
       _readinessReadPort = readinessReadPort,
       _unitGateway = unitGateway,
       _catalogReadGateway = catalogReadGateway;

  final IProductPriceBandGateway _priceBandGateway;
  final IProductReadinessReadPort _readinessReadPort;
  final ICatalogUnitGateway _unitGateway;
  final ICatalogReadGateway _catalogReadGateway;

  @override
  Future<SetProductUnitPriceBandResult> handle(
    SetProductUnitPriceBandCommand command,
  ) async {
    await _ensureBaseUnit(command.tenantId, command.productId);

    final units = await _unitGateway.listProductUnits(
      query: ListProductUnitsQuery(
        tenantId: command.tenantId,
        productId: command.productId,
        includeInactive: true,
      ),
    );

    final targetUnit = _resolveTargetUnit(
      units: units.units,
      productUnitId: command.productUnitId,
    );
    if (targetUnit == null) {
      throw ApplicationException('Product unit not found');
    }
    if (!targetUnit.isActive) {
      throw InactiveProductUnitException();
    }

    final controlCenter = await _catalogReadGateway.loadControlCenter(
      tenantId: command.tenantId,
      productId: command.productId,
    );

    final warnings = PriceBandWarningCalculator.compute(
      basePricePerBaseUnit: controlCenter?.basePriceAmount,
      baseUnitName: units.baseUnitName,
      unit: targetUnit,
      listPrice: command.listPrice,
      floorPrice: command.floorPrice,
    );

    if (warnings.isNotEmpty && !command.confirmAcknowledgeWarnings) {
      throw PriceBandWarningsRequireAcknowledgmentException(warnings: warnings);
    }

    // Domain-first: enforce floor ≤ list before RPC persist.
    ProductUnitPriceBand.set(
      id: targetUnit.id,
      tenantId: TenantId(command.tenantId),
      productId: ProductId(command.productId),
      productUnitId: targetUnit.id,
      listPrice: command.listPrice,
      floorPrice: command.floorPrice,
      storePriceRuleId: command.storePriceRuleId,
    );

    await _priceBandGateway.setProductUnitPriceBand(
      tenantId: command.tenantId,
      productId: command.productId,
      productUnitId: targetUnit.id,
      listPrice: command.listPrice,
      floorPrice: command.floorPrice,
      sourceType: command.sourceType,
      storePriceRuleId: command.storePriceRuleId,
    );

    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }

    final readiness = ProductReadinessEvaluator.compute(facts);
    return SetProductUnitPriceBandResult(
      productId: command.productId,
      productUnitId: targetUnit.id,
      listPrice: command.listPrice,
      floorPrice: command.floorPrice,
      sourceType: command.sourceType,
      storePriceRuleId: command.storePriceRuleId,
      warnings: warnings,
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

  ProductUnitDto? _resolveTargetUnit({
    required List<ProductUnitDto> units,
    required String? productUnitId,
  }) {
    if (productUnitId != null) {
      for (final unit in units) {
        if (unit.id == productUnitId) {
          return unit;
        }
      }
      return null;
    }

    for (final unit in units) {
      if (unit.isBaseUnit) {
        return unit;
      }
    }
    return null;
  }
}
