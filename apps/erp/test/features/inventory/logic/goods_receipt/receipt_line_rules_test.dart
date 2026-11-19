import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_line_rules.dart';

void main() {
  const dummyProductLot = ReceiptProductOption(
    id: 'p-lot',
    name: 'Vắc xin Dại',
    code: 'SP-LOT',
    barcode: null,
    baseUom: 'hộp',
    isLotTracked: true,
    expiryRequired: true,
    units: [ReceiptUnitOption(id: 'u-base', name: 'hộp', rate: 1, isBase: true)],
  );

  const dummyProductNone = ReceiptProductOption(
    id: 'p-none',
    name: 'Nobivac',
    code: 'SP-01',
    barcode: null,
    baseUom: 'hộp',
    isLotTracked: false,
    expiryRequired: false,
    units: [ReceiptUnitOption(id: 'u-base', name: 'hộp', rate: 1, isBase: true)],
  );

  const dummyUnit = ReceiptUnitOption(id: 'u-base', name: 'hộp', rate: 1, isBase: true);

  group('receipt_line_rules lineInvalidReason', () {
    test('missing_lot_code', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: '', expiryText: '30/11/2026', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Nhập mã lô');
    });

    test('duplicate_lot_code', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '30/11/2026', manufactureText: '', quantity: 10),
          ReceiptLotEntry(key: 'l2', code: 'dh1 ', expiryText: '30/11/2026', manufactureText: '', quantity: 5),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Lô này đã được thêm');
    });

    test('missing_expiry_when_required', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Nhập hạn dùng');
    });

    test('invalid_expiry_format', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '31/02/2026', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Hạn dùng chưa đúng dạng');
    });

    test('invalid_manufacture_format', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '30/11/2026', manufactureText: '99/99/2026', quantity: 10),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Ngày sản xuất chưa đúng dạng');
    });

    test('known_lot_expiry_mismatch_blocks', () {
      final known = [
        const KnownLot(
          productId: 'p-lot',
          code: 'DH1',
          expiry: LotDate(year: 2026, month: 11, day: 30),
        ),
      ];
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'dh1 ', expiryText: '12/2026', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: known), 'Lô dh1  đã có hạn dùng 30/11/2026');
    });

    test('known_lot_same_expiry_ok', () {
      final known = [
        const KnownLot(
          productId: 'p-lot',
          code: 'DH1',
          expiry: LotDate(year: 2026, month: 11, day: 30),
        ),
      ];
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '30/11/2026', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: known), isNull);
    });

    test('zero_lot_quantity', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '30/11/2026', manufactureText: '', quantity: 0),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Nhập số lượng nhận.');
    });

    test('zero_none_lot_quantity', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 0),
        ],
        unitPriceVnd: 100000,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Nhập số lượng nhận.');
    });

    test('zero_unit_price', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 0,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Nhập giá mua.');
    });

    test('free_qty_gte_total_qty', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
        freeQty: 10,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'SL tặng phải nhỏ hơn số lượng nhận');
    });

    test('invalid_tier_percent', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [
          ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10),
        ],
        unitPriceVnd: 100000,
        tierPercent: 105,
      );
      expect(lineInvalidReason(line, knownLots: const []), 'Mức giảm từ 0 đến 100%');
    });
  });

  group('applyHint autofill and rules', () {
    const crateUnit = ReceiptUnitOption(id: 'u-crate', name: 'thùng', rate: 10, isBase: false);

    test('free_autofill_only_when_divisible', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: crateUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 2)],
        unitPriceVnd: 500000,
      );

      // Gợi ý tặng 2 hộp (không chia hết cho 10) -> freeQty giữ 0
      final hint2 = const ProgramHint(
        programId: 'prog-1',
        programName: 'Mua 10 tặng 1',
        kind: ProgramKind.buyXGetY,
        suggestedFreeQty: 2,
      );
      final applied2 = applyHint(line, hint2);
      expect(applied2.freeQty, 0);

      // Gợi ý tặng 20 hộp (chia hết 10 = 2 thùng) -> freeQty = 2
      final hint20 = const ProgramHint(
        programId: 'prog-1',
        programName: 'Mua 10 tặng 10',
        kind: ProgramKind.buyXGetY,
        suggestedFreeQty: 20,
      );
      final applied20 = applyHint(line, hint20);
      expect(applied20.freeQty, 2);
    });

    test('manual_free_not_overwritten', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: crateUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 2)],
        unitPriceVnd: 500000,
        freeQty: 1,
        freeEdited: true,
      );
      final hint20 = const ProgramHint(
        programId: 'prog-1',
        programName: 'Mua 10 tặng 10',
        kind: ProgramKind.buyXGetY,
        suggestedFreeQty: 20,
      );
      final applied = applyHint(line, hint20);
      expect(applied.freeQty, 1);
    });

    test('tier_autofill_and_manual', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 100)],
        unitPriceVnd: 100000,
      );
      const hint = ProgramHint(
        programId: 'prog-tier',
        programName: 'Giảm bậc',
        kind: ProgramKind.tierDiscount,
        tier: (minQty: 100, percent: 3.0, discountVnd: 30000),
      );
      final applied = applyHint(line, hint);
      expect(applied.tierPercent, 3.0);
      expect(applied.programId, 'prog-tier');

      final lineManual = applied.copyWith(tierPercent: 5.0, tierEdited: true);
      final reapplied = applyHint(lineManual, hint);
      expect(reapplied.tierPercent, 5.0);
    });

    test('hint_null_clears_program', () {
      final line = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
        programId: 'p-1',
        tierPercent: 5.0,
      );
      final cleared = applyHint(line, null);
      expect(cleared.programId, isNull);
      expect(cleared.tierPercent, isNull);
    });

    test('offer_summary_parts', () {
      final l1 = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
        tierPercent: 5.0,
        freeQty: 1,
      );
      expect(offerSummary(l1), 'Giảm 5% · tặng 1 hộp');

      final l2 = ReceiptLineDraft(
        key: 'k2',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
      );
      expect(offerSummary(l2), isNull);
    });

    test('review_attention_order', () {
      final line1 = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
        programId: 'p1',
        hintAtEntry: const ProgramHint(programId: 'p1', programName: 'Cũ', kind: ProgramKind.tierDiscount),
        hint: const ProgramHint(programId: 'p2', programName: 'Mới', kind: ProgramKind.tierDiscount),
      );

      final line2 = ReceiptLineDraft(
        key: 'k2',
        product: dummyProductLot,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: 'DH1', expiryText: '30/11/2026', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
        tierPercent: 10.0,
        tierEdited: true,
        hint: const ProgramHint(
          programId: 'p3',
          programName: 'Bậc',
          kind: ProgramKind.tierDiscount,
          tier: (minQty: 10, percent: 5.0, discountVnd: 50000),
        ),
      );

      final line3 = ReceiptLineDraft(
        key: 'k3',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
        hint: const ProgramHint(
          programId: 'p4',
          programName: 'Tích lũy',
          kind: ProgramKind.volumeRebate,
          rebate: (progress: 0, target: 100, wouldReach: true),
        ),
      );

      final attentions = reviewAttention([line1, line2, line3]);
      expect(attentions.length, 3);
      expect(attentions[0].tone, VComponentTone.warning);
      expect(attentions[0].title, 'Ưu đãi đã cập nhật');
      expect(attentions[1].tone, VComponentTone.warning);
      expect(attentions[1].title, 'Đã sửa mức giảm');
      expect(attentions[2].tone, VComponentTone.info);
      expect(attentions[2].title, 'Đạt mốc khi ghi phiếu');
    });

    test('apply_hint_non_tier_clears_tier', () {
      final lineWithTier = ReceiptLineDraft(
        key: 'k1',
        product: dummyProductNone,
        unit: dummyUnit,
        lots: const [ReceiptLotEntry(key: 'l1', code: '', expiryText: '', manufactureText: '', quantity: 10)],
        unitPriceVnd: 100000,
        tierPercent: 5.0,
        tierEdited: false,
      );
      final appliedBuyX = applyHint(
        lineWithTier,
        const ProgramHint(programId: 'bxy', programName: 'Tặng', kind: ProgramKind.buyXGetY, buyQty: 10, freeQty: 1),
      );
      expect(appliedBuyX.tierPercent, isNull);
    });
  });
}
