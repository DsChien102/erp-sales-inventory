import 'money_dto.dart';
import 'product_snapshot_dto.dart';
import 'product_unit_snapshot_dto.dart';
import 'quantity_dto.dart';

/// Whether a derived current-holding line traces back to the original order
/// line or was introduced by a subsequent exchange.
enum SalesOrderLineSource { original, exchange }

/// A derived "current holdings" line for a sales order: what the customer
/// effectively holds after applying completed return/exchange history on top
/// of the original order lines.
final class SalesOrderCurrentLineDto {
  const SalesOrderCurrentLineDto({
    required this.product,
    required this.unit,
    required this.heldQuantity,
    required this.unitPrice,
    required this.source,
  });

  final ProductSnapshotDto product;
  final ProductUnitSnapshotDto unit;
  final QuantityDto heldQuantity;
  final MoneyDto unitPrice;
  final SalesOrderLineSource source;
}
