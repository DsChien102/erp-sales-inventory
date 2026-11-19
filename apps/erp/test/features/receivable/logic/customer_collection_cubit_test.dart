import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/idempotency_key_factory.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/logic/customer_collection_cubit.dart';
import 'package:erp/features/receivable/logic/customer_collection_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;

class _Keys implements IdempotencyKeyFactory {
  int n = 0;

  @override
  String next(String intent) => 'k${++n}';
}

void main() {
  late FakeReceivableRepository repo;
  late CustomerCollectionCubit cubit;

  setUp(() {
    repo = FakeReceivableRepository();
    cubit = CustomerCollectionCubit(
      repository: repo,
      customerId: fx.tuanId,
      orders: fx.tuanOrders,
      keyFactory: _Keys(),
    );
  });

  tearDown(() => cubit.close());

  test('khởi tạo: không tick, số 0, chưa gửi được', () {
    expect(cubit.state.selectedIds, isEmpty);
    expect(cubit.state.amountMinor, 0);
    expect(cubit.state.preview.canSubmit, isFalse);
    expect(cubit.state.isDirty, isFalse);
  });

  test('toggle resets amount to scope total', () {
    cubit.toggleOrder('so-001');
    cubit.setAmountText('5.000.000');
    expect(cubit.state.amountMinor, 5000000);
    cubit.toggleOrder('so-003');
    expect(cubit.state.amountMinor, 10000000);
  });

  test('toggleAll chọn hết rồi bỏ hết', () {
    cubit.toggleAll();
    expect(cubit.state.selectedIds, {'so-001', 'so-002', 'so-003'});
    expect(cubit.state.amountMinor, 18000000);
    cubit.toggleAll();
    expect(cubit.state.selectedIds, isEmpty);
    expect(cubit.state.amountMinor, 0);
  });

  test('untick all locks submit', () {
    cubit.toggleOrder('so-002');
    cubit.toggleOrder('so-002');
    expect(cubit.state.amountMinor, 0);
    expect(cubit.state.preview.canSubmit, isFalse);
  });

  test('setAmountText bỏ ký tự không phải số', () {
    cubit.toggleAll();
    cubit.setAmountText('10.000.000đ');
    expect(cubit.state.amountMinor, 10000000);
    cubit.setAmountText('abc');
    expect(cubit.state.amountMinor, 0);
  });

  test('vượt tổng đơn đã chọn: openConfirm không đổi bước', () {
    cubit.toggleOrder('so-002');
    cubit.setAmountText('8000001');
    expect(cubit.state.preview.over, isTrue);
    cubit.openConfirm();
    expect(cubit.state.step, CollectionStep.form);
  });

  test('openConfirm / backToForm khi hợp lệ', () {
    cubit.toggleAll();
    cubit.openConfirm();
    expect(cubit.state.step, CollectionStep.confirm);
    cubit.backToForm();
    expect(cubit.state.step, CollectionStep.form);
  });

  test('submit thành công gửi đúng request', () async {
    cubit.toggleOrder('so-003');
    cubit.toggleOrder('so-001');
    cubit.toggleOrder('so-002');
    cubit.setAmountText('10.000.000');
    await cubit.submit();
    final r = repo.collectionCalls.single;
    expect(r.orderIds, ['so-001', 'so-002', 'so-003']);
    expect(r.expectedOutstandingMinor, 18000000);
    expect(r.amountMinor, 10000000);
    expect(r.method, CollectionMethod.cash);
    expect(r.externalReference, isNull);
    expect(r.idempotencyKey, 'k1');
    expect(cubit.state.phase, CollectionPhase.success);
    expect(cubit.state.result?.outstandingAfterMinor, 8000000);
  });

  test('chuyển khoản gửi mã giao dịch đã trim, quay về tiền mặt thì null', () async {
    cubit.toggleAll();
    cubit.setMethod(CollectionMethod.manualBankTransfer);
    cubit.setReference(' FT2611180001 ');
    await cubit.submit();
    expect(repo.collectionCalls.last.externalReference, 'FT2611180001');
    expect(repo.collectionCalls.last.method, CollectionMethod.manualBankTransfer);
    cubit.setMethod(CollectionMethod.cash);
    await cubit.submit();
    expect(repo.collectionCalls.last.externalReference, isNull);
  });

  test('retry keeps idempotency key', () async {
    cubit.toggleAll();
    repo.enqueueRecord(const AppException(AppErrorCode.network));
    await cubit.submit();
    expect(cubit.state.phase, CollectionPhase.error);
    expect(cubit.state.errorMessage, 'Không ghi nhận được. Thử lại?');
    await cubit.submit();
    expect(repo.collectionCalls.map((c) => c.idempotencyKey), ['k1', 'k1']);
  });

  test('edit after error makes new key', () async {
    cubit.toggleAll();
    repo.enqueueRecord(const AppException(AppErrorCode.network));
    await cubit.submit();
    cubit.setAmountText('9.000.000');
    expect(cubit.state.phase, CollectionPhase.idle);
    await cubit.submit();
    expect(repo.collectionCalls.map((c) => c.idempotencyKey), ['k1', 'k2']);
  });

  test('RECEIVABLE_CHANGED → changed', () async {
    cubit.toggleAll();
    repo.enqueueRecord(const AppException('RECEIVABLE_CHANGED'));
    await cubit.submit();
    expect(cubit.state.phase, CollectionPhase.changed);
  });

  test('OVERPAYMENT_NOT_ALLOWED → thông điệp 6.3', () async {
    cubit.toggleAll();
    repo.enqueueRecord(const AppException('OVERPAYMENT_NOT_ALLOWED'));
    await cubit.submit();
    expect(cubit.state.phase, CollectionPhase.error);
    expect(cubit.state.errorMessage, 'Số tiền vượt quá tổng còn nợ của khách.');
  });

  test('đang submitting: submit lần 2 không gọi thêm', () async {
    cubit.toggleAll();
    final hold = Completer<CustomerCollectionResult>();
    repo.enqueueRecord(hold);
    final first = cubit.submit();
    await cubit.submit();
    expect(repo.collectionCalls, hasLength(1));
    expect(cubit.state.phase, CollectionPhase.submitting);
    hold.complete(const CustomerCollectionResult(collectionId: 'c', outstandingAfterMinor: 0));
    await first;
    expect(cubit.state.phase, CollectionPhase.success);
  });
}
