import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import '../bloc/product_guided_create_state.dart';
import '../models/product_business_status.dart';
import '../models/product_list_item_model.dart';
import '../models/product_readiness_status.dart';

class CatalogUiMapper {
  static ({double? listPrice, double? floorPrice}) resolvePriceBand(
    ProductGuidedCreateState state,
  ) {
    if (!state.priceBandConfigured) {
      return (listPrice: null, floorPrice: null);
    }

    final baseCost = double.tryParse(state.baseCost.trim());

    if (state.pricingMethod == 'manual') {
      return (
        listPrice: double.tryParse(state.manualListPrice.trim()),
        floorPrice: double.tryParse(state.manualFloorPrice.trim()),
      );
    }

    if (baseCost == null) {
      return (listPrice: null, floorPrice: null);
    }

    if (state.pricingMethod == 'storeRule') {
      return (
        listPrice: baseCost * 1.35,
        floorPrice: baseCost * 1.15,
      );
    }

    if (state.pricingMethod == 'customAuto' || state.pricingMethod == 'auto') {
      final markup = double.tryParse(state.customAutoMarkup.trim()) ?? 35.0;
      final floorMarkup = double.tryParse(state.customAutoFloorMarkup.trim()) ?? 15.0;
      return (
        listPrice: baseCost * (1 + markup / 100),
        floorPrice: baseCost * (1 + floorMarkup / 100),
      );
    }

    return (listPrice: null, floorPrice: null);
  }

  static ProductListItemModel toListItemModelFromCreate({
    required ProductGuidedCreateState state,
    required String productId,
    required ReadinessSummaryDto readinessSummary,
  }) {
    final coverDraft = state.imageDrafts.isNotEmpty
        ? state.imageDrafts[
            state.coverImageIndex.clamp(0, state.imageDrafts.length - 1)]
        : null;
    final coverPath = coverDraft?.localPath;

    final stockQty = int.tryParse(state.initialStock.trim());
    final baseCost = double.tryParse(state.baseCost.trim());

    final priceBand = resolvePriceBand(state);
    final listPrice = priceBand.listPrice;
    final floorPrice = priceBand.floorPrice;

    ProductReadinessStatus readiness;
    if (state.baseUnit.trim().isEmpty) {
      readiness = ProductReadinessStatus.missingBaseUnit;
    } else if (stockQty == null) {
      readiness = ProductReadinessStatus.missingStockSource;
    } else if (listPrice == null || floorPrice == null) {
      readiness = ProductReadinessStatus.missingPriceBand;
    } else {
      readiness = ProductReadinessStatus.ready;
    }

    return ProductListItemModel(
      id: productId,
      name: state.name.trim(),
      tradeName: state.tradeName.isNotEmpty ? state.tradeName : state.name,
      sku: state.sku.isNotEmpty ? state.sku : null,
      barcode: state.barcode.isNotEmpty ? state.barcode : null,
      imageUrl: coverPath != null && coverPath.startsWith('http') ? coverPath : null,
      businessStatus: ProductBusinessStatus.active,
      readinessStatus: readiness,
      baseUnit: state.baseUnit.isNotEmpty ? state.baseUnit : null,
      images: state.imageDrafts.map((d) => d.localPath).toList(),
      stockQty: stockQty,
      baseCost: baseCost,
      listPrice: listPrice,
      floorPrice: floorPrice,
    );
  }

  static ProductReadinessStatus _readinessFromSummary(
    ReadinessSummaryDto summary,
    String baseUnit,
  ) {
    if (summary.status == ReadinessStatus.readyToSell) {
      return ProductReadinessStatus.ready;
    }

    final codes = summary.blockers.map((b) => b.code).toSet();
    if (codes.contains(ReadinessBlockerCode.missingBaseUnit) || baseUnit.trim().isEmpty) {
      return ProductReadinessStatus.missingBaseUnit;
    }
    if (codes.contains(ReadinessBlockerCode.missingPrice) ||
        codes.contains(ReadinessBlockerCode.missingPriceBand)) {
      return ProductReadinessStatus.missingPriceBand;
    }
    if (codes.contains(ReadinessBlockerCode.missingStock)) {
      return ProductReadinessStatus.missingStockSource;
    }
    return ProductReadinessStatus.needsReview;
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

