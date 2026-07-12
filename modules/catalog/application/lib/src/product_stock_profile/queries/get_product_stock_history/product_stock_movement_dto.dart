import 'package:vet45_catalog_application/src/product_stock_profile/shared/stock_movement_type.dart';

final class ProductStockMovementDto {
  const ProductStockMovementDto({
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
  final int quantityBefore;
  final int quantityAfter;
  final int delta;
  final String? reason;
}
