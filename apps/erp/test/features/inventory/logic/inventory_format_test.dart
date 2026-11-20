import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory_format', () {
    test('format_quantity', () {
      expect(formatQuantity(106), '106');
      expect(formatQuantity(1.5), '1,5');
      expect(formatQuantity(0.25), '0,25');
    });

    test('format_stock_quantity', () {
      expect(formatStockQuantity(41, 'hộp'), '41 hộp');
      expect(formatStockQuantity(1.5, 'chai'), '1,5 chai');
    });
  });
}
