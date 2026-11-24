import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_cost_rules.dart';

void main() {
  group('receipt_cost_rules', () {
    test('spec_example_4_1', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 6,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 100000,
            tierPercent: null,
            lotQuantities: [6],
          ),
          const ReceiptCostLineInput(
            paidQty: 4,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 100000,
            tierPercent: null,
            lotQuantities: [4],
          ),
        ],
        freightVnd: 50000,
        discountVnd: 20000,
      );

      expect(breakdown.purchaseTotal, 1000000);
      expect(breakdown.landedTotal, 1030000);
      expect(breakdown.discountTooLarge, isFalse);
      expect(breakdown.lines.length, 2);

      final l1 = breakdown.lines[0];
      expect(l1.gross, 600000);
      expect(l1.tierDiscount, 0);
      expect(l1.purchase, 600000);
      expect(l1.freight, 30000);
      expect(l1.discount, 12000);
      expect(l1.landed, 618000);
      expect(l1.landedUnitCost, 103000.0);

      final l2 = breakdown.lines[1];
      expect(l2.gross, 400000);
      expect(l2.tierDiscount, 0);
      expect(l2.purchase, 400000);
      expect(l2.freight, 20000);
      expect(l2.discount, 8000);
      expect(l2.landed, 412000);
      expect(l2.landedUnitCost, 103000.0);
    });

    test('tier_case12', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 300,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 100000,
            tierPercent: 5.0,
            lotQuantities: [300],
          ),
        ],
        freightVnd: 0,
        discountVnd: 0,
      );

      final l = breakdown.lines.single;
      expect(l.gross, 30000000);
      expect(l.tierDiscount, 1500000);
      expect(l.purchase, 28500000);
      expect(l.landed, 28500000);
      expect(l.landedUnitCost, 95000.0);
    });

    test('buy_x_get_y_case13_unit_cost', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 10,
            freeQty: 1,
            rate: 1,
            unitPriceVnd: 50000,
            tierPercent: null,
            lotQuantities: [11],
          ),
        ],
        freightVnd: 0,
        discountVnd: 0,
      );

      final l = breakdown.lines.single;
      expect(l.purchase, 500000);
      expect(l.landed, 500000);
      expect(l.landedUnitCost, closeTo(45454.5455, 0.0001));
    });

    test('allocation_rounding_matches_sql', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 3,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 111112,
            tierPercent: null,
            lotQuantities: [1, 1, 1],
          ),
          const ReceiptCostLineInput(
            paidQty: 1,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 333332,
            tierPercent: null,
            lotQuantities: [1],
          ),
          const ReceiptCostLineInput(
            paidQty: 1,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 333332,
            tierPercent: null,
            lotQuantities: [1],
          ),
        ],
        freightVnd: 100000,
        discountVnd: 10001,
      );

      expect(breakdown.purchaseTotal, 1000000);
      expect(breakdown.landedTotal, 1089999);

      final l1 = breakdown.lines[0];
      expect(l1.purchase, 333336);
      expect(l1.freight, 33334);
      expect(l1.discount, 3335);
      expect(l1.landed, 363335);
      expect(l1.landedUnitCost, closeTo(121111.6667, 0.0001));
      expect(l1.lotAmounts, [121113, 121111, 121111]);

      final l2 = breakdown.lines[1];
      expect(l2.freight, 33333);
      expect(l2.discount, 3333);
      expect(l2.landed, 363332);

      final l3 = breakdown.lines[2];
      expect(l3.freight, 33333);
      expect(l3.discount, 3333);
      expect(l3.landed, 363332);
    });

    test('unit_conversion_landed_cost', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 2,
            freeQty: 0,
            rate: 10,
            unitPriceVnd: 500000,
            tierPercent: null,
            lotQuantities: [2],
          ),
        ],
        freightVnd: 0,
        discountVnd: 0,
      );

      final l = breakdown.lines.single;
      expect(l.purchase, 1000000);
      expect(l.landed, 1000000);
      expect(l.landedUnitCost, 50000.0);
    });

    test('remainder_to_largest_first_on_tie', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 1,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 10000,
            tierPercent: null,
            lotQuantities: [1],
          ),
          const ReceiptCostLineInput(
            paidQty: 1,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 10000,
            tierPercent: null,
            lotQuantities: [1],
          ),
        ],
        freightVnd: 1,
        discountVnd: 0,
      );

      expect(breakdown.lines[0].freight, 1);
      expect(breakdown.lines[1].freight, 0);
    });

    test('discount_too_large_flag', () {
      final breakdown = computeReceiptCost(
        [
          const ReceiptCostLineInput(
            paidQty: 1,
            freeQty: 0,
            rate: 1,
            unitPriceVnd: 100000,
            tierPercent: null,
            lotQuantities: [1],
          ),
        ],
        freightVnd: 50000,
        discountVnd: 150001,
      );

      expect(breakdown.discountTooLarge, isTrue);
    });

    test('sum_invariant', () {
      final rnd = Random(42);
      for (int t = 0; t < 200; t++) {
        final lineCount = rnd.nextInt(5) + 1;
        final lines = <ReceiptCostLineInput>[];
        for (int i = 0; i < lineCount; i++) {
          final lotCount = rnd.nextInt(3) + 1;
          final lotQtys = List.generate(lotCount, (_) => rnd.nextInt(50) + 1);
          final totQty = lotQtys.reduce((a, b) => a + b);
          final freeQty = rnd.nextInt(totQty ~/ 2 + 1);
          final paidQty = totQty - freeQty;
          final price = (rnd.nextInt(500) + 1) * 1000;
          final pct = rnd.nextBool() ? rnd.nextInt(20).toDouble() : null;
          final rate = rnd.nextBool() ? (rnd.nextInt(10) + 1).toDouble() : 1.0;

          lines.add(
            ReceiptCostLineInput(
              paidQty: paidQty,
              freeQty: freeQty,
              rate: rate,
              unitPriceVnd: price,
              tierPercent: pct,
              lotQuantities: lotQtys,
            ),
          );
        }

        final freight = rnd.nextInt(200000);
        final approxPurchase = lines.fold<int>(0, (acc, l) => acc + (l.paidQty * l.unitPriceVnd).round());
        final discount = rnd.nextInt(approxPurchase + freight + 1);

        final res = computeReceiptCost(lines, freightVnd: freight, discountVnd: discount);

        final sumLanded = res.lines.fold<int>(0, (acc, l) => acc + l.landed);
        expect(sumLanded, res.purchaseTotal + freight - discount);

        for (final l in res.lines) {
          final sumLot = l.lotAmounts.fold<int>(0, (acc, a) => acc + a);
          expect(sumLot, l.landed);
        }
      }
    });
  });
}
