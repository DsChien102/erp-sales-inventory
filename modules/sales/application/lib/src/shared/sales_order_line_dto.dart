import 'money_dto.dart';
import 'product_snapshot_dto.dart';
import 'product_unit_snapshot_dto.dart';
import 'quantity_dto.dart';

final class SalesOrderLineDto {
  const SalesOrderLineDto({
    required this.lineId,
    required this.product,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.note,
  });

  final String lineId;
  final ProductSnapshotDto product;
  final ProductUnitSnapshotDto unit;
  final QuantityDto quantity;
  final MoneyDto unitPrice;
  final MoneyDto lineTotal;
  final String? note;
}
