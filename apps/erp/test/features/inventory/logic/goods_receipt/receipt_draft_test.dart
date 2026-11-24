import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';

void main() {
  const dummySupplier = ReceiptSupplierOption(
    id: 's-1',
    name: 'Công ty Á Châu',
    code: 'NCC-A',
    isSystem: false,
  );

  const dummyProduct = ReceiptProductOption(
    id: 'p-1',
    name: 'Nobivac',
    code: 'SP-01',
    barcode: null,
    baseUom: 'hộp',
    isLotTracked: false,
    expiryRequired: false,
    units: [ReceiptUnitOption(id: 'u-1', name: 'hộp', rate: 1, isBase: true)],
  );

  const dummyUnit = ReceiptUnitOption(id: 'u-1', name: 'hộp', rate: 1, isBase: true);

  group('ReceiptDraft', () {
    test('payload_matches_contract', () {
      final draft = ReceiptDraft(
        supplier: dummySupplier,
        docNo: 'HĐ 0001523',
        freightVnd: 50000,
        discountVnd: 20000,
        lines: [
          ReceiptLineDraft(
            key: 'line-1',
            product: dummyProduct,
            unit: dummyUnit,
            unitPriceVnd: 100000,
            freeQty: 1,
            tierPercent: 5.0,
            programId: 'prog-1',
            hint: const ProgramHint(
              programId: 'prog-1',
              programName: 'Bậc giảm',
              kind: ProgramKind.tierDiscount,
            ),
            lots: const [
              ReceiptLotEntry(
                key: 'lot-1',
                code: '',
                expiryText: '',
                manufactureText: '',
                quantity: 11,
              ),
            ],
          ),
        ],
      );

      final payload = draft.toPayload();
      expect(payload['supplier_id'], 's-1');
      expect(payload['supplier_doc_no'], 'HĐ 0001523');
      expect(payload['freight_cost_vnd'], 50000);
      expect(payload['trade_discount_vnd'], 20000);

      final lines = payload['lines'] as List;
      expect(lines.length, 1);
      final l = lines.first as Map<String, dynamic>;
      expect(l['product_id'], 'p-1');
      expect(l['unit_id'], 'u-1');
      expect(l['unit_price_vnd'], 100000);
      expect(l['free_qty'], 1);
      expect(l['program_id'], 'prog-1');
      expect(l['tier_discount_percent'], 5.0);

      final lots = l['lots'] as List;
      expect(lots.length, 1);
      final lot = lots.first as Map<String, dynamic>;
      expect(lot['lot_code'], isNull); // non-lot -> lot_code null
      expect(lot['quantity'], 11);
    });

    test('payload_drops_tier_when_program_not_tier', () {
      final draft = ReceiptDraft(
        supplier: dummySupplier,
        lines: [
          ReceiptLineDraft(
            key: 'line-1',
            product: dummyProduct,
            unit: dummyUnit,
            unitPriceVnd: 100000,
            tierPercent: 5.0,
            tierEdited: true,
            hint: const ProgramHint(
              programId: 'prog-bxy',
              programName: 'Tặng',
              kind: ProgramKind.buyXGetY,
            ),
            lots: const [
              ReceiptLotEntry(key: 'l-1', code: '', expiryText: '', manufactureText: '', quantity: 10),
            ],
          ),
        ],
      );
      final payload = draft.toPayload();
      final l = (payload['lines'] as List).first as Map<String, dynamic>;
      expect(l['tier_discount_percent'], isNull);
    });

    test('empty_doc_no_becomes_null', () {
      final draft = ReceiptDraft(
        supplier: dummySupplier,
        docNo: '   ',
        lines: const [],
      );
      final payload = draft.toPayload();
      expect(payload['supplier_doc_no'], isNull);
    });
  });
}

