import 'dart:async';
import 'package:fake_async/fake_async.dart';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/logic/receivable_list_cubit.dart';
import 'package:erp/features/receivable/logic/receivable_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_receivable_repository.dart';
import '../support/receivable_fixtures.dart' as fx;

CustomerReceivablePage _page(List<CustomerReceivableRow> items, {String? cursor}) =>
    CustomerReceivablePage(summary: fx.summaryBefore, items: items, nextCursor: cursor);

void main() {
  late FakeReceivableRepository repo;
  late ReceivableListCubit cubit;

  setUp(() {
    repo = FakeReceivableRepository();
    cubit = ReceivableListCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  test('load: khởi đầu loading rồi ready đúng thứ tự server', () async {
    expect(cubit.state.status, ReceivableListStatus.loading);
    await cubit.load();
    expect(cubit.state.status, ReceivableListStatus.ready);
    expect(cubit.state.summary, fx.summaryBefore);
    expect([for (final r in cubit.state.items) r.displayName], [
      'Anh Tuấn',
      'Trại Hưng Phát',
      'Chị Lan',
    ]);
  });

  test('toggleOverdue gọi filter overdue rồi quay về all', () async {
    await cubit.load();
    cubit.toggleOverdue();
    await pumpEventQueue();
    expect(repo.listCalls.last.filter, ReceivableFilter.overdue);
    expect(cubit.state.filter, ReceivableFilter.overdue);
    cubit.toggleOverdue();
    await pumpEventQueue();
    expect(repo.listCalls.last.filter, ReceivableFilter.all);
  });

  test('debounces search: 3 lần gõ chỉ gọi RPC một lần', () {
    fakeAsync((async) {
      final c = ReceivableListCubit(repository: repo);
      c.setQuery('t');
      async.elapse(const Duration(milliseconds: 100));
      c.setQuery('tu');
      async.elapse(const Duration(milliseconds: 100));
      c.setQuery('tuan');
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(repo.listCalls, hasLength(1));
      expect(repo.listCalls.single.search, 'tuan');
      c.close();
    });
  });

  test('drops stale response: lần gọi cũ về muộn không đè', () async {
    final slow = Completer<CustomerReceivablePage>();
    repo
      ..enqueueList(slow)
      ..enqueueList(_page([fx.rowsBefore[2]]));
    final first = cubit.load();
    final second = cubit.load();
    await second;
    expect([for (final r in cubit.state.items) r.displayName], ['Chị Lan']);
    slow.complete(_page(fx.rowsBefore));
    await first;
    expect([for (final r in cubit.state.items) r.displayName], ['Chị Lan']);
  });

  test('loadMore nối items và gửi cursor; không gọi khi hết cursor', () async {
    repo
      ..enqueueList(_page([fx.rowsBefore[0]], cursor: 'c1'))
      ..enqueueList(_page([fx.rowsBefore[1]]));
    await cubit.load();
    await cubit.loadMore();
    expect(repo.listCalls.last.cursor, 'c1');
    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.nextCursor, isNull);
    final calls = repo.listCalls.length;
    await cubit.loadMore();
    expect(repo.listCalls, hasLength(calls));
  });

  test('loadMore không chạy khi đang loadingMore', () async {
    final hold = Completer<CustomerReceivablePage>();
    repo
      ..enqueueList(_page([fx.rowsBefore[0]], cursor: 'c1'))
      ..enqueueList(hold);
    await cubit.load();
    final a = cubit.loadMore();
    await cubit.loadMore();
    expect(repo.listCalls, hasLength(2));
    hold.complete(_page([fx.rowsBefore[1]]));
    await a;
  });

  test('lỗi → error; load lại → ready', () async {
    repo.enqueueList(const AppException(AppErrorCode.network));
    await cubit.load();
    expect(cubit.state.status, ReceivableListStatus.error);
    await cubit.load();
    expect(cubit.state.status, ReceivableListStatus.ready);
  });

  test('clearQuery tải lại ngay với search rỗng', () async {
    await cubit.load();
    cubit.clearQuery();
    await pumpEventQueue();
    expect(cubit.state.query, '');
    expect(repo.listCalls.last.search, anyOf(isNull, isEmpty));
  });

  test('loadMore bị chặn khi đang đổi lọc', () async {
    final hold = Completer<CustomerReceivablePage>();
    repo
      ..enqueueList(_page([fx.rowsBefore[0], fx.rowsBefore[1]], cursor: 'c1'))
      ..enqueueList(hold);
    await cubit.load();
    cubit.toggleOverdue();
    await pumpEventQueue();
    await cubit.loadMore();
    expect(repo.listCalls.where((c) => c.cursor != null), isEmpty);
    hold.complete(_page([fx.rowsBefore[0]]));
    await pumpEventQueue();
    expect([for (final r in cubit.state.items) r.displayName], ['Anh Tuấn']);
    expect(cubit.state.filter, ReceivableFilter.overdue);
  });

  test('loadMore cũ về muộn không đè kết quả của lọc mới', () async {
    final more = Completer<CustomerReceivablePage>();
    repo
      ..enqueueList(_page([fx.rowsBefore[0]], cursor: 'c1'))
      ..enqueueList(more)
      ..enqueueList(_page([fx.rowsBefore[2]]));
    await cubit.load();
    final pending = cubit.loadMore();
    cubit.toggleOverdue();
    await pumpEventQueue();
    more.complete(_page([fx.rowsBefore[1]]));
    await pending;
    await pumpEventQueue();
    expect([for (final r in cubit.state.items) r.displayName], ['Chị Lan']);
    expect(cubit.state.loadingMore, isFalse);
  });
}
