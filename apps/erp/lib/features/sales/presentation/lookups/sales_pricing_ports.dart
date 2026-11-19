import 'package:erp/features/sales/presentation.dart';

/// ERP-owned pricing ports for compose / manual-price orchestration.
/// Kept out of `c45_sales_presentation` so the module stays BC-local.

typedef SalesPricingPreviewFn =
    Future<SalesPricingPreviewResult> Function(
      SalesPricingPreviewRequest request,
    );

typedef SalesManualPriceEvaluateFn =
    Future<SalesManualPriceEvaluation> Function(
      SalesManualPriceRequest request,
    );

typedef SalesPrivatePriceSaveFn =
    Future<SalesPrivatePriceSaveResult> Function(
      SalesPrivatePriceSaveRequest request,
    );
