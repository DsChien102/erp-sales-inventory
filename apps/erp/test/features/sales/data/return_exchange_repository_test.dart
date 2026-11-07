
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_post_sale_parity_expectations.dart';

class _RecordingRpc implements SupabaseRpc {
  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  Object? result;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema: schema, fn: fn, params: params));
    if (result is Exception) throw result!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('ReturnExchangeRepository', () {
    test('C6: confirm_sends_fixed_reference_decision', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
      final request = ReturnExchangeConfirmRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'idem',
        payloadHash: 'hash',
        correlationId: parityCorrelationId,
        expectedVersion: 4,
      );
      await repo.confirm(request);
      expect(
        rpc.calls.single.params?['reference_decision'],
        equals(const <String, dynamic>{
          'blockers': <Object>[],
          'exchange_products_by_product_unit_id': <String, Object>{},
          'exchange_units_by_product_unit_id': <String, Object>{},
          'exchange_prices_by_product_unit_id': <String, Object>{},
          'pricing_source_version': null,
          'inventory_source_version': null,
        }),
      );
    });

    test('C6: evaluate_sends_fixed_reference_decision', () async {
      final rpc = _RecordingRpc()..result = sampleValuationJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
      await repo.evaluate(
        returnExchangeId: parityReturnExchangeId,
        expectedSourceVersion: 7,
      );
      expect(
        rpc.calls.single.params?['reference_decision'],
        equals(const <String, dynamic>{
          'blockers': <Object>[],
          'exchange_products_by_product_unit_id': <String, Object>{},
          'exchange_units_by_product_unit_id': <String, Object>{},
          'exchange_prices_by_product_unit_id': <String, Object>{},
          'pricing_source_version': null,
          'inventory_source_version': null,
        }),
      );
    });

    test('C6: confirm_single_rpc_call (no _get_return_exchange_context)', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
      final request = ReturnExchangeConfirmRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'idem',
        payloadHash: 'hash',
        correlationId: parityCorrelationId,
        expectedVersion: 4,
      );
      await repo.confirm(request);
      expect(rpc.calls.map((c) => c.fn).toList(), equals(['confirm_return_exchange']));
    });

    test('cancel_null_version_keeps_key', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson(status: 'cancelled');
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
      final request = const ReturnExchangeMutationRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'idem',
        payloadHash: 'hash',
        correlationId: parityCorrelationId,
        expectedVersion: null,
      );
      await repo.cancel(request);
      expect(rpc.calls.single.params?.containsKey('expected_version'), isTrue);
      expect(rpc.calls.single.params?['expected_version'], isNull);
    });

    test('confirm_due_date_local_date drops time-of-day', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
      final request = ReturnExchangeConfirmRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'idem',
        payloadHash: 'hash',
        correlationId: parityCorrelationId,
        expectedVersion: 4,
        paymentDueDate: DateTime(2026, 11, 20, 23, 30),
      );
      await repo.confirm(request);
      expect(rpc.calls.single.params?['payment_due_date'], '2026-11-20');
    });

    test('preview_uses_p_keys_without_query_id', () async {
      final rpc = _RecordingRpc()..result = samplePreviewPricingJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
      await repo.previewPricing(
        salesOrderId: parityOrderId,
        lines: samplePricingLines,
      );
      final params = rpc.calls.single.params!;
      expect(params.containsKey('p_tenant_id'), isTrue);
      expect(params.containsKey('p_actor_id'), isTrue);
      expect(params.containsKey('p_sales_order_id'), isTrue);
      expect(params.containsKey('p_lines'), isTrue);
      expect(params.containsKey('query_id'), isFalse);
    });

    test('tenant_actor_read_each_call', () async {
      var tenantReads = 0;
      var actorReads = 0;
      final rpc = _RecordingRpc()..result = sampleReturnExchangePrecheckJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async {
          tenantReads++;
          return 'tenant-$tenantReads';
        },
        actorId: () async {
          actorReads++;
          return 'actor-$actorReads';
        },
      );

      await repo.precheck(salesOrderId: parityOrderId);
      expect(tenantReads, 1);
      expect(actorReads, 1);
      expect(rpc.calls.last.params?['tenant_id'], 'tenant-1');
      expect(rpc.calls.last.params?['actor_id'], 'actor-1');

      rpc.result = sampleReturnableOrderLinesJson();
      await repo.getReturnableLines(salesOrderId: parityOrderId);
      expect(tenantReads, 2);
      expect(actorReads, 2);
      expect(rpc.calls.last.params?['tenant_id'], 'tenant-2');
      expect(rpc.calls.last.params?['actor_id'], 'actor-2');
    });

    test(
      'no_client_permission_check maps PERMISSION_DENIED to NO_PERMISSION in single call',
      () async {
        final rpc = _RecordingRpc()
          ..result = const PostgrestException(
            message: '{"code":"PERMISSION_DENIED","message":"forbidden"}',
          );
        final repo = ReturnExchangeRepository(
          rpc: rpc,
          tenantId: () async => parityTenantId,
          actorId: () async => parityActorId,
        );

        await expectLater(
          () => repo.precheck(salesOrderId: parityOrderId),
          throwsA(
            isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION'),
          ),
        );
        expect(rpc.calls.length, 1);
      },
    );

    test('C9: blocked_keeps_details_blockers', () async {
      final rpc = _RecordingRpc()
        ..result = const PostgrestException(
          message:
              '{"code":"RETURN_EXCHANGE_BLOCKED","details":{"blockers":[{"code":"DRAFT_RETURN_ACTIVE","message":"m"}]}}',
        );
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );

      await expectLater(
        () => repo.precheck(salesOrderId: parityOrderId),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'RETURN_EXCHANGE_BLOCKED')
              .having((e) => e.details?['blockers'], 'details.blockers', isA<List>()),
        ),
      );
    });

    test('C9: blocked_without_details_has_null_details', () async {
      final rpc = _RecordingRpc()
        ..result = const PostgrestException(
          message: '{"code":"RETURN_EXCHANGE_BLOCKED"}',
        );
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );

      await expectLater(
        () => repo.precheck(salesOrderId: parityOrderId),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', 'RETURN_EXCHANGE_BLOCKED')
              .having((e) => e.details, 'details', isNull),
        ),
      );
    });
  });
}
