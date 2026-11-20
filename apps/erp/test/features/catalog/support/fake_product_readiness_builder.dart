import 'package:erp/features/catalog/data/models/catalog_enums.dart';
import 'package:erp/features/catalog/data/models/product_readiness.dart';
import 'package:erp/features/catalog/logic/product_readiness.dart';

/// Builds [ProductReadinessViewDto] for [FakeCatalogBackend] scenarios.
abstract final class FakeProductReadinessBuilder {
  static const stockModeBasic = StockMode.basic;
  static const stockModeAdvanced = StockMode.advanced;
  static const basePriceModeManual = BasePriceMode.manual;
  static const basePriceModeCosting = BasePriceMode.costingModule;

  static ProductReadinessViewDto build({
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
    bool pricePermissionDenied = false,
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
    final permissions = ProductReadinessPermissionContext(
      canManageUnits: true,
      canManageStock: true,
      canManagePricing: !pricePermissionDenied,
      canUpdateProduct: true,
      canCreateProduct: true,
      canViewDetail: true,
    );

    return ProductReadinessViewAssembler.assemble(
      facts: facts,
      readiness: readiness,
      permissions: permissions,
    );
  }
}

