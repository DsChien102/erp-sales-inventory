import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/receipt_hint_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('receipt_hint_rules', () {
    test('tier_hint_boundaries', () {
      // paid = 280 -> tier 100 (3%), nextTier 300 (5%, missing 20)
      const hintBoth = ProgramHint(
        programId: 'p1',
        programName: 'Bậc SL',
        kind: ProgramKind.tierDiscount,
        tier: (minQty: 100, percent: 3, discountVnd: 840000),
        nextTier: (minQty: 300, percent: 5, missingQty: 20),
      );
      expect(
        hintLines(hintBoth, 'hộp'),
        [
          'Đang áp bậc từ 100: giảm 3%',
          'Nhập thêm 20 hộp để được giảm 5%',
        ],
      );

      // paid = 100 -> tier 100 (3%), nextTier 300 (5%, missing 200)
      const hintAtBoundary = ProgramHint(
        programId: 'p1',
        programName: 'Bậc SL',
        kind: ProgramKind.tierDiscount,
        tier: (minQty: 100, percent: 3, discountVnd: 300000),
        nextTier: (minQty: 300, percent: 5, missingQty: 200),
      );
      expect(
        hintLines(hintAtBoundary, 'hộp').first,
        'Đang áp bậc từ 100: giảm 3%',
      );

      // paid = 500 -> tier 300 (5%), nextTier null
      const hintTop = ProgramHint(
        programId: 'p1',
        programName: 'Bậc SL',
        kind: ProgramKind.tierDiscount,
        tier: (minQty: 300, percent: 5, discountVnd: 2500000),
      );
      expect(
        hintLines(hintTop, 'hộp'),
        ['Đang áp bậc từ 300: giảm 5%'],
      );

      // paid = 50 -> tier null, nextTier 100 (3%, missing 50)
      const hintBelow = ProgramHint(
        programId: 'p1',
        programName: 'Bậc SL',
        kind: ProgramKind.tierDiscount,
        nextTier: (minQty: 100, percent: 3, missingQty: 50),
      );
      expect(
        hintLines(hintBelow, 'hộp'),
        ['Nhập thêm 50 hộp để được giảm 3%'],
      );
    });

    test('buy_x_zero_free', () {
      const hintZero = ProgramHint(
        programId: 'p2',
        programName: 'Mua 10 tặng 1',
        kind: ProgramKind.buyXGetY,
        buyQty: 10,
        freeQty: 1,
        suggestedFreeQty: 0,
      );
      expect(
        hintLines(hintZero, 'hộp'),
        ['Mua đủ 10 hộp để được tặng 1'],
      );

      const hintPositive = ProgramHint(
        programId: 'p2',
        programName: 'Mua 10 tặng 1',
        kind: ProgramKind.buyXGetY,
        buyQty: 10,
        freeQty: 1,
        suggestedFreeQty: 2,
      );
      expect(
        hintLines(hintPositive, 'hộp'),
        ['Tặng 2 hộp (mua 10 tặng 1)'],
      );
    });

    test('volume_would_reach_suffix', () {
      const hintNotReached = ProgramHint(
        programId: 'p3',
        programName: 'Mốc 1.000 hộp Q4',
        kind: ProgramKind.volumeRebate,
        rebate: (progress: 400, target: 1000, wouldReach: false),
      );
      expect(
        hintLines(hintNotReached, 'hộp', paidQty: 200),
        ['Tính vào chương trình "Mốc 1.000 hộp Q4": 400 + 200 / 1.000 hộp'],
      );

      const hintReached = ProgramHint(
        programId: 'p3',
        programName: 'Mốc 1.000 hộp Q4',
        kind: ProgramKind.volumeRebate,
        rebate: (progress: 400, target: 1000, wouldReach: true),
      );
      expect(
        hintLines(hintReached, 'hộp', paidQty: 600),
        [
          'Tính vào chương trình "Mốc 1.000 hộp Q4": 400 + 600 / 1.000 hộp — đạt mốc khi ghi phiếu',
        ],
      );
    });
  });
}

