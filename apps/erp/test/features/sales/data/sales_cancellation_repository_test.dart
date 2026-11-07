
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
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
  group('SalesCancellationRepository', () {
    test('tenant_actor_read_each_call', () async {
      var tenantReads = 0;
      var actorReads = 0;
      final rpc = _RecordingRpc()..result = sampleCancelPrecheckJson();
      final repo = SalesCancellationRepository(
        rpc: rpc,
        tenantId: () async {
          tenantReads++;
          return 'tenant-$tenantReads';
        },
        actorId: () async {
          actorReads++;
          return 'actor-$actorReads';
        },
        newId: () => parityQueryId,
      );

      await repo.precheck(salesOrderId: parityOrderId, expectedSourceVersion: 7);
      expect(tenantReads, 1);
      expect(actorReads, 1);
      expect(rpc.calls.last.params?['tenant_id'], 'tenant-1');
      expect(rpc.calls.last.params?['actor_id'], 'actor-1');

      rpc.result = sampleCancelResultJson();
      await repo.confirm(
        const SalesOrderCancellationRequest(
          commandId: parityCommandId,
          salesOrderId: parityOrderId,
          reasonText: 'note',
          idempotencyKey: 'idem',
          payloadHash: 'hash',
          correlationId: parityCorrelationId,
          expectedOrderVersion: 7,
          expectedSettlementVersion: 3,
        ),
      );
      expect(tenantReads, 2);
      expect(actorReads, 2);
      expect(rpc.calls.last.params?['tenant_id'], 'tenant-2');
      expect(rpc.calls.last.params?['actor_id'], 'actor-2');
    });

    test('no_client_permission_check maps server error to NO_PERMISSION in single call', () async {
      final rpc = _RecordingRpc()
        ..result = const PostgrestException(
          message: '{"code":"PERMISSION_DENIED","message":"forbidden"}',
        );
      final repo = SalesCancellationRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );

      await expectLater(
        () => repo.precheck(salesOrderId: parityOrderId, expectedSourceVersion: 7),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION'),
        ),
      );
      expect(rpc.calls.length, 1);
    });
  });
}

