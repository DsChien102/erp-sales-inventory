import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation.dart';

import '../support/compose_line_test_data.dart';

SalesComposeLineVm _line({
  required String lineId,
  required int quantity,
  required int listMinor,
  required int appliedMinor,
  int? pricedUnitDiscountMinor,
  int? pricedLineTotalMinor,
}) {
  return composeTestLine(
    lineId: lineId,
    productId: 'prod-$lineId',
    productUnitId: 'unit-$lineId',
    productName: 'SP $lineId',
    unitLabel: 'Hộp',
    quantity: quantity,
    baseUnitPrice: composeTestMoney(listMinor),
    appliedUnitPrice: composeTestMoney(appliedMinor),
    listUnitPrice: composeTestMoney(listMinor),
    pricedUnitDiscountMinor: pricedUnitDiscountMinor,
    pricedLineTotalMinor: pricedLineTotalMinor,
    pricedContextVersion: pricedLineTotalMinor == null ? -1 : 1,
  );
}

void main() {
  group('SalesComposeTotals', () {
    test('sold below list → merchandise at list, gap goes to discount', () {
      final totals = SalesComposeTotals.fromLines([
        _line(
          lineId: 'l1',
          quantity: 2,
          listMinor: 20000,
          appliedMinor: 20000,
          pricedUnitDiscountMinor: 3000,
          pricedLineTotalMinor: 34000,
        ),
      ]);

      expect(totals.itemCount, 2);
      expect(totals.merchandiseAmountMinor, 40000);
      expect(totals.discountMinor, 6000);
      expect(totals.netAmountMinor, 34000);
    });

    test('provisional applied below list uses list−sold as discount', () {
      final totals = SalesComposeTotals.fromLines([
        _line(lineId: 'l1', quantity: 3, listMinor: 10000, appliedMinor: 9000),
      ]);

      expect(totals.merchandiseAmountMinor, 30000);
      expect(totals.discountMinor, 3000);
      expect(totals.netAmountMinor, 27000);
    });

    test('manual price above list raises merchandise; discount stays 0', () {
      final totals = SalesComposeTotals.fromLines([
        _line(
          lineId: 'l1',
          quantity: 2,
          listMinor: 10000,
          appliedMinor: 15000,
          pricedUnitDiscountMinor: 0,
          pricedLineTotalMinor: 30000,
        ),
      ]);

      expect(totals.merchandiseAmountMinor, 30000);
      expect(totals.discountMinor, 0);
      expect(totals.netAmountMinor, 30000);
    });

    test('mixed lines: uplift and discount keep net = Σ sold', () {
      final totals = SalesComposeTotals.fromLines([
        _line(
          lineId: 'above',
          quantity: 1,
          listMinor: 10000,
          appliedMinor: 12000,
          pricedUnitDiscountMinor: 0,
          pricedLineTotalMinor: 12000,
        ),
        _line(
          lineId: 'below',
          quantity: 1,
          listMinor: 10000,
          appliedMinor: 8000,
          pricedUnitDiscountMinor: 0,
          pricedLineTotalMinor: 8000,
        ),
      ]);

      expect(totals.merchandiseAmountMinor, 22000); // 12000 + 10000
      expect(totals.discountMinor, 2000); // 0 + 2000
      expect(totals.netAmountMinor, 20000); // 12000 + 8000
    });

    test('order-level discount stacks on line discount', () {
      final totals = SalesComposeTotals.fromLines(
        [
          _line(
            lineId: 'l1',
            quantity: 1,
            listMinor: 50000,
            appliedMinor: 50000,
            pricedUnitDiscountMinor: 0,
            pricedLineTotalMinor: 50000,
          ),
        ],
        orderDiscountMinor: 5000,
      );

      expect(totals.merchandiseAmountMinor, 50000);
      expect(totals.discountMinor, 5000);
      expect(totals.netAmountMinor, 45000);
    });
  });
}
