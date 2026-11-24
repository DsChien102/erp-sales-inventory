import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_record_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_record_state.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubInventoryRpc implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> mutate({
    required String scope,
    required String idempotencyKey,
    required String fn,
    required Map<String, dynamic> params,
  }) async =>
      const {};

  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      const {};
}

class _FakeProgramRepository extends SupplierProgramRepository {
  _FakeProgramRepository() : super(rpc: _StubInventoryRpc());

  late ProgramDetail nextDetail;

  @override
  Future<ProgramDetail> get(String id) async => nextDetail;
}

class _FakeRebateRepository extends SupplierRebateRepository {
  _FakeRebateRepository() : super(rpc: _StubInventoryRpc());

  final List<int?> previewCalls = [];
  final List<({String idempotencyKey, int amountVnd, String? overrideReason})>
      recordCalls = [];

  RebatePreview Function(int? amountVnd)? onPreview;
  Future<RebateRecordResult> Function()? onRecord;

  @override
  Future<RebatePreview> preview({
    required String programId,
    int? amountVnd,
  }) async {
    previewCalls.add(amountVnd);
    if (onPreview != null) {
      return onPreview!(amountVnd);
    }
    final amount = amountVnd ?? 5000000;
    return RebatePreview(
      programId: programId,
      programName: 'Mốc 1.000 hộp Q4',
      supplierName: 'NCC A',
      targetQty: 1000,
      progressQty: 1000,
      rebatePercent: 5,
      uom: 'hộp',
      baseAmountVnd: 100000000,
      proposedAmountVnd: 5000000,
      amountVnd: amount,
      allocations: const [
        RebateAllocation(
          productId: 'p1',
          name: 'Nobivac DHPPi',
          uom: 'hộp',
          paidQty: 1000,
          purchaseAmountVnd: 100000000,
          rebatePartVnd: 5000000,
          onHandQty: 300,
          inventoryPartVnd: 1500000,
          cogsPartVnd: 3500000,
          avgCostBefore: 100000,
          avgCostAfter: 95000,
        ),
      ],
      inventoryPartTotal: 1500000,
      cogsPartTotal: 3500000,
    );
  }

  @override
  Future<RebateRecordResult> record({
    required String idempotencyKey,
    required String programId,
    required String documentNo,
    required DateTime documentDate,
    required int amountVnd,
    String? overrideReason,
  }) async {
    recordCalls.add((
      idempotencyKey: idempotencyKey,
      amountVnd: amountVnd,
      overrideReason: overrideReason,
    ));
    if (onRecord != null) {
      return onRecord!();
    }
    return RebateRecordResult(
      rebateId: 'reb-14',
      programId: programId,
      programName: 'Mốc 1.000 hộp Q4',
      supplierName: 'NCC A',
      targetQty: 1000,
      progressQty: 1000,
      rebatePercent: 5,
      uom: 'hộp',
      baseAmountVnd: 100000000,
      proposedAmountVnd: 5000000,
      amountVnd: amountVnd,
      allocations: const [],
      inventoryPartTotal: 1500000,
      cogsPartTotal: 3500000,
    );
  }
}

ProgramDetail _makeDetail({
  ProgramStatus status = ProgramStatus.reached,
  bool viewerIsOwner = true,
}) {
  return ProgramDetail(
    row: ProgramRow(
      id: 'prog-14',
      name: 'Mốc 1.000 hộp Q4',
      supplierId: 'sup-a',
      supplierName: 'NCC A',
      kind: ProgramKind.volumeRebate,
      status: status,
      startedOn: DateTime(2026, 11, 1),
      productIds: const ['p1'],
      productCount: 1,
      commonUom: 'hộp',
      tiers: const [],
      targetQty: 1000,
      rebatePercent: 5,
      progressQty: 1000,
    ),
    revision: 1,
    isLocked: true,
    products: const [
      ProgramProduct(
        productId: 'p1',
        name: 'Nobivac DHPPi',
        code: 'NB-1',
        baseUom: 'hộp',
      ),
    ],
    receipts: const [],
    baseAmountVnd: 100000000,
    viewerIsOwner: viewerIsOwner,
  );
}

void main() {
  group('RebateRecordCubit', () {
    late _FakeProgramRepository programs;
    late _FakeRebateRepository rebates;
    late int keySeq;

    setUp(() {
      programs = _FakeProgramRepository()..nextDetail = _makeDetail();
      rebates = _FakeRebateRepository();
      keySeq = 0;
    });

    RebateRecordCubit buildCubit() => RebateRecordCubit(
          rebates: rebates,
          programs: programs,
          programId: 'prog-14',
          newKey: () => 'key-${++keySeq}',
          now: () => DateTime(2026, 11, 12),
        );

    test('load_owner_reached_previews', () async {
      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.status, RebateRecordStatus.ready);
      expect(cubit.state.amountText, '5.000.000');
      expect(cubit.state.preview?.proposedAmountVnd, 5000000);
      expect(rebates.previewCalls, [null]);
      await cubit.close();
    });

    test('load_staff_not_owner', () async {
      programs.nextDetail = _makeDetail(viewerIsOwner: false);
      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.status, RebateRecordStatus.notOwner);
      expect(rebates.previewCalls, isEmpty);
      await cubit.close();
    });

    test('load_active_not_reached', () async {
      programs.nextDetail = _makeDetail(status: ProgramStatus.active);
      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.status, RebateRecordStatus.notReached);
      expect(rebates.previewCalls, isEmpty);
      await cubit.close();
    });

    test('amount_change_debounced', () {
      fakeAsync((async) {
        final cubit = buildCubit();
        cubit.load();
        async.flushMicrotasks();
        rebates.previewCalls.clear();

        cubit.setAmountText('4000000');
        async.elapse(const Duration(milliseconds: 100));
        cubit.setAmountText('4200000');
        async.elapse(const Duration(milliseconds: 100));
        cubit.setAmountText('4500000');
        async.elapse(const Duration(milliseconds: 100));
        expect(rebates.previewCalls, isEmpty);

        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
        expect(rebates.previewCalls, [4500000]);

        // Invalid input does not call preview; sets errors['amount'] on submit
        rebates.previewCalls.clear();
        cubit.setAmountText('0');
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();
        expect(rebates.previewCalls, isEmpty);

        cubit.submit();
        async.flushMicrotasks();
        expect(cubit.state.showErrors, isTrue);
        expect(cubit.state.errors['amount'], isNotNull);

        cubit.close();
      });
    });

    test('payload_drops_reason_when_equal', () {
      fakeAsync((async) {
        final cubit = buildCubit();
        cubit.load();
        async.flushMicrotasks();

        cubit.setDocumentNo('CK-2026-11');
        cubit.setAmountText('4000000');
        cubit.setReason('Thương lượng lại');
        async.elapse(const Duration(milliseconds: 450));
        async.flushMicrotasks();

        // Reset back to proposed amount
        cubit.setAmountText('5.000.000');
        async.elapse(const Duration(milliseconds: 450));
        async.flushMicrotasks();

        cubit.submit();
        async.flushMicrotasks();
        expect(cubit.state.confirming, isTrue);

        cubit.confirm();
        async.flushMicrotasks();

        expect(rebates.recordCalls.single.amountVnd, 5000000);
        expect(rebates.recordCalls.single.overrideReason, isNull);
        cubit.close();
      });
    });

    test('submit_shows_all_errors', () async {
      final cubit = buildCubit();
      await cubit.load();

      await cubit.submit();

      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.confirming, isFalse);
      expect(cubit.state.errors['documentNo'], 'Nhập số chứng từ');
      expect(rebates.recordCalls, isEmpty);
      await cubit.close();
    });

    test('confirm_success_recorded', () async {
      final cubit = buildCubit();
      await cubit.load();
      cubit.setDocumentNo('CK-2026-14');

      await cubit.submit();
      expect(cubit.state.confirming, isTrue);

      await cubit.confirm();
      expect(cubit.state.status, RebateRecordStatus.recorded);
      expect(cubit.state.result?.rebateId, 'reb-14');
      await cubit.close();
    });

    test('confirm_not_reached_stale', () async {
      rebates.onRecord = () async {
        throw const AppException(InventoryErrorCode.programNotReached);
      };
      final cubit = buildCubit();
      await cubit.load();
      cubit.setDocumentNo('CK-2026-14');

      await cubit.confirm();
      expect(cubit.state.status, RebateRecordStatus.stale);
      await cubit.close();
    });

    test('confirm_period_closed_keeps_form', () async {
      rebates.onRecord = () async {
        throw const AppException(InventoryErrorCode.periodClosed);
      };
      final cubit = buildCubit();
      await cubit.load();
      cubit.setDocumentNo('CK-2026-14');

      await cubit.confirm();
      expect(cubit.state.status, RebateRecordStatus.ready);
      expect(cubit.state.errorCode, InventoryErrorCode.periodClosed);
      expect(cubit.state.documentNo, 'CK-2026-14');
      expect(cubit.state.amountText, '5.000.000');
      await cubit.close();
    });

    test('retry_keeps_idempotency_key', () async {
      var attempts = 0;
      rebates.onRecord = () async {
        attempts++;
        if (attempts == 1) {
          throw const AppException(AppErrorCode.network);
        }
        return RebateRecordResult(
          rebateId: 'reb-14',
          programId: 'prog-14',
          programName: 'Mốc 1.000 hộp Q4',
          supplierName: 'NCC A',
          targetQty: 1000,
          progressQty: 1000,
          rebatePercent: 5,
          uom: 'hộp',
          baseAmountVnd: 100000000,
          proposedAmountVnd: 5000000,
          amountVnd: 5000000,
          allocations: const [],
          inventoryPartTotal: 1500000,
          cogsPartTotal: 3500000,
        );
      };

      final cubit = buildCubit();
      await cubit.load();
      cubit.setDocumentNo('CK-2026-14');

      await cubit.confirm();
      expect(cubit.state.status, RebateRecordStatus.ready);
      expect(cubit.state.errorCode, AppErrorCode.network);

      await cubit.confirm();
      expect(cubit.state.status, RebateRecordStatus.recorded);
      expect(rebates.recordCalls.length, 2);
      expect(
        rebates.recordCalls[0].idempotencyKey,
        rebates.recordCalls[1].idempotencyKey,
      );
      await cubit.close();
    });

    test('submit_waits_fresh_preview', () async {
      final cubit = buildCubit();
      await cubit.load();
      rebates.previewCalls.clear();

      cubit.setDocumentNo('CK-2026-14');
      cubit.setAmountText('6.000.000');
      cubit.setReason('Thoả thuận bổ sung');

      // Submit immediately before 400ms debounce fires
      await cubit.submit();

      expect(rebates.previewCalls, [6000000]);
      expect(cubit.state.preview?.amountVnd, 6000000);
      expect(cubit.state.confirming, isTrue);
      await cubit.close();
    });
  });
}
