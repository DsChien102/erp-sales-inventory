
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_checkout_parity_expectations.dart';

class _Rpc implements SupabaseRpc {
  final calls = <(String, String, Map<String, dynamic>?)>[];
  Object? result;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema, fn, params));
    final e = error;
    if (e != null) throw e is AppException ? e : AppException.from(e);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SalesFinalizeRequest _request({String payloadHash = 'hash-1'}) => SalesFinalizeRequest(
  commandId: checkoutCommandId,
  storeId: checkoutStoreId,
  currencyCode: 'VND',
  lines: checkoutLines(),
  paymentIntents: checkoutIntents(),
  commercialSnapshot: checkoutSnapshot(),
  idempotencyKey: 'checkout:attempt-1',
  payloadHash: payloadHash,
  correlationId: 'corr-1',
);

void main() {
  late _Rpc rpc;
  var tenantReads = 0;
  var actorReads = 0;
  late SalesCheckoutRepository repo;

  setUp(() {
    tenantReads = 0;
    actorReads = 0;
    rpc = _Rpc();
    repo = SalesCheckoutRepository(
      rpc: rpc,
      tenantId: () async {
        tenantReads++;
        return checkoutTenantId;
      },
      actorId: () async {
        actorReads++;
        return checkoutActorId;
      },
    );
  });

  test('finalize_rule_blocks_before_rpc', () async {
    await expectLater(
      repo.finalize(_request(payloadHash: ' ')),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', 'CONTEXT_INVALID')
            .having((e) => e.serverMessage, 'msg', 'payloadHash is required.'),
      ),
    );
    expect(rpc.calls, isEmpty);
  });

  test('finalize_calls_only_finalize_rpc', () async {
    rpc.result = checkoutResultJson('succeeded');
    await repo.finalize(_request());
    expect(rpc.calls.single.$2, 'finalize_sales_order');
  });

  test('finalize_blocked_result_carries_server_code', () async {
    rpc.result = checkoutResultJson('blocked', blockedCode: 'PRICE_CHANGED');
    final dto = await repo.finalize(_request());
    expect(dto.blockedCode, 'PRICE_CHANGED');
  });

  test('finalize_blocked_result_carries_blocked_message', () async {
    rpc.result = checkoutResultJson(
      'blocked',
      blockedCode: 'INSUFFICIENT_STOCK',
      blockedMessage: 'Thuốc A: chỉ còn 0 hộp bán được.',
    );
    final dto = await repo.finalize(_request());
    expect(dto.blockedCode, 'INSUFFICIENT_STOCK');
    expect(dto.blockedMessage, 'Thuốc A: chỉ còn 0 hộp bán được.');
  });

  test('finalize_network_error_is_uncertain', () async {
    rpc.error = const AppException('NETWORK_ERROR');
    await expectLater(
      repo.finalize(_request()),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'UNCERTAIN_RESULT')),
    );
  });

  test('precheck_network_error_stays_network', () async {
    rpc.error = const AppException('NETWORK_ERROR');
    await expectLater(
      repo.precheck(
        storeId: checkoutStoreId,
        currencyCode: 'VND',
        lines: checkoutLines(),
        paymentIntents: const [],
      ),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
    );
  });

  test('tenant_actor_read_each_call', () async {
    rpc.result = checkoutResultJson('processing');
    await repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k');
    await repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k');
    expect(tenantReads, 2);
    expect(actorReads, 2);
  });

  test('query_id_is_fresh_uuid_each_call', () async {
    rpc.result = checkoutResultJson('processing');
    await repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k');
    await repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k');
    final ids = rpc.calls.map((c) => c.$3!['p_query_id']).toSet();
    expect(ids, hasLength(2));
  });

  test('no_client_permission_check', () async {
    rpc.error = PostgrestException(message: '{"code":"PERMISSION_DENIED","message":"x"}');
    await expectLater(
      repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    expect(rpc.calls, hasLength(1));
  });
}
