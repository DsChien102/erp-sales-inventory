import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('program_form_draft', () {
    test('payload_only_kind_fields', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 'sup-1',
            name: 'Mua 10 tặng 1',
            kind: ProgramKind.buyXGetY,
            productIds: const ['p1'],
            tiers: const [(minQty: '100', percent: '3')],
            buyQty: '10',
            freeQty: '1',
            targetQty: '1000',
            rebatePercent: '5',
          );

      final json = draft.toPayload(forUpdate: false).toJson();

      expect(json['supplier_id'], 'sup-1');
      expect(json['kind'], 'BUY_X_GET_Y');
      expect(json['buy_qty'], 10);
      expect(json['free_qty'], 1);
      expect(json.containsKey('tiers'), isFalse);
      expect(json.containsKey('target_qty'), isFalse);
      expect(json.containsKey('rebate_percent'), isFalse);
    });

    test('kind_switch_keeps_drafts', () {
      var draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            tiers: const [
              (minQty: '100', percent: '3'),
              (minQty: '300', percent: '5'),
            ],
          );

      draft = draft.copyWith(
        kind: ProgramKind.buyXGetY,
        buyQty: '10',
        freeQty: '1',
      );
      expect(draft.kind, ProgramKind.buyXGetY);
      expect(draft.tiers.length, 2);
      expect(draft.tiers[0].minQty, '100');

      draft = draft.copyWith(kind: ProgramKind.tierDiscount);
      expect(draft.kind, ProgramKind.tierDiscount);
      expect(draft.tiers.length, 2);
      expect(draft.tiers[1].minQty, '300');
      expect(draft.buyQty, '10');
      expect(draft.freeQty, '1');
    });

    test('payload_update_omits_supplier_kind', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 'sup-1',
            name: 'Mốc 1.000 hộp',
            kind: ProgramKind.volumeRebate,
            productIds: const ['p1'],
            targetQty: '1000',
            rebatePercent: '5',
          );

      final json = draft.toPayload(forUpdate: true).toJson();

      expect(json.containsKey('supplier_id'), isFalse);
      expect(json.containsKey('kind'), isFalse);
      expect(json['target_qty'], 1000);
      expect(json['rebate_percent'], 5);
    });
  });
}

