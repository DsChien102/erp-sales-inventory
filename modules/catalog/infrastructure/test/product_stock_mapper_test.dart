import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/src/domain/stock/product_stock_mapper.dart';

void main() {
  group('ProductStockMapper', () {
    test('movementReadRowFromRpc maps initial movement', () {
      final row = ProductStockMapper.movementReadRowFromRpc({
        'id': 'movement-1',
        'occurred_at': '2026-01-15T10:30:00.000Z',
        'actor_display_name': 'user-abc',
        'movement_type': 'initial',
        'quantity_before': 0,
        'quantity_after': 50,
        'delta': 50,
        'reason': null,
      });

      expect(row.id, 'movement-1');
      expect(row.movementType, StockMovementType.initial);
      expect(row.quantityAfter, 50);
      expect(row.reason, isNull);
    });

    test('movementReadRowFromRpc maps adjust movement with reason', () {
      final row = ProductStockMapper.movementReadRowFromRpc({
        'id': 'movement-2',
        'occurred_at': '2026-01-15T11:30:00.000Z',
        'actor_display_name': 'user-def',
        'movement_type': 'adjust',
        'quantity_before': 50,
        'quantity_after': 25,
        'delta': -25,
        'reason': 'Kiểm kê',
      });

      expect(row.movementType, StockMovementType.adjust);
      expect(row.delta, -25);
      expect(row.reason, 'Kiểm kê');
    });
  });
}
