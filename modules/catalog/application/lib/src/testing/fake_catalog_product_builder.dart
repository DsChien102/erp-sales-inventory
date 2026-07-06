import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import 'fake_product_readiness_builder.dart';

/// Builds list and control-center DTOs for [FakeCatalogModule].
abstract final class FakeCatalogProductBuilder {
  static ReadinessSummaryDto readinessSummaryFor({
    required String productId,
    required String productName,
    required bool hasBaseUnit,
    required bool hasImages,
    required bool hasStock,
    required bool hasBasePrice,
    required bool hasPriceBand,
    required bool hasRequiredCustomFields,
    StockMode stockMode = StockMode.basic,
    BasePriceMode basePriceMode = BasePriceMode.manual,
  }) {
    final facts = ProductReadinessFacts(
      productId: productId,
      productName: productName,
      hasBaseUnit: hasBaseUnit,
      hasImages: hasImages,
      hasStock: hasStock,
      hasBasePrice: hasBasePrice,
      hasPriceBand: hasPriceBand,
      hasRequiredCustomFields: hasRequiredCustomFields,
      stockMode: stockMode,
      basePriceMode: basePriceMode,
    );
    final readiness = ProductReadinessEvaluator.compute(facts);
    return ReadinessSummaryDto.fromDomain(readiness);
  }

  static ProductListItemDto toListItem({
    required String id,
    required String name,
    String? tradeName,
    String? sku,
    String? barcode,
    String? primaryImageUrl,
    ProductStatus businessStatus = ProductStatus.active,
    bool isSoftDeleted = false,
    required ReadinessSummaryDto readinessSummary,
    double? listPrice,
    double? floorPrice,
    String? baseUnit,
    int? stockQuantity,
    DateTime? updatedAt,
    bool hasRequiredCustomFields = true,
    StockMode stockMode = StockMode.basic,
    BasePriceMode basePriceMode = BasePriceMode.manual,
    bool hasImages = true,
    bool hasStock = true,
    bool hasBasePrice = true,
    bool hasPriceBand = true,
    bool hasBaseUnit = true,
  }) {
    final stockLabel = stockQuantity != null ? '$stockQuantity' : null;
    return ProductListItemDto(
      id: id,
      name: name,
      tradeName: tradeName,
      sku: sku?.isEmpty == true ? null : sku,
      barcode: barcode?.isEmpty == true ? null : barcode,
      primaryImageUrl: primaryImageUrl,
      businessStatus: businessStatus,
      isSoftDeleted: isSoftDeleted,
      readinessSummary: readinessSummary,
      listPrice: listPrice,
      floorPrice: floorPrice,
      baseUnit: baseUnit?.isEmpty == true ? null : baseUnit,
      stockQuantity: stockQuantity,
      stockLabel: stockLabel,
      updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
    );
  }

  static ProductControlCenterDto toControlCenter({
    required String id,
    required String name,
    String? tradeName,
    String? sku,
    String? barcode,
    List<String> images = const [],
    String? description,
    String? note,
    ProductStatus businessStatus = ProductStatus.active,
    bool isSoftDeleted = false,
    String? baseUnit,
    int? stockQty,
    int? stockVersion,
    double? baseCost,
    double? listPrice,
    double? floorPrice,
    PriceBandSourceType? priceBandSourceType,
    String? storePriceRuleName,
    bool isCustomOverride = false,
    bool hasRequiredCustomFields = true,
    StockMode stockMode = StockMode.basic,
    BasePriceMode basePriceMode = BasePriceMode.manual,
    bool pricePermissionDenied = false,
    List<CustomFieldGroupCardDto> customFieldGroupCards = const [],
    List<ProductChangeHistoryEntryDto> changeHistoryPreview = const [],
  }) {
    final hasBaseUnit = baseUnit != null && baseUnit.trim().isNotEmpty;
    final hasImages = images.isNotEmpty;
    final hasStock = stockQty != null;
    final hasBasePrice = baseCost != null;
    final hasPriceBand = listPrice != null && floorPrice != null;

    final readinessView = FakeProductReadinessBuilder.build(
      productId: id,
      productName: name,
      hasBaseUnit: hasBaseUnit,
      hasImages: hasImages,
      hasStock: hasStock,
      hasBasePrice: hasBasePrice,
      hasPriceBand: hasPriceBand,
      hasRequiredCustomFields: hasRequiredCustomFields,
      stockMode: stockMode,
      basePriceMode: basePriceMode,
      pricePermissionDenied: pricePermissionDenied,
    );

    return ProductControlCenterDto(
      profile: ProductProfileSummaryDto(
        productId: id,
        name: name,
        tradeName: tradeName,
        sku: sku?.isEmpty == true ? null : sku,
        barcode: barcode?.isEmpty == true ? null : barcode,
        businessStatus: businessStatus,
        isSoftDeleted: isSoftDeleted,
        primaryImageUrl: images.isNotEmpty ? images.first : null,
        images: images,
        description: description,
        note: note,
      ),
      units: ProductUnitsCardDto(
        baseUnitName: hasBaseUnit ? baseUnit : null,
        isMissing: !hasBaseUnit,
        missingMessage: hasBaseUnit ? null : 'Thiếu đơn vị cơ sở',
      ),
      stock: ProductStockCardDto(
        mode: stockMode,
        source: stockMode == StockMode.advanced
            ? StockDataSource.inventoryModule
            : StockDataSource.basicProfile,
        sourceLabel: stockMode == StockMode.advanced
            ? 'Tồn kho từ module Kho'
            : 'Tồn kho cơ bản',
        quantity: stockQty,
        unitName: hasBaseUnit ? baseUnit : null,
        isConfigured: hasStock,
        isOutOfStock: hasStock && stockQty == 0,
        canAdjust: stockMode == StockMode.basic && hasBaseUnit,
        currentVersion: stockVersion,
        isPendingExternal: stockMode == StockMode.advanced,
        isMissing: stockMode == StockMode.basic && !hasStock,
        missingMessage: stockMode == StockMode.basic && !hasStock ? 'Thiếu tồn kho' : null,
      ),
      basePrice: ProductBasePriceCardDto(
        mode: basePriceMode,
        sourceLabel: ProductBasePriceCardDto.sourceLabelFor(basePriceMode),
        amount: baseCost,
        baseUnitName: hasBaseUnit ? baseUnit : null,
        canEdit: basePriceMode == BasePriceMode.manual && hasBaseUnit,
        isPendingExternal: basePriceMode == BasePriceMode.costingModule,
        isMissing: basePriceMode == BasePriceMode.manual && !hasBasePrice,
        missingMessage: basePriceMode == BasePriceMode.manual && !hasBasePrice
            ? 'Thiếu Giá cơ sở định giá'
            : null,
      ),
      priceBand: ProductPriceBandCardDto(
        listPrice: listPrice,
        floorPrice: floorPrice,
        unitName: hasBaseUnit ? baseUnit : null,
        isMissing: !hasPriceBand,
        missingMessage: !hasPriceBand ? 'Thiếu khung giá bán' : null,
        sourceType: priceBandSourceType,
        storePriceRuleName: storePriceRuleName,
        isCustomOverride: isCustomOverride,
      ),
      customFieldGroupCards: customFieldGroupCards,
      readinessSummary: readinessView.readinessSummary,
      checklist: const [],
      contextualActions: readinessView.suggestedActions,
      changeHistoryPreview: changeHistoryPreview,
      primaryActionId: readinessView.primaryActionId,
    );
  }
}
