import '../shared/checkout_line_input.dart';
import '../shared/customer_snapshot_dto.dart';
import '../shared/pricing_snapshot_dto.dart';

abstract interface class ISalesPricingPort {
  Future<PricingSnapshotDto> previewPrice({
    required String tenantId,
    required String storeId,
    required CheckoutLineInput line,
    CustomerSnapshotDto? customer,
  });
}
