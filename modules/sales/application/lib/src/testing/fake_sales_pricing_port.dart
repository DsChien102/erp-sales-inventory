import '../ports/i_sales_pricing_port.dart';
import '../shared/checkout_line_input.dart';
import '../shared/customer_snapshot_dto.dart';
import '../shared/pricing_snapshot_dto.dart';

final class FakeSalesPricingPort implements ISalesPricingPort {
  const FakeSalesPricingPort({required this.snapshot});

  final PricingSnapshotDto snapshot;

  @override
  Future<PricingSnapshotDto> previewPrice({
    required String tenantId,
    required String storeId,
    required CheckoutLineInput line,
    CustomerSnapshotDto? customer,
  }) async => snapshot;
}
