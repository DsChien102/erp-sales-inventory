import 'package:vet45_catalog_application/application.dart';

abstract final class ProductStockMapper {
  static ProductStockMovementReadRow movementReadRowFromRpc(
    Map<String, dynamic> row,
  ) {
    return ProductStockMovementReadRow(
      id: row['id'] as String,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      actorDisplayName: row['actor_display_name'] as String,
      movementType: _movementTypeFromRpc(row['movement_type'] as String),
      quantityBefore: (row['quantity_before'] as num).toDouble(),
      quantityAfter: (row['quantity_after'] as num).toDouble(),
      delta: (row['delta'] as num).toDouble(),
      reason: row['reason'] as String?,
    );
  }

  static StockMovementType _movementTypeFromRpc(String value) {
    return switch (value) {
      'adjust' => StockMovementType.adjust,
      _ => StockMovementType.initial,
    };
  }
}
