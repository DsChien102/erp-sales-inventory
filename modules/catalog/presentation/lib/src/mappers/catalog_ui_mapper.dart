import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import '../bloc/product_guided_create_state.dart';
import '../models/product_business_status.dart';
import '../models/product_list_item_model.dart';
import '../models/product_readiness_status.dart';
import '../utils/catalog_currency_formatters.dart';

class CatalogUiMapper {
  static ({int? listBeforeVat, int? floorBeforeVat}) resolvePriceBand(
    ProductGuidedCreateState state,
  ) {
    if (!state.priceBandConfigured) {
      return (listBeforeVat: null, floorBeforeVat: null);
    }

    final baseCost = parseCatalogCurrencyAmount(state.baseCost)?.toDouble();

    if (state.pricingMethod == 'manual') {
      return (
        listBeforeVat: int.tryParse(state.manualListPrice.trim().replaceAll(',', '')),
        floorBeforeVat: int.tryParse(state.manualFloorPrice.trim().replaceAll(',', '')),
      );
    }

    if (baseCost == null) {
      return (listBeforeVat: null, floorBeforeVat: null);
    }

    if (state.pricingMethod == 'storeRule') {
      final listRatio = state.storeRuleListMarkupRatio;
      final floorRatio = state.storeRuleFloorMarkupRatio;
      if (listRatio == null || floorRatio == null) {
        return (listBeforeVat: null, floorBeforeVat: null);
      }
      final suggested = StorePriceSuggestionCalculator.suggest(
        basePrice: baseCost,
        listMarkupRatio: listRatio,
        floorMarkupRatio: floorRatio,
      );
      return (
        listBeforeVat: suggested.listBeforeVat,
        floorBeforeVat: suggested.floorBeforeVat,
      );
    }

    if (state.pricingMethod == 'customAuto' || state.pricingMethod == 'auto') {
      final markup = double.tryParse(state.customAutoMarkup.trim().replaceAll(',', ''));
      final floorMarkup = double.tryParse(
        state.customAutoFloorMarkup.trim().replaceAll(',', ''),
      );
      if (markup == null || floorMarkup == null) {
        return (listBeforeVat: null, floorBeforeVat: null);
      }
      final suggested = StorePriceSuggestionCalculator.suggest(
        basePrice: baseCost,
        listMarkupRatio: markup / 100,
        floorMarkupRatio: floorMarkup / 100,
      );
      return (
        listBeforeVat: suggested.listBeforeVat,
        floorBeforeVat: suggested.floorBeforeVat,
      );
    }

    return (listBeforeVat: null, floorBeforeVat: null);
  }

  static ProductListItemModel toListItemModelFromCreate({
    required ProductGuidedCreateState state,
    required String productId,
    required ReadinessSummaryDto readinessSummary,
  }) {
    final coverDraft = state.imageDrafts.isNotEmpty
        ? state.imageDrafts[state.coverImageIndex.clamp(0, state.imageDrafts.length - 1)]
        : null;
    final coverPath = coverDraft?.localPath;

    final stockQty = state.parsedBasicStockQuantityBase;
    final baseCost = parseCatalogCurrencyAmount(state.baseCost)?.toDouble();

    final priceBand = resolvePriceBand(state);
    final listBeforeVat = priceBand.listBeforeVat;
    final floorBeforeVat = priceBand.floorBeforeVat;

    ProductReadinessStatus readiness;
    if (state.baseUnit.trim().isEmpty) {
      readiness = ProductReadinessStatus.missingBaseUnit;
    } else if (stockQty == null) {
      readiness = ProductReadinessStatus.missingStockSource;
    } else if (listBeforeVat == null) {
      readiness = ProductReadinessStatus.missingPriceBand;
    } else {
      readiness = ProductReadinessStatus.ready;
    }

    return ProductListItemModel(
      id: productId,
      name: state.name.trim(),
      tradeName: state.tradeName.isNotEmpty ? state.tradeName : null,
      sku: state.sku.isNotEmpty ? state.sku : null,
      barcode: state.barcode.isNotEmpty ? state.barcode : null,
      imageUrl: coverPath != null && coverPath.startsWith('http') ? coverPath : null,
      businessStatus: ProductBusinessStatus.active,
      readinessStatus: readiness,
      baseUnit: state.baseUnit.isNotEmpty ? state.baseUnit : null,
      images: state.imageDrafts.map((d) => d.localPath).toList(),
      stockQty: stockQty,
      baseCost: baseCost,
      listBeforeVat: listBeforeVat,
      floorBeforeVat: floorBeforeVat,
    );
  }

  /// Minimal PCC stub when opening a duplicate match (slice #1).
  static ProductListItemModel minimalFromDuplicate({
    required String productId,
    required String productName,
    String? sku,
    String? barcode,
  }) {
    return ProductListItemModel(
      id: productId,
      name: productName,
      sku: sku,
      barcode: barcode,
      businessStatus: ProductBusinessStatus.active,
      readinessStatus: ProductReadinessStatus.needsReview,
    );
  }
}
