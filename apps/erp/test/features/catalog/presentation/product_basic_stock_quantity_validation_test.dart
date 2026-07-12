import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

void main() {
  group('ProductGuidedCreateState basic stock integer validation', () {
    test('rejects fractional quantity 1.5', () {
      const state = ProductGuidedCreateState(basicStockQuantityBase: '1.5');

      expect(state.parsedBasicStockQuantityBase, isNull);
      expect(
        state.basicStockQuantityBaseError,
        'Tồn kho phải là số nguyên hợp lệ',
      );
    });

    test('accepts non-negative integer quantity', () {
      const state = ProductGuidedCreateState(basicStockQuantityBase: '150');

      expect(state.parsedBasicStockQuantityBase, 150);
      expect(state.basicStockQuantityBaseError, isNull);
    });

    test('rejects negative quantity', () {
      const state = ProductGuidedCreateState(basicStockQuantityBase: '-3');

      expect(state.parsedBasicStockQuantityBase, isNull);
      expect(
        state.basicStockQuantityBaseError,
        'Tồn kho ban đầu không được âm',
      );
    });
  });
}
