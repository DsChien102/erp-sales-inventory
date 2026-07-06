import 'package:vet45_catalog_domain/domain.dart';

import '../readiness/product_readiness_permission_context.dart';
import '../readiness/product_readiness_view_assembler.dart';
import '../readiness/readiness_summary_dto.dart';
import 'product_base_price_card_dto.dart';
import 'product_control_center_dto.dart';
import 'product_control_center_read_model.dart';
import 'product_price_band_card_dto.dart';
import 'product_profile_summary_dto.dart';
import 'product_stock_card_dto.dart';
import 'product_units_card_dto.dart';
import '../stock/stock_data_source.dart';

/// Assembles [ProductControlCenterDto] from RPC read model + permissions.
abstract final class ProductControlCenterAssembler {
  static ProductControlCenterDto assemble({
    required ProductControlCenterReadModel model,
    required ProductReadinessPermissionContext permissions,
    bool includeChangeHistory = true,
  }) {
    final readiness = ProductReadinessEvaluator.compute(model.facts);
    final readinessView = ProductReadinessViewAssembler.assemble(
      facts: model.facts,
      readiness: readiness,
      permissions: permissions,
    );

    final hasBaseUnit = model.baseUnitName != null && model.baseUnitName!.trim().isNotEmpty;
    final hasStock = model.stockQuantity != null;
    final hasBasePrice = model.basePriceAmount != null;
    final hasPriceBand = model.listPrice != null && model.floorPrice != null;

    return ProductControlCenterDto(
      profile: ProductProfileSummaryDto(
        productId: model.productId,
        name: model.name,
        tradeName: model.tradeName,
        sku: model.sku,
        barcode: model.barcode,
        businessStatus: model.businessStatus,
        isSoftDeleted: model.isSoftDeleted,
        primaryImageUrl: model.primaryImageUrl,
        images: model.images,
        description: model.description,
        note: model.note,
      ),
      units: ProductUnitsCardDto(
        baseUnitName: hasBaseUnit ? model.baseUnitName : null,
        conversionUnits: model.conversionUnits,
        isMissing: !hasBaseUnit,
        missingMessage: hasBaseUnit ? null : 'Thiếu đơn vị cơ sở',
      ),
      stock: ProductStockCardDto(
        mode: model.facts.stockMode,
        source: model.facts.stockMode == StockMode.advanced
            ? StockDataSource.inventoryModule
            : StockDataSource.basicProfile,
        sourceLabel: model.facts.stockMode == StockMode.advanced
            ? 'Tồn kho từ module Kho'
            : 'Tồn kho cơ bản',
        quantity: model.stockQuantity,
        unitName: hasBaseUnit ? model.baseUnitName : null,
        isConfigured: hasStock,
        isOutOfStock: hasStock && model.stockQuantity == 0,
        canAdjust: model.facts.stockMode == StockMode.basic && hasBaseUnit,
        currentVersion: model.stockVersion,
        isPendingExternal: model.facts.stockMode == StockMode.advanced,
        isMissing: model.facts.stockMode == StockMode.basic && !hasStock,
        missingMessage: model.facts.stockMode == StockMode.basic && !hasStock
            ? 'Thiếu tồn kho'
            : null,
      ),
      basePrice: ProductBasePriceCardDto(
        mode: model.facts.basePriceMode,
        amount: model.basePriceAmount,
        currency: model.basePriceCurrency,
        isPendingExternal: model.facts.basePriceMode == BasePriceMode.costingModule,
        isMissing: model.facts.basePriceMode == BasePriceMode.manual && !hasBasePrice,
        missingMessage: model.facts.basePriceMode == BasePriceMode.manual && !hasBasePrice
            ? 'Thiếu Giá cơ sở định giá'
            : null,
      ),
      priceBand: ProductPriceBandCardDto(
        listPrice: model.listPrice,
        floorPrice: model.floorPrice,
        unitName: hasBaseUnit ? model.baseUnitName : null,
        isMissing: !hasPriceBand,
        missingMessage: !hasPriceBand ? 'Thiếu khung giá bán' : null,
      ),
      customFieldGroupCards: const [],
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
      checklist: const [],
      contextualActions: readinessView.suggestedActions,
      changeHistoryPreview: includeChangeHistory ? model.changeHistoryPreview : const [],
      primaryActionId: readinessView.primaryActionId,
    );
  }
}
