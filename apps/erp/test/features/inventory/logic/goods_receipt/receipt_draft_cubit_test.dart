import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_state.dart';

class _FakeReceiptRepository extends Fake implements GoodsReceiptRepository {
  late ReceiptFormOptions options;
  RecordReceiptResult? nextRecordResult;
  Object? nextRecordError;
  String? lastRecordKey;
  Map<String, dynamic>? lastRecordPayload;
  int recordCallCount = 0;

  @override
  Future<ReceiptFormOptions> formOptions() async => options;

  @override
  Future<RecordReceiptResult> record({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    recordCallCount++;
    lastRecordKey = idempotencyKey;
    lastRecordPayload = payload;
    if (nextRecordError != null) {
      throw nextRecordError!;
    }
    return nextRecordResult!;
  }
}

class _FakeProgramRepository extends Fake implements SupplierProgramRepository {
  int hintCallCount = 0;
  List<({String productId, num paidQty, int unitPrice})>? lastInputs;
  List<ProgramHint?> nextHints = [];
  int getCallCount = 0;
  num? nextRebatePercent;
  Object? getError;

  @override
  Future<ProgramDetail> get(String id) async {
    getCallCount++;
    if (getError != null) throw getError!;
    return ProgramDetail(
      row: ProgramRow(
        id: id,
        name: 'A - Nobivac mốc 100',
        supplierId: 's-1',
        supplierName: 'Công ty Á Châu',
        kind: ProgramKind.volumeRebate,
        status: ProgramStatus.active,
        startedOn: DateTime(2026, 11, 16),
        productIds: const ['p-1'],
        productCount: 1,
        tiers: const [],
        targetQty: 100,
        rebatePercent: nextRebatePercent,
        progressQty: 0,
      ),
      revision: 1,
      isLocked: false,
      products: const [],
      receipts: const [],
      baseAmountVnd: 0,
    );
  }

  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async {
    hintCallCount++;
    lastInputs = lines;
    return nextHints;
  }
}

void main() {
  late _FakeReceiptRepository receiptRepo;
  late _FakeProgramRepository programRepo;

  const supplierA = ReceiptSupplierOption(id: 's-1', name: 'Công ty Á Châu', code: 'AC', isSystem: false);
  const supplierWalkIn = ReceiptSupplierOption(id: 's-walkin', name: 'Nhà cung cấp vãng lai', code: null, isSystem: true);

  const product1 = ReceiptProductOption(
    id: 'p-1',
    name: 'Nobivac DHPPi',
    code: 'NOB-1',
    barcode: null,
    baseUom: 'hộp',
    isLotTracked: true,
    expiryRequired: true,
    units: [ReceiptUnitOption(id: 'u-1', name: 'hộp', rate: 1, isBase: true)],
  );

  setUp(() {
    receiptRepo = _FakeReceiptRepository();
    receiptRepo.options = const ReceiptFormOptions(
      warehouseName: 'Kho chính',
      today: '2026-11-10',
      suppliers: [supplierA, supplierWalkIn],
      products: [product1],
      lots: [],
    );
    programRepo = _FakeProgramRepository();
  });

  group('ReceiptDraftCubit rebatePercent', () {
    const rebateHint = ProgramHint(
      programId: 'prog-1',
      programName: 'A - Nobivac mốc 100',
      kind: ProgramKind.volumeRebate,
      rebate: (progress: 0, target: 100, wouldReach: false),
    );
    const tierHint = ProgramHint(
      programId: 'prog-2',
      programName: 'Bậc SL',
      kind: ProgramKind.tierDiscount,
      tier: (minQty: 50, percent: 3, discountVnd: 100),
    );

    Future<(ReceiptDraftCubit, String)> setUpLine() async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );
      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-1', 'u-1');
      return (cubit, lineKey);
    }

    test('cubit_sets_percent', () async {
      programRepo.nextRebatePercent = 5;
      programRepo.nextHints = [rebateHint];
      final (cubit, _) = await setUpLine();

      await cubit.refreshAllHints();

      expect(programRepo.getCallCount, 1);
      expect(cubit.state.draft.lines.first.rebatePercent, 5);
    });

    test('cubit_caches_percent', () async {
      programRepo.nextRebatePercent = 5;
      programRepo.nextHints = [rebateHint];
      final (cubit, _) = await setUpLine();

      await cubit.refreshAllHints();
      await cubit.refreshAllHints();

      expect(programRepo.getCallCount, 1);
      expect(cubit.state.draft.lines.first.rebatePercent, 5);
    });

    test('cubit_skips_non_rebate', () async {
      programRepo.nextHints = [tierHint];
      final (cubit, _) = await setUpLine();

      await cubit.refreshAllHints();

      expect(programRepo.getCallCount, 0);
      expect(cubit.state.draft.lines.first.rebatePercent, isNull);
    });

    test('cubit_percent_failure_ignored', () async {
      programRepo.getError = Exception('rpc down');
      programRepo.nextHints = [rebateHint];
      final (cubit, _) = await setUpLine();

      await cubit.refreshAllHints();

      expect(cubit.state.hintsLoading, isFalse);
      expect(cubit.state.draft.lines.first.rebatePercent, isNull);
      expect(cubit.state.draft.lines.first.hint, isNotNull);
    });

    test('cubit_clears_percent_when_hint_gone', () async {
      programRepo.nextRebatePercent = 5;
      programRepo.nextHints = [rebateHint];
      final (cubit, _) = await setUpLine();
      await cubit.refreshAllHints();
      expect(cubit.state.draft.lines.first.rebatePercent, 5);

      programRepo.nextHints = [null];
      await cubit.refreshAllHints();

      expect(cubit.state.draft.lines.first.rebatePercent, isNull);
    });
  });

  group('ReceiptDraftCubit', () {
    test('load_options_and_initial_product', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        initialProductId: 'p-1',
      );

      expect(cubit.state.status, ReceiptDraftStatus.loading);
      await cubit.load();

      expect(cubit.state.status, ReceiptDraftStatus.ready);
      expect(cubit.state.options?.products.length, 1);

      cubit.selectSupplier(supplierA);
      final addedKey = cubit.addInitialProductLine();
      expect(addedKey, isNotNull);
      expect(cubit.state.draft.lines.length, 1);
      expect(cubit.state.draft.lines.first.product.id, 'p-1');
    });

    testWidgets('hints_debounced_per_line', (tester) async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        hintDebounce: const Duration(milliseconds: 400),
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-1', 'u-1');

      // Sửa số lượng 3 lần liên tiếp trong vòng 400ms
      cubit.updateLine(lineKey, (l) => l.copyWith(lots: [l.lots.first.copyWith(quantity: 10)]));
      await tester.pump(const Duration(milliseconds: 100));

      cubit.updateLine(lineKey, (l) => l.copyWith(lots: [l.lots.first.copyWith(quantity: 20)]));
      await tester.pump(const Duration(milliseconds: 100));

      cubit.updateLine(lineKey, (l) => l.copyWith(lots: [l.lots.first.copyWith(quantity: 30)]));
      expect(programRepo.hintCallCount, 0);

      await tester.pump(const Duration(milliseconds: 400));
      expect(programRepo.hintCallCount, 1);
      expect(programRepo.lastInputs?.first.paidQty, 30);
    });

    testWidgets('walk_in_skips_hints', (tester) async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierWalkIn);
      final lineKey = cubit.addLine('p-1', 'u-1');

      cubit.updateLine(lineKey, (l) => l.copyWith(lots: [l.lots.first.copyWith(quantity: 10)]));
      await tester.pump(const Duration(milliseconds: 500));

      expect(programRepo.hintCallCount, 0);
    });

    test('change_supplier_clears_offers', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-1', 'u-1');

      cubit.updateLine(
        lineKey,
        (l) => l.copyWith(
          programId: 'prog-1',
          tierPercent: 5.0,
          freeQty: 2,
        ),
      );

      expect(cubit.state.draft.lines.first.programId, 'prog-1');

      // Đổi NCC -> xóa toàn bộ ưu đãi
      cubit.selectSupplier(supplierWalkIn);
      final line = cubit.state.draft.lines.first;
      expect(line.programId, isNull);
      expect(line.tierPercent, isNull);
      expect(line.hint, isNull);
    });

    test('any_edit_clears_idempotency_key', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      cubit.setIdempotencyKeyForTesting('test-idem-key');
      expect(cubit.state.idempotencyKey, 'test-idem-key');

      cubit.setDocNo('HD 001');
      expect(cubit.state.idempotencyKey, isNull);
    });

    test('duplicate_product_unit_rejected', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);

      final k1 = cubit.addLine('p-1', 'u-1');
      final k2 = cubit.addLine('p-1', 'u-1');

      expect(k1, k2);
      expect(cubit.state.draft.lines.length, 1);
    });

    test('submit_success_sets_result', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      cubit.addLine('p-1', 'u-1');

      receiptRepo.nextRecordResult = const RecordReceiptResult(
        receiptId: 'rc-1',
        receiptNo: 'PN-261110-01',
        supplierName: 'Á Châu',
        businessDate: '2026-11-10',
        lineCount: 1,
        lotCount: 1,
        landedTotalVnd: 1000000,
        createdByName: 'Chủ kho',
        stockChanges: [],
        reachedPrograms: [],
      );

      await cubit.submit();

      expect(cubit.state.submit, ReceiptSubmitStatus.idle);
      expect(cubit.state.result?.receiptNo, 'PN-261110-01');
      expect(receiptRepo.recordCallCount, 1);
      expect(receiptRepo.lastRecordKey, isNotNull);
    });

    test('program_changed_reloads_hints', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      cubit.addLine('p-1', 'u-1');

      receiptRepo.nextRecordError =
          const AppException('RECEIPT_PROGRAM_CHANGED');

      await cubit.submit();

      expect(cubit.state.submit, ReceiptSubmitStatus.failed);
      expect(programRepo.hintCallCount, greaterThan(0));
      expect(cubit.state.idempotencyKey, isNull);
    });

    test('retry_reuses_key', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      cubit.addLine('p-1', 'u-1');

      receiptRepo.nextRecordError = const AppException('NETWORK_ERROR');

      await cubit.submit();

      expect(cubit.state.submit, ReceiptSubmitStatus.failed);
      expect(cubit.state.submitNetworkError, isTrue);
      final firstKey = receiptRepo.lastRecordKey;
      expect(firstKey, isNotNull);

      // Thử lại lần 2
      receiptRepo.nextRecordError = null;
      receiptRepo.nextRecordResult = const RecordReceiptResult(
        receiptId: 'rc-1',
        receiptNo: 'PN-261110-01',
        supplierName: 'Á Châu',
        businessDate: '2026-11-10',
        lineCount: 1,
        lotCount: 1,
        landedTotalVnd: 1000000,
        createdByName: 'Chủ kho',
        stockChanges: [],
        reachedPrograms: [],
      );

      await cubit.submit();

      expect(cubit.state.submit, ReceiptSubmitStatus.idle);
      expect(cubit.state.result, isNotNull);
      expect(receiptRepo.lastRecordKey, firstKey);
    });

    test('review_open_refreshes_hints_and_flags_change', () async {
      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
      );

      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-1', 'u-1');

      cubit.updateLine(
        lineKey,
        (l) => l.copyWith(
          hint: const ProgramHint(
            programId: 'p1',
            programName: 'Ưu đãi cũ',
            kind: ProgramKind.tierDiscount,
          ),
        ),
      );

      programRepo.nextHints = [
        const ProgramHint(
          programId: 'p2',
          programName: 'Ưu đãi mới',
          kind: ProgramKind.tierDiscount,
        ),
      ];

      await cubit.prepareReview();

      final line = cubit.state.draft.lines.first;
      expect(line.hintAtEntry?.programId, 'p1');
      expect(line.hint?.programId, 'p2');
    });
  });
}
