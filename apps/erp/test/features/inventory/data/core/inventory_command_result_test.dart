import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/inventory/data/core/inventory_command_result.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';

void main() {
  group('InventoryCommandResult', () {
    test('parses_full_shape', () {
      final json = {
        'movement_ids': ['mov-1', 'mov-2'],
        'lines': [
          {
            'line_id': 'line-1',
            'movement_id': 'mov-1',
            'value_movement_id': 'val-1',
            'unit_cost': 50000.5,
            'amount_vnd': 250000,
            'cost_version_id': 'ver-1',
            'is_provisional': false,
          },
        ],
        'stock_changes': [
          {
            'product_id': 'prod-1',
            'product_name': 'Thuốc Nobivac',
            'base_uom': 'Lọ',
            'before': 10,
            'after': 15,
          },
        ],
      };

      final result = InventoryCommandResult.fromJson(json);
      expect(result.movementIds, ['mov-1', 'mov-2']);
      expect(result.lines.length, 1);
      final line = result.lines.first;
      expect(line.lineId, 'line-1');
      expect(line.movementId, 'mov-1');
      expect(line.valueMovementId, 'val-1');
      expect(line.unitCost, 50000.5);
      expect(line.amountVnd, 250000);
      expect(line.costVersionId, 'ver-1');
      expect(line.isProvisional, false);

      expect(result.stockChanges.length, 1);
      final change = result.stockChanges.first;
      expect(change.productId, 'prod-1');
      expect(change.productName, 'Thuốc Nobivac');
      expect(change.baseUom, 'Lọ');
      expect(change.before, 10);
      expect(change.after, 15);
    });

    test('parses_masked_amounts', () {
      final json = {
        'movement_ids': ['mov-1'],
        'lines': [
          {
            'line_id': 'line-1',
            'movement_id': 'mov-1',
            'value_movement_id': 'val-1',
            'unit_cost': null,
            'amount_vnd': null,
            'cost_version_id': null,
            'is_provisional': true,
          },
        ],
        'stock_changes': [
          {
            'product_id': 'prod-1',
            'product_name': 'Vắc xin',
            'base_uom': 'Liều',
            'before': 0,
            'after': 5,
          },
        ],
      };

      final result = InventoryCommandResult.fromJson(json);
      expect(result.lines.first.unitCost, isNull);
      expect(result.lines.first.amountVnd, isNull);
      expect(result.lines.first.costVersionId, isNull);
      expect(result.lines.first.isProvisional, isTrue);
    });

    test('to_k4_converts_correctly', () {
      final result = InventoryCommandResult(
        movementIds: const ['mov-1'],
        lines: const [],
        stockChanges: const [
          InventoryStockChange(
            productId: 'p-1',
            productName: 'Sản phẩm A',
            baseUom: 'Cái',
            before: 2.5,
            after: 5,
          ),
          InventoryStockChange(
            productId: 'p-2',
            productName: 'Sản phẩm B',
            baseUom: '',
            before: 0,
            after: 10,
          ),
        ],
      );

      final k4 = result.toK4();
      expect(k4.length, 2);
      expect(k4[0].product, 'Sản phẩm A');
      expect(k4[0].before, '2,5 Cái');
      expect(k4[0].after, '5 Cái');

      expect(k4[1].product, 'Sản phẩm B');
      expect(k4[1].before, '0');
      expect(k4[1].after, '10');
    });
  });
}
