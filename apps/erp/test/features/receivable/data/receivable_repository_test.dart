import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/receivable/data/receivable_models.dart';
import 'package:erp/features/receivable/data/receivable_repository.dart';
import 'package:erp/features/receivable/logic/receivable_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/receivable_fixtures.dart' as fx;

class _Rpc implements SupabaseRpc {
  String? schema;
  String? fn;
  Map<String, dynamic>? params;
  Object? result;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    this.schema = schema;
    this.fn = fn;
    this.params = params;
    final e = error;
    if (e != null) throw e is AppException ? e : AppException.from(e);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Rpc rpc;
  late ReceivableRepository repo;

  setUp(() {
    rpc = _Rpc();
    repo = ReceivableRepository(
      rpc: rpc,
      tenantId: () async => 't-1',
      actorId: () async => 'u-1',
    );
  });

  test('list gọi list_customer_receivables và đọc fixture', () async {
    rpc.result = fx.listJson;
    final page = await repo.list(filter: ReceivableFilter.overdue, search: '  ', cursor: 'c1');
    expect(rpc.schema, 'receivable');
    expect(rpc.fn, 'list_customer_receivables');
    expect(rpc.params, {
      'p_tenant_id': 't-1',
      'p_actor_id': 'u-1',
      'p_filter': 'overdue',
      'p_search': null,
      'p_cursor': 'c1',
      'p_page_size': 50,
    });
    expect(page, fx.pageBefore);
  });

  test('list gửi search đã trim', () async {
    rpc.result = fx.listJson;
    await repo.list(search: ' tuan ');
    expect(rpc.params!['p_search'], 'tuan');
    expect(rpc.params!['p_filter'], 'all');
  });

  test('getCustomer', () async {
    rpc.result = fx.tuanDetailJson;
    final d = await repo.getCustomer(fx.tuanId);
    expect(rpc.fn, 'get_customer_receivable');
    expect(rpc.params!['p_customer_partner_id'], fx.tuanId);
    expect(d, fx.tuanDetail);
  });

  test('history', () async {
    rpc.result = fx.historyJson;
    final h = await repo.history(fx.tuanId, cursor: 'x');
    expect(rpc.fn, 'list_customer_receivable_history');
    expect(rpc.params!['p_cursor'], 'x');
    expect(rpc.params!['p_page_size'], 20);
    final it = h.items.single;
    expect(it.kind, ReceivableHistoryKind.customerCollection);
    expect(it.allocations.first.orderCode, 'DH-002');
    expect(it.actorDisplayName, 'Nguyễn An');
    expect(it.externalReference, isNull);
    expect(h.nextCursor, isNull);
  });

  test('recordCollection gửi đúng tham số', () async {
    rpc.result = {'collectionId': 'cc-1', 'outstandingAfterMinor': 8000000, 'allocations': []};
    final r = await repo.recordCollection(
      const CustomerCollectionRequest(
        customerId: 'c-tuan',
        amountMinor: 10000000,
        method: CollectionMethod.manualBankTransfer,
        externalReference: '  ',
        orderIds: ['so-001', 'so-002'],
        expectedOutstandingMinor: 18000000,
        idempotencyKey: 'k1',
      ),
    );
    expect(rpc.fn, 'record_customer_collection');
    expect(rpc.params, {
      'p_tenant_id': 't-1',
      'p_actor_id': 'u-1',
      'p_customer_partner_id': 'c-tuan',
      'p_amount_minor': 10000000,
      'p_payment_method_code': 'manualBankTransfer',
      'p_external_reference': null,
      'p_order_ids': ['so-001', 'so-002'],
      'p_expected_outstanding_minor': 18000000,
      'p_idempotency_key': 'k1',
    });
    expect(r.collectionId, 'cc-1');
    expect(r.outstandingAfterMinor, 8000000);
  });

  test('RECEIVABLE_CHANGED → thông điệp 6.3', () async {
    rpc.error = const AppException('RECEIVABLE_CHANGED');
    try {
      await repo.getCustomer('x');
      fail('phải ném lỗi');
    } on AppException catch (e) {
      expect(e.code, 'RECEIVABLE_CHANGED');
      expect(
        e.userMessage(kReceivableErrorMessages),
        'Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.',
      );
    }
  });

  test('JSON null cho nextDueDate / dueDate', () {
    final row = CustomerReceivableRow.fromJson({
      ...(fx.listJson['items'] as List).first as Map<String, dynamic>,
      'nextDueDate': null,
    });
    expect(row.nextDueDate, isNull);
    final o = OpenReceivableOrder.fromJson({
      ...(fx.tuanDetailJson['openOrders'] as List).first as Map<String, dynamic>,
      'dueDate': null,
    });
    expect(o.dueDate, isNull);
  });

  test('getSummary sends customer id and parses', () async {
    rpc.result = {'outstandingMinor': 18000000, 'openOrderCount': 3, 'maxOverdueDays': 8};
    final r = await repo.getSummary('c-1');
    expect(rpc.fn, 'get_customer_receivable_summary');
    expect(rpc.params!['p_customer_partner_id'], 'c-1');
    expect(rpc.params!['p_tenant_id'], 't-1');
    expect(r.outstandingMinor, 18000000);
    expect(r.openOrderCount, 3);
    expect(r.maxOverdueDays, 8);
  });
}
