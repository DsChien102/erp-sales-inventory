// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_checkout_parity_expectations.dart';

class _Rpc implements SupabaseRpc {
  int calls = 0;
  Object? result;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls++;
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
  late SalesPaymentRepository payment;
  late SalesOrderRepository order;

  setUp(() {
    reads = 0;
    rpc = _Rpc();
    Future<String> tenant() async {
      reads++;
      return checkoutTenantId;
    }

    payment = SalesPaymentRepository(rpc: rpc, tenantId: tenant, actorId: () async => 'u');
    order = SalesOrderRepository(rpc: rpc, tenantId: tenant, actorId: () async => 'u');
  });

  test('tenant_actor_read_each_call', () async {
    rpc.result = settlementJson();
    await payment.getSettlement(salesOrderId: 'o');
    await payment.getSettlement(salesOrderId: 'o');
    expect(reads, 2);
    rpc.result = orderResultJson();
    await order.get(salesOrderId: 'o');
    expect(reads, 3);
  });

  test('no_client_permission_check', () async {
    rpc.error = PostgrestException(message: '{"code":"PERMISSION_DENIED"}');
    await expectLater(
      payment.getSummary(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    await expectLater(
      order.get(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    expect(rpc.calls, 2);
  });

  test('malformed_json_is_system_error', () async {
    rpc.result = {'status': 'weird'};
    await expectLater(
      payment.getSummary(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
    );
  });

  test('not_found_kept', () async {
    rpc.error = PostgrestException(message: '{"code":"NOT_FOUND","message":"x"}');
    await expectLater(
      order.get(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NOT_FOUND')),
    );
  });
}
