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

  group('rebateEstimateLines', () {
    const rebateHint = ProgramHint(
      programId: 'p3',
      programName: 'A - Nobivac mốc 100',
      kind: ProgramKind.volumeRebate,
      rebate: (progress: 0, target: 100, wouldReach: false),
    );

    test('lines_full', () {
      expect(
        rebateEstimateLines(rebateHint, 5, 'hộp', paidQty: 60, unitPrice: 100000),
        [
          'Còn thiếu 40 hộp để đạt mốc 100.',
          'Nếu nhập đủ mốc với đơn giá này: giảm 5% ≈ 500.000 đ.',
          'Giá vốn dự kiến ≈ 95.000đ/hộp. Dự kiến, chưa ghi sổ; chưa tính hàng đang tồn.',
        ],
      );
    });

    test('lines_no_price_hides_money', () {
      expect(
        rebateEstimateLines(rebateHint, 5, 'hộp', paidQty: 60, unitPrice: 0),
        ['Còn thiếu 40 hộp để đạt mốc 100.'],
      );
    });

    test('lines_reached_no_missing', () {
      final lines = rebateEstimateLines(rebateHint, 5, 'hộp', paidQty: 100, unitPrice: 100000);
      expect(lines.any((l) => l.startsWith('Còn thiếu')), isFalse);
      expect(lines.length, 2);
    });

    test('lines_base_unit_conversion', () {
      // 6 thùng × 10 = 60 hộp; giá thùng 1.000.000 => 100.000/hộp (đã quy về ĐVT cơ sở)
      expect(
        rebateEstimateLines(rebateHint, 5, 'hộp', paidQty: 6 * 10, unitPrice: 1000000 / 10),
        rebateEstimateLines(rebateHint, 5, 'hộp', paidQty: 60, unitPrice: 100000),
      );
    });

    test('lines_other_kinds_empty', () {
      const tier = ProgramHint(
        programId: 'p1',
        programName: 'Bậc SL',
        kind: ProgramKind.tierDiscount,
      );
      const buyXGetY = ProgramHint(
        programId: 'p2',
        programName: 'Mua 10 tặng 1',
        kind: ProgramKind.buyXGetY,
        buyQty: 10,
        freeQty: 1,
      );
      expect(rebateEstimateLines(tier, 5, 'hộp', paidQty: 60, unitPrice: 100000), isEmpty);
      expect(rebateEstimateLines(buyXGetY, 5, 'hộp', paidQty: 60, unitPrice: 100000), isEmpty);
    });

    test('lines_without_percent_only_missing', () {
      expect(
        rebateEstimateLines(rebateHint, null, 'hộp', paidQty: 60, unitPrice: 100000),
        ['Còn thiếu 40 hộp để đạt mốc 100.'],
      );
    });
  });
}
