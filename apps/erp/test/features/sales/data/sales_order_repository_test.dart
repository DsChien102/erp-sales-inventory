// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_order_inquiry_parity_expectations.dart';

class _Rpc implements SupabaseRpc {
  int calls = 0;
  Object? result;
  Object? error;
  Map<String, dynamic>? lastParams;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls++;
    lastParams = params;
    final e = error;
    if (e != null) throw e is AppException ? e : AppException.from(e);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Rpc rpc;
  var reads = 0;
  late SalesOrderRepository repository;

  setUp(() {
    reads = 0;
    rpc = _Rpc();
    Future<String> tenant() async {
      reads++;
      return inquiryTenantId;
    }

    repository = SalesOrderRepository(
      rpc: rpc,
      tenantId: tenant,
      actorId: () async => inquiryActorId,
      newId: () => inquiryQueryId,
    );
  });

  test('list_sends_null_keys', () async {
    rpc.result = samplePagedListJson();
    await repository.list(filter: null);
    expect(rpc.lastParams, isNotNull);
    expect(rpc.lastParams!.containsKey('store_id'), isTrue);
    expect(rpc.lastParams!['store_id'], isNull);
    expect(rpc.lastParams!.containsKey('seller_id'), isTrue);
    expect(rpc.lastParams!.containsKey('has_outstanding_receivable'), isTrue);
  });

  test('list_default_page_size_50', () async {
    rpc.result = samplePagedListJson();
    await repository.list();
    expect(rpc.lastParams!['page_size'], 50);
  });

  test('detail_sends_null_expected_version', () async {
    rpc.result = sampleDetailJson();
    await repository.getDetail(salesOrderId: inquiryOrderId);
    expect(rpc.lastParams!.containsKey('expected_source_version'), isTrue);
    expect(rpc.lastParams!['expected_source_version'], isNull);
  });

  test('cancellation_impact_pending_kept', () async {
    rpc.error = const PostgrestException(message: '{"code":"IMPACT_PENDING","message":"Impact"}');
    await expectLater(
      repository.getCancellation(salesOrderId: inquiryOrderId),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'IMPACT_PENDING')),
    );
  });

  test('tenant_actor_read_each_call', () async {
    rpc.result = samplePagedListJson();
    await repository.list();
    await repository.list();
    expect(reads, 2);
  });

  test('no_client_permission_check', () async {
    rpc.error = const PostgrestException(message: '{"code":"PERMISSION_DENIED"}');
    await expectLater(
      repository.list(),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    expect(rpc.calls, 1);
  });
}
