import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/models/receipt_actor.dart';
import 'package:erp/features/inventory/data/models/receipt_header_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_item_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_lot_draft.dart';
import 'package:erp/features/inventory/data/models/valuation_group_item.dart';
import 'package:erp/features/inventory/data/models/valuation_work_item.dart';
import 'package:erp/features/inventory/data/valuation_repository.dart';
import 'package:erp/features/inventory/logic/quick_receipt_session_cubit.dart';
import 'package:erp/features/inventory/logic/receipt_approval_cubit.dart';
import 'package:erp/features/inventory/logic/receipt_approval_state.dart';
import 'package:erp/features/inventory/logic/receipt_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T1-T8: Receipt Item & Session Validation Rules', () {
    test('T1: validateReceiptItem with lot tracked and empty lot code has missingLotCode', () {
      final item = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: true,
        lots: const [
          ReceiptLotDraft(
            lotCode: '',
            accepted: 10,
          ),
        ],
      );

      final result = validateReceiptItem(item);
      expect(result.isValid, isFalse);
      expect(result.lotIssues.first, contains(LotIssue.missingLotCode));
    });

    test('T2: two lots with same code l1 / L1 have duplicateLotCode on both', () {
      final item = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: true,
        lots: const [
          ReceiptLotDraft(
            lotCode: 'l1',
            accepted: 10,
          ),
          ReceiptLotDraft(
            lotCode: 'L1 ',
            accepted: 5,
          ),
        ],
      );

      final result = validateReceiptItem(item);
      expect(result.isValid, isFalse);
      expect(result.lotIssues[0], contains(LotIssue.duplicateLotCode));
      expect(result.lotIssues[1], contains(LotIssue.duplicateLotCode));
    });

    test('T3: requiresExpiry and expiry null has missingExpiry', () {
      final item = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: true,
        requiresExpiry: true,
        lots: const [
          ReceiptLotDraft(
            lotCode: 'LOT-01',
            accepted: 10,
            expiryDate: null,
          ),
        ],
      );

      final result = validateReceiptItem(item);
      expect(result.isValid, isFalse);
      expect(result.lotIssues.first, contains(LotIssue.missingExpiry));
    });

    test('T4: expiry before manufacture date has expiryNotAfterManufacture', () {
      const mfg = LotDate(year: 2026, month: 5, day: 1);
      const exp = LotDate(year: 2026, month: 4, day: 30);
      final item = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: true,
        requiresExpiry: true,
        lots: [
          ReceiptLotDraft(
            lotCode: 'LOT-01',
            accepted: 10,
            manufactureDate: mfg,
            expiryDate: exp,
          ),
        ],
      );

      final result = validateReceiptItem(item);
      expect(result.isValid, isFalse);
      expect(result.lotIssues.first, contains(LotIssue.expiryNotAfterManufacture));
    });

    test('T5: quantity -5 has negativeQuantity', () {
      final item = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [
          ReceiptLotDraft(
            accepted: -5,
          ),
        ],
      );

      final result = validateReceiptItem(item);
      expect(result.isValid, isFalse);
      expect(result.lotIssues.first, contains(LotIssue.negativeQuantity));
    });

    test('T6: canReview is false with one valid item + one empty item', () {
      final repo = GoodsReceiptRepository();
      final cubit = QuickReceiptSessionCubit(
        repository: repo,
        actorLoader: () async => const ReceiptActor(id: 'u1', name: 'User 1'),
      );

      cubit.updateHeader(
        cubit.state.header.copyWith(
          supplierId: 's1',
          supplierName: 'Sup 1',
          warehouseId: 'w1',
          documentFileNames: const ['doc.pdf'],
        ),
      );

      final validItem = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [ReceiptLotDraft(accepted: 10)],
      );

      final emptyItem = ReceiptItemDraft(
        productId: 'p2',
        productName: 'P2',
        productCode: 'SP-2',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [ReceiptLotDraft(accepted: 0)],
      );

      cubit.saveItem(validItem);
      expect(cubit.state.canReview, isTrue);

      cubit.saveItem(emptyItem);
      expect(cubit.state.canReview, isFalse);
    });

    test('T7: canReview is false when all items only have rejected quantities', () {
      final repo = GoodsReceiptRepository();
      final cubit = QuickReceiptSessionCubit(
        repository: repo,
        actorLoader: () async => const ReceiptActor(id: 'u1', name: 'User 1'),
      );

      cubit.updateHeader(
        cubit.state.header.copyWith(
          supplierId: 's1',
          supplierName: 'Sup 1',
          warehouseId: 'w1',
          documentFileNames: const ['doc.pdf'],
        ),
      );

      final rejectedItem = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [ReceiptLotDraft(rejected: 10)],
      );

      cubit.saveItem(rejectedItem);
      expect(cubit.state.items.first.totalPhysicalStock, equals(0));
      expect(cubit.state.canReview, isFalse);
    });

    test('T8: canReview is false when no document is attached', () {
      final repo = GoodsReceiptRepository();
      final cubit = QuickReceiptSessionCubit(
        repository: repo,
        actorLoader: () async => const ReceiptActor(id: 'u1', name: 'User 1'),
      );

      cubit.updateHeader(
        cubit.state.header.copyWith(
          supplierId: 's1',
          supplierName: 'Sup 1',
          warehouseId: 'w1',
          documentFileNames: const [],
        ),
      );

      final validItem = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [ReceiptLotDraft(accepted: 10)],
      );

      cubit.saveItem(validItem);
      expect(cubit.state.header.isValid, isFalse);
      expect(cubit.state.canReview, isFalse);
    });
  });

  group('T9-T15: Cubit & Repository Business Logic', () {
    test('T9: indexOf after saveItem for same Product + UOM returns original index and length unchanged', () {
      final repo = GoodsReceiptRepository();
      final cubit = QuickReceiptSessionCubit(
        repository: repo,
        actorLoader: () async => const ReceiptActor(id: 'u1', name: 'User 1'),
      );

      final item1 = ReceiptItemDraft(
        productId: 'p1',
        productName: 'P1',
        productCode: 'SP-1',
        unitId: 'u1',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [ReceiptLotDraft(accepted: 10)],
      );
      cubit.saveItem(item1);
      expect(cubit.state.items.length, equals(1));
      expect(cubit.indexOf('p1', 'u1'), equals(0));

      final item1Updated = item1.copyWith(
        lots: const [ReceiptLotDraft(accepted: 25)],
      );
      cubit.saveItem(item1Updated);
      expect(cubit.state.items.length, equals(1));
      expect(cubit.indexOf('p1', 'u1'), equals(0));
      expect(cubit.state.items.first.totalAccepted, equals(25));
    });

    test('T10: submitQuickReceipt twice on same day gives different IDs and both persist', () async {
      final repo = GoodsReceiptRepository();
      const maker = ReceiptActor(id: 'maker_1', name: 'Nguyễn Văn An');
      final header = ReceiptHeaderDraft(
        supplierId: 's1',
        supplierName: 'Sup 1',
        warehouseId: 'w1',
        receiptDate: DateTime.now(),
        documentFileNames: const ['doc.pdf'],
      );

      final doc1 = await repo.submitQuickReceipt(header, const [], maker: maker);
      final doc2 = await repo.submitQuickReceipt(header, const [], maker: maker);

      expect(doc1.id, isNot(equals(doc2.id)));
      final fetched1 = await repo.getReceiptById(doc1.id);
      final fetched2 = await repo.getReceiptById(doc2.id);
      expect(fetched1, isNotNull);
      expect(fetched2, isNotNull);
    });

    test('T11: getReceiptById for non-existent ID returns null', () async {
      final repo = GoodsReceiptRepository();
      final fetched = await repo.getReceiptById('khong-co');
      expect(fetched, isNull);
    });

    test('T12: approveReceipt with approver matching maker throws SELF_APPROVAL_NOT_ALLOWED', () async {
      final repo = GoodsReceiptRepository();
      const maker = ReceiptActor(id: 'user_a', name: 'User A');
      final header = ReceiptHeaderDraft(
        supplierId: 's1',
        supplierName: 'Sup 1',
        warehouseId: 'w1',
        receiptDate: DateTime.now(),
        documentFileNames: const ['doc.pdf'],
      );

      final doc = await repo.submitQuickReceipt(header, const [], maker: maker);

      expect(
        () => repo.approveReceipt(doc.id, approver: maker),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals('SELF_APPROVAL_NOT_ALLOWED'),
          ),
        ),
      );

      final after = await repo.getReceiptById(doc.id);
      expect(after?.status.name, equals('pendingApproval'));
    });

    test('T13: approving a receipt twice throws APPROVAL_ALREADY_DECIDED', () async {
      final repo = GoodsReceiptRepository();
      const maker = ReceiptActor(id: 'user_a', name: 'User A');
      const approver = ReceiptActor(id: 'user_b', name: 'User B');
      final header = ReceiptHeaderDraft(
        supplierId: 's1',
        supplierName: 'Sup 1',
        warehouseId: 'w1',
        receiptDate: DateTime.now(),
        documentFileNames: const ['doc.pdf'],
      );

      final doc = await repo.submitQuickReceipt(header, const [], maker: maker);
      await repo.approveReceipt(doc.id, approver: approver);

      expect(
        () => repo.approveReceipt(doc.id, approver: approver),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals('APPROVAL_ALREADY_DECIDED'),
          ),
        ),
      );
    });

    test('T14: approved quick receipt appears in ValuationRepository queue with directMissing', () async {
      final valRepo = ValuationRepository();
      final receiptRepo = GoodsReceiptRepository(valuation: valRepo);
      const maker = ReceiptActor(id: 'user_a', name: 'User A');
      const approver = ReceiptActor(id: 'user_b', name: 'User B');

      final header = ReceiptHeaderDraft(
        supplierId: 'sup_01',
        supplierName: 'Minh Dũng',
        warehouseId: 'wh_01',
        receiptDate: DateTime.now(),
        documentFileNames: const ['bb.pdf'],
      );
      final item = ReceiptItemDraft(
        productId: 'prod_01',
        productName: 'Amox 500',
        productCode: 'AMX-500',
        unitId: 'u_hop',
        unitName: 'Hộp',
        isLotTracked: true,
        lots: const [
          ReceiptLotDraft(lotCode: 'L1', accepted: 50),
        ],
      );

      final doc = await receiptRepo.submitQuickReceipt(header, [item], maker: maker);
      await receiptRepo.approveReceipt(doc.id, approver: approver);

      final queue = await valRepo.getQueue();
      final valItem = queue.firstWhere((r) => r.id == doc.id);
      expect(valItem.receiptNumber, equals(doc.id));
      expect(valItem.status, equals(ValuationWorkItemStatus.missing));

      final receiptVal = await valRepo.getReceiptValuation(doc.id);
      expect(receiptVal.groups.first.status, equals(ValuationGroupStatus.directMissing));
    });

    test('T15: confirmValuation on same ValuationRepository instance removes receipt from pending queue', () async {
      final valRepo = ValuationRepository();
      final receiptRepo = GoodsReceiptRepository(valuation: valRepo);
      const maker = ReceiptActor(id: 'user_a', name: 'User A');
      const approver = ReceiptActor(id: 'user_b', name: 'User B');

      final header = ReceiptHeaderDraft(
        supplierId: 'sup_01',
        supplierName: 'Minh Dũng',
        warehouseId: 'wh_01',
        receiptDate: DateTime.now(),
        documentFileNames: const ['bb.pdf'],
      );
      final item = ReceiptItemDraft(
        productId: 'prod_01',
        productName: 'Amox 500',
        productCode: 'AMX-500',
        unitId: 'u_hop',
        unitName: 'Hộp',
        isLotTracked: false,
        lots: const [ReceiptLotDraft(accepted: 50)],
      );

      final doc = await receiptRepo.submitQuickReceipt(header, [item], maker: maker);
      await receiptRepo.approveReceipt(doc.id, approver: approver);

      final rData = await valRepo.getReceiptValuation(doc.id);
      final groupId = rData.groups.first.id;

      await valRepo.confirmValuation(
        receiptId: doc.id,
        selectedGroupIds: [groupId],
      );

      final queueAfter = await valRepo.getQueue();
      expect(queueAfter.any((r) => r.id == doc.id), isFalse);
    });
  });

  group('B3-B7: ngày theo bao bì, lô trùng, hiển thị', () {
    ReceiptItemDraft amox(List<ReceiptLotDraft> lots) => ReceiptItemDraft(
          productId: 'prod_01',
          productName: 'Amox 500',
          productCode: 'AMX-500',
          unitId: 'u_hop',
          unitName: 'Hộp',
          isLotTracked: true,
          requiresExpiry: true,
          lots: lots,
          knownLotExpiry: const {'L2407-A': LotDate(year: 2028, month: 7)},
        );

    test('B3: isConsistentWith so khớp ở các phần cùng có', () {
      const month = LotDate(year: 2028, month: 7);
      expect(month.isConsistentWith(const LotDate(year: 2028, month: 7, day: 15)), isTrue);
      expect(month.isConsistentWith(const LotDate(year: 2028, month: 8)), isFalse);
      expect(const LotDate(year: 2028).isConsistentWith(month), isTrue);
    });

    test('B4: lô đã có với hạn dùng khác → lotConflict', () {
      final conflict = validateReceiptItem(amox(const [
        ReceiptLotDraft(
          lotCode: 'l2407-a',
          accepted: 5,
          expiryDate: LotDate(year: 2028, month: 8),
        ),
      ]));
      expect(conflict.lotIssues.first, contains(LotIssue.lotConflict));

      for (final ok in const [
        LotDate(year: 2028, month: 7),
        LotDate(year: 2028, month: 7, day: 15),
      ]) {
        final result = validateReceiptItem(amox([
          ReceiptLotDraft(lotCode: 'l2407-a', accepted: 5, expiryDate: ok),
        ]));
        expect(result.isValid, isTrue);
      }
    });

    test('B5: classificationText', () {
      final item = amox(const [
        ReceiptLotDraft(lotCode: 'A', accepted: 70, quarantine: 1),
        ReceiptLotDraft(lotCode: 'B', accepted: 50, quarantine: 1),
      ]);
      expect(classificationText(item), '2 lô · 120 đạt · 2 cách ly');
      expect(classificationText(amox(const [ReceiptLotDraft()])), 'Chưa ghi nhận');
    });

    test('B6: formatQuantity không làm tròn số lẻ', () {
      expect(formatQuantity(106), '106');
      expect(formatQuantity(1.5), '1,5');
      expect(formatQuantity(0.25), '0,25');
    });

    test('B7: duyệt phiếu đã xử lý → tải lại, không có actionError', () async {
      final repo = GoodsReceiptRepository();
      const approver = ReceiptActor(id: 'other', name: 'Trưởng Kho');
      final first = ReceiptApprovalCubit(
        repository: repo,
        actorLoader: () async => approver,
      );
      final second = ReceiptApprovalCubit(
        repository: repo,
        actorLoader: () async => approver,
      );
      await first.load('REC-240715-01');
      await second.load('REC-240715-01');
      await first.approve();
      await second.approve();

      final state = second.state;
      expect(state, isA<ReceiptApprovalLoaded>());
      state as ReceiptApprovalLoaded;
      expect(state.isDecided, isTrue);
      expect(state.actionError, isNull);
    });
  });
}
