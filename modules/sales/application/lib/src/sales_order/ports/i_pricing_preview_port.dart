import '../../shared/pricing_preview_dto.dart';
import '../../shared/sales_order_working_state_dto.dart';

/// Port for Theme-4 pricing preview against a frozen compose working-state DTO.
///
/// Manual price / floor policy stays with Pricing; Sales only requests a preview
/// for the current line set. Compose mutation lives in ERP presentation.
abstract interface class IPricingPreviewPort {
  Future<PricingPreviewDto> previewWorkingState({
    required String tenantId,
    required SalesOrderWorkingStateDto workingState,
  });
}
