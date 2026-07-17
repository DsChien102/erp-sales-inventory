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

    final priceBand = _createPriceBand(
      command: command,
      targetUnit: targetUnit,
      basePricePerBaseUnit: controlCenter?.basePriceAmount,
    );

    final listBeforeVat = priceBand.listBeforeVat!.amount;
    final listAfterVat = priceBand.listAfterVat!.amount;
    final floorBeforeVat = priceBand.floorBeforeVat?.amount;
    final floorAfterVat = priceBand.floorAfterVat?.amount;

    final warnings = PriceBandWarningCalculator.compute(
      basePricePerBaseUnit: controlCenter?.basePriceAmount,
      baseUnitName: units.baseUnitName,
      unit: targetUnit,
      listBeforeVat: listBeforeVat,
      floorBeforeVat: floorBeforeVat,
    );

    if (warnings.isNotEmpty && !command.confirmAcknowledgeWarnings) {
      throw PriceBandWarningsRequireAcknowledgmentException(warnings: warnings);
    }

    await _priceBandGateway.setProductUnitPriceBand(
      tenantId: command.tenantId,
      productId: command.productId,
      productUnitId: targetUnit.id,
      listBeforeVat: listBeforeVat,
      floorBeforeVat: floorBeforeVat,
      listAfterVat: listAfterVat,
      floorAfterVat: floorAfterVat,
      effectiveFrom: command.effectiveFrom,
      effectiveTo: command.effectiveTo,
      status: command.status,
      sourceType: command.sourceType,
      storePriceRuleId: command.storePriceRuleId,
      listMarkupRatio: command.listMarkupRatio,
      floorMarkupRatio: command.floorMarkupRatio,
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
      listBeforeVat: listBeforeVat,
      floorBeforeVat: floorBeforeVat,
      listAfterVat: listAfterVat,
      floorAfterVat: floorAfterVat,
      effectiveFrom: command.effectiveFrom,
      effectiveTo: command.effectiveTo,
      status: command.status ?? ProductPriceBandStatus.active,
      sourceType: command.sourceType,
      storePriceRuleId: command.storePriceRuleId,
      listMarkupRatio: command.listMarkupRatio,
      floorMarkupRatio: command.floorMarkupRatio,
      warnings: warnings,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
    );
  }

  ProductUnitPriceBand _createPriceBand({
    required SetProductUnitPriceBandCommand command,
    required ProductUnitDto targetUnit,
    required double? basePricePerBaseUnit,
  }) {
    final status = command.status ?? ProductPriceBandStatus.active;
    switch (command.sourceType) {
      case PriceBandSourceType.ruleBased:
        throw ApplicationException(
          'Rule-based price bands must use ApplyStorePriceRuleCommand.',
        );
      case PriceBandSourceType.customConfig:
        final basePrice = basePricePerBaseUnit;
        if (basePrice == null) {
          throw MissingBasePriceException();
        }
        if (targetUnit.conversionRateToBase <= 0) {
          throw ApplicationException('Product unit conversion rate is invalid.');
        }
        final markupConfig = PriceBandMarkupConfig(
          listMarkupRatio: command.listMarkupRatio!,
          floorMarkupRatio: command.floorMarkupRatio,
        );
        return ProductUnitPriceBand.setCustomConfig(
          id: targetUnit.id,
          tenantId: TenantId(command.tenantId),
          productId: ProductId(command.productId),
          productUnitId: targetUnit.id,
          basePriceForUnit: basePrice * targetUnit.conversionRateToBase,
          markupConfig: markupConfig,
          effectiveFrom: command.effectiveFrom,
          effectiveTo: command.effectiveTo,
          status: status,
        );
      case PriceBandSourceType.manual:
        final listBeforeVat = command.listBeforeVat;
        final listAfterVat = command.listAfterVat;
        if (listBeforeVat == null || listAfterVat == null) {
          throw ApplicationException('Manual list prices are required.');
        }
        return ProductUnitPriceBand.setManual(
          id: targetUnit.id,
          tenantId: TenantId(command.tenantId),
          productId: ProductId(command.productId),
          productUnitId: targetUnit.id,
          listBeforeVat: listBeforeVat,
          floorBeforeVat: command.floorBeforeVat,
          listAfterVat: listAfterVat,
          floorAfterVat: command.floorAfterVat,
          effectiveFrom: command.effectiveFrom,
          effectiveTo: command.effectiveTo,
          status: status,
        );
    }
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
