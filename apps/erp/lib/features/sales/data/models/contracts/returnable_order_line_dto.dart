import 'money_dto.dart';
import 'product_snapshot_dto.dart';
import 'product_unit_snapshot_dto.dart';
import 'quantity_dto.dart';

final class ReturnableOrderLineDto {
  const ReturnableOrderLineDto({
    this.salesOrderLineId,
    this.sourceExchangeLineId,
    required this.product,
    required this.unit,
    required this.soldQuantity,
    required this.returnableQuantity,
    required this.originalUnitPrice,
  });

  final String? salesOrderLineId;
  final String? sourceExchangeLineId;
  final ProductSnapshotDto product;
  final ProductUnitSnapshotDto unit;
  final QuantityDto soldQuantity;
  final QuantityDto returnableQuantity;
  final MoneyDto originalUnitPrice;

  /// Stable identity of a returnable unit: an original order line id, or a
  /// confirmed exchange line id for exchanged-in goods (ADR-9).
  String get unitId => (salesOrderLineId ?? sourceExchangeLineId)!;
}
