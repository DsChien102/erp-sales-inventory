// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sales_checkout_parity_expectations.dart';

class _RecordingRpc implements SupabaseRpc {
  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  Object? result;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema: schema, fn: fn, params: params));
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('new', () {
    late _RecordingRpc rpc;
    late SalesCheckoutRepository repo;

    setUp(() {
      rpc = _RecordingRpc();
      var n = 0;
      repo = SalesCheckoutRepository(
        rpc: rpc,
        tenantId: () async => checkoutTenantId,
        actorId: () async => checkoutActorId,
        newId: () => n++ == 0 ? checkoutQueryId : 'unexpected-second-id',
      );
    });

    void expectCall(String fn, Map<String, dynamic> params) {
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, fn);
      expect(rpc.calls.single.params, equals(params));
    }

    test('params_precheck', () async {
      rpc.result = precheckJson();
      final dto = await repo.precheck(
        storeId: checkoutStoreId,
        customerId: 'customer-1',
        currencyCode: checkoutCurrencyRaw,
        paymentDueDate: DateTime(2026, 11, 9, 15),
        lines: checkoutLines(),
        paymentIntents: checkoutIntents(),
        expectedSourceVersion: 4,
      );
      expectCall('precheck_sales_order_checkout', expectedPrecheckParams());
      expectPrecheck(dto);
    });

    test('params_precheck_omits_expected_version_when_null', () async {
      rpc.result = precheckJson();
      await repo.precheck(
        storeId: checkoutStoreId,
        customerId: 'customer-1',
        currencyCode: checkoutCurrencyRaw,
        paymentDueDate: DateTime(2026, 11, 9, 15),
        lines: checkoutLines(),
        paymentIntents: checkoutIntents(),
      );
      expectCall('precheck_sales_order_checkout', expectedPrecheckParams(expectedVersion: null));
      expect(rpc.calls.single.params, isNot(contains('p_expected_source_version')));
    });

    test('params_finalize', () async {
      rpc.result = checkoutResultJson('succeeded');
      final dto = await repo.finalize(
        SalesFinalizeRequest(
          commandId: checkoutCommandId,
          storeId: checkoutStoreId,
          sourceDraftId: 'draft-7',
          customerId: 'customer-1',
          currencyCode: checkoutCurrencyRaw,
          orderNote: ' Giao chiều ',
          paymentDueDate: DateTime(2026, 11, 9, 15),
          lines: checkoutLines(),
          paymentIntents: checkoutIntents(),
          commercialSnapshot: checkoutSnapshot(),
          idempotencyKey: 'checkout:attempt-1',
          payloadHash: 'hash-1',
          correlationId: 'corr-1',
          expectedSourceVersion: 4,
        ),
      );
      expectCall('finalize_sales_order', expectedFinalizeParams());
      expectCheckoutResult(dto, 'succeeded');
    });

    test('params_get_checkout_result', () async {
      rpc.result = checkoutResultJson('processing');
      final dto = await repo.getResult(
        storeId: checkoutStoreId,
        idempotencyKey: 'checkout:attempt-1',
      );
      expectCall('get_checkout_result', expectedStatusParams());
      expectCheckoutResult(dto, 'processing');
    });

    for (final status in checkoutStatuses.keys) {
      test('parse_checkout_result_$status', () async {
        rpc.result = checkoutResultJson(status);
        expectCheckoutResult(
          await repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'checkout:attempt-1'),
          status,
        );
      });
    }

    test('parse_rejects_unknown_status', () async {
      rpc.result = checkoutResultJson('weird');
      await expectLater(
        repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });

    test('parse_rejects_blank_idempotency_key', () async {
      rpc.result = {...checkoutResultJson('succeeded'), 'idempotencyKey': ' '};
      await expectLater(
        repo.getResult(storeId: checkoutStoreId, idempotencyKey: 'k'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });
  });
}
