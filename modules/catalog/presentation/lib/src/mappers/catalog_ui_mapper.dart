import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import '../bloc/product_guided_create_state.dart';
import '../models/product_business_status.dart';
import '../models/product_list_item_model.dart';
import '../models/product_readiness_status.dart';

class CatalogUiMapper {
  static ProductListItemModel toListItemModelFromCreate({
    required ProductGuidedCreateState state,
    required String productId,
    required ReadinessSummaryDto readinessSummary,
  }) {
    final readiness = _readinessFromSummary(readinessSummary, state.baseUnit);
    final coverDraft = state.imageDrafts.isNotEmpty
        ? state.imageDrafts[
            state.coverImageIndex.clamp(0, state.imageDrafts.length - 1)]
        : null;
    final coverPath = coverDraft?.localPath;

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

