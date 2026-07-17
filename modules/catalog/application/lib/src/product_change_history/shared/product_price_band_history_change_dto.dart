import 'product_price_band_history_snapshot_dto.dart';
import 'product_price_band_history_trigger.dart';

final class ProductPriceBandHistoryChangeDto {
  const ProductPriceBandHistoryChangeDto({
    required this.productUnitId,
    required this.unitName,
    required this.currency,
    required this.trigger,
    required this.after,
    this.before,
  });

  final String productUnitId;
  final String unitName;
  final String currency;
  final ProductPriceBandHistoryTrigger trigger;
  final ProductPriceBandHistorySnapshotDto? before;
  final ProductPriceBandHistorySnapshotDto after;
}
