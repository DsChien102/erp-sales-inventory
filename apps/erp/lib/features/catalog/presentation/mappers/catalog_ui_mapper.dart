import '../../data/models.dart';
import '../../logic/product_guided_create_state.dart';
import '../../logic/store_price_suggestion.dart';
import '../models/product_list_item_model.dart';
import '../models/product_readiness_status.dart';
import '../utils/catalog_currency_formatters.dart';

class CatalogUiMapper {
  static ({int? listBeforeVat, int? floorBeforeVat}) resolvePriceBand(
    ProductGuidedCreateState state,
  ) {
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

    final baseCost = parseCatalogCurrencyAmount(state.baseCost)?.toDouble();

    // Manual / calculated amounts are treated as after-VAT (UI default).
    // Guided create wire still uses before-VAT command params; BE/fake mirror after ← before.
    final priceBand = resolvePriceBand(state);
    final listBeforeVat = priceBand.listBeforeVat;
    final floorBeforeVat = priceBand.floorBeforeVat;
    // Until VAT rate exists for price bands, after == before (mirror).
    final listAfterVat = listBeforeVat;
    final floorAfterVat = floorBeforeVat;

    ProductReadinessStatus readiness;
    if (state.baseUnit.trim().isEmpty) {
      readiness = ProductReadinessStatus.missingBaseUnit;
    } else if (listAfterVat == null) {
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
      stockQty: null,
      baseCost: baseCost,
      listBeforeVat: listBeforeVat,
      floorBeforeVat: floorBeforeVat,
      listAfterVat: listAfterVat,
      floorAfterVat: floorAfterVat,
      trackingMode: state.trackingMode,
      expiryRequired: state.expiryRequired,
      hasInventoryMovements: false,
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

  /// Build or refresh a [ProductListItemModel] from [ProductControlCenterDto].
  ///
  /// Used by PCC when loaded by ID on web/desktop so sub-screens and delete dialogs
  /// receive a consistent [ProductListItemModel] without relying on `extra`.
  static ProductListItemModel listItemFromControlCenter(
    ProductControlCenterDto cc, {
    ProductListItemModel? base,
  }) {
    final seed = base ??
        minimalFromDuplicate(
          productId: cc.profile.productId,
          productName: cc.profile.name,
          sku: cc.profile.sku,
          barcode: cc.profile.barcode,
        );
    return seed.copyWith(
      name: cc.profile.name,
      tradeName: cc.profile.tradeName,
      sku: cc.profile.sku,
      barcode: cc.profile.barcode,
      images: cc.profile.images,
      imageUrl: cc.profile.primaryImageUrl,
      businessStatus: cc.profile.businessStatus,
      baseUnit: cc.units.baseUnitName,
      notes: cc.profile.note,
      stockQty: cc.stock.quantity,
      trackingMode: cc.profile.trackingMode,
      expiryRequired: cc.profile.expiryRequired,
      hasInventoryMovements: cc.profile.hasInventoryMovements,
    );
  }
}
