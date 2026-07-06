import 'stock_movement_type.dart';

final class ProductStockMovementReadRow {
  const ProductStockMovementReadRow({
    required this.id,
    required this.occurredAt,
    required this.actorDisplayName,
    required this.movementType,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.delta,
    this.reason,
  });

  final String id;
  final DateTime occurredAt;
  final String actorDisplayName;
  final StockMovementType movementType;
  final double quantityBefore;
  final double quantityAfter;
  final double delta;
  final String? reason;
}
