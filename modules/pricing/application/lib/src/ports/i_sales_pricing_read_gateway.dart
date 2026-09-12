import '../sales_pricing/queries/evaluate_sales_manual_price/evaluate_sales_manual_price_query.dart';
import '../sales_pricing/shared/sales_manual_price_evaluation_dto.dart';
import '../sales_pricing/shared/sales_working_state_pricing_input.dart';
import '../sales_pricing/shared/sales_working_state_pricing_preview_dto.dart';

abstract interface class ISalesPricingReadGateway {
  Future<SalesWorkingStatePricingPreviewDto> previewWorkingState(
    SalesWorkingStatePricingInput input,
  );

  Future<SalesManualPriceEvaluationDto> evaluateManualPrice(
    EvaluateSalesManualPriceQuery query,
  );
}
