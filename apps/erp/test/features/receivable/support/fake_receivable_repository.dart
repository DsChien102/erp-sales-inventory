import 'dart:async';
import 'dart:collection';

import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/data/receivable_repository.dart';

import 'receivable_fixtures.dart' as fx;

/// Hàng đợi kết quả cho một hàm: giá trị, lỗi (bất kỳ Object khác), hoặc [Completer] để giữ phản hồi.
class _Script<T> {
  _Script(this._fallback);

  final T Function() _fallback;
  final Queue<Object> _queue = Queue();

  void add(Object v) => _queue.add(v);

  Future<T> next() {
    if (_queue.isEmpty) return Future.value(_fallback());
    final x = _queue.removeFirst();
    if (x is Completer<T>) return x.future;
    if (x is T) return Future.value(x as T);
    return Future.error(x);
  }
}

typedef ListCall = ({ReceivableFilter filter, String? search, String? cursor});

class FakeReceivableRepository implements ReceivableRepository {
  final _list = _Script<CustomerReceivablePage>(() => fx.pageBefore);
  final _customer = _Script<CustomerReceivableDetail>(() => fx.tuanDetail);
  final _history = _Script<ReceivableHistoryPage>(
    () => ReceivableHistoryPage(items: fx.tuanHistoryBefore, nextCursor: null),
  );
  final _record = _Script<CustomerCollectionResult>(
    () => const CustomerCollectionResult(collectionId: 'cc-1', outstandingAfterMinor: 8000000),
  );

  final List<ListCall> listCalls = [];
  final List<String> customerCalls = [];
  final List<({String customerId, String? cursor})> historyCalls = [];
  final List<CustomerCollectionRequest> collectionCalls = [];

  void enqueueList(Object v) => _list.add(v);
  void enqueueCustomer(Object v) => _customer.add(v);
  void enqueueHistory(Object v) => _history.add(v);
  void enqueueRecord(Object v) => _record.add(v);

  @override
  Future<CustomerReceivablePage> list({
    ReceivableFilter filter = ReceivableFilter.all,
    String? search,
    String? cursor,
  }) {
    listCalls.add((filter: filter, search: search, cursor: cursor));
    return _list.next();
  }

  @override
  Future<CustomerReceivableDetail> getCustomer(String customerId) {
    customerCalls.add(customerId);
    return _customer.next();
  }

  final List<String> summaryCalls = [];
  Object summaryResult = const CustomerReceivableSummary(
    outstandingMinor: 18000000,
    openOrderCount: 3,
    maxOverdueDays: 8,
  );

  @override
  Future<CustomerReceivableSummary> getSummary(String customerId) {
    summaryCalls.add(customerId);
    final r = summaryResult;
    if (r is CustomerReceivableSummary) return Future.value(r);
    return Future.error(r);
  }

  @override
  Future<ReceivableHistoryPage> history(String customerId, {String? cursor}) {
    historyCalls.add((customerId: customerId, cursor: cursor));
    return _history.next();
  }

  @override
  Future<CustomerCollectionResult> recordCollection(CustomerCollectionRequest request) {
    collectionCalls.add(request);
    return _record.next();
  }
}
