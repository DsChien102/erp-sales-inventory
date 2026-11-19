import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/logic/customer_receivable_cubit.dart';
import 'package:erp/features/receivable/logic/customer_receivable_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;

void main() {
  late FakeReceivableRepository repo;
  late CustomerReceivableCubit cubit;

  setUp(() {
    repo = FakeReceivableRepository();
    cubit = CustomerReceivableCubit(repository: repo, customerId: fx.tuanId);
  });

  tearDown(() => cubit.close());

  test('load gọi chi tiết và lịch sử song song', () async {
    final detail = Completer<CustomerReceivableDetail>();
    final history = Completer<ReceivableHistoryPage>();
    repo
      ..enqueueCustomer(detail)
      ..enqueueHistory(history);
    final done = cubit.load();
    await pumpEventQueue();
    expect(repo.customerCalls, [fx.tuanId]);
    expect(repo.historyCalls, hasLength(1));
    detail.complete(fx.tuanDetail);
    history.complete(ReceivableHistoryPage(items: fx.tuanHistoryBefore, nextCursor: null));
    await done;
    expect(cubit.state.detailStatus, LoadStatus.ready);
    expect(cubit.state.historyStatus, LoadStatus.ready);
    expect(cubit.state.history, fx.tuanHistoryBefore);
  });

  test('lịch sử lỗi, chi tiết được → lỗi độc lập', () async {
    repo.enqueueHistory(const AppException(AppErrorCode.network));
    await cubit.load();
    expect(cubit.state.detailStatus, LoadStatus.ready);
    expect(cubit.state.historyStatus, LoadStatus.error);
  });

  test('chi tiết lỗi → detailStatus error', () async {
    repo.enqueueCustomer(const AppException(AppErrorCode.network));
    await cubit.load();
    expect(cubit.state.detailStatus, LoadStatus.error);
  });

  test('retryHistory chỉ gọi history', () async {
    repo.enqueueHistory(const AppException(AppErrorCode.network));
    await cubit.load();
    await cubit.retryHistory();
    expect(repo.customerCalls, hasLength(1));
    expect(repo.historyCalls, hasLength(2));
    expect(cubit.state.historyStatus, LoadStatus.ready);
  });

  test('loadMoreHistory nối và gửi cursor', () async {
    repo.enqueueHistory(ReceivableHistoryPage(items: fx.tuanHistoryBefore, nextCursor: 'h1'));
    await cubit.load();
    expect(cubit.state.historyCursor, 'h1');
    await cubit.loadMoreHistory();
    expect(repo.historyCalls.last.cursor, 'h1');
    expect(cubit.state.history, hasLength(2));
    expect(cubit.state.historyCursor, isNull);
  });

  test('reload gọi lại cả hai và xoá lịch sử cũ', () async {
    await cubit.load();
    repo.enqueueHistory(const ReceivableHistoryPage(items: [], nextCursor: null));
    await cubit.reload();
    expect(repo.customerCalls, hasLength(2));
    expect(repo.historyCalls, hasLength(2));
    expect(cubit.state.history, isEmpty);
  });
}
