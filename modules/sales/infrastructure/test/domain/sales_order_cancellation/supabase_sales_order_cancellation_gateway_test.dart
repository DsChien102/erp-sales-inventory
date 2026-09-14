import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'package:vet45_sales_infrastructure/src/domain/sales_order_cancellation/supabase_sales_order_cancellation_gateway.dart';

void main() {
  group('SupabaseSalesOrderCancellationGateway', () {
    test('uses precheck_sales_order_cancellation and maps a ready result', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'allowed': true,
          'sourceVersion': 7,
          'sourceSettlementVersion': 3,
          'blockers': <Object?>[],
        },
      );
      final gateway = SupabaseSalesOrderCancellationGateway(rpcClient: rpc);

      final dto = await gateway.precheck(
        PrecheckSalesOrderCancellationQuery(
          id: 'query-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedSourceVersion: 7,
        ),
      );

      expect(rpc.lastProcedure, 'precheck_sales_order_cancellation');
      expect(rpc.lastParams?['sales_order_id'], 'order-1');
      expect(dto.allowed, isTrue);
      expect(dto.sourceSettlementVersion, 3);
    });

    test('uses confirm_sales_order_cancellation and maps the result', () async {
      final rpc = _FakeRpcClient(response: _resultJson('confirmed'));
      final gateway = SupabaseSalesOrderCancellationGateway(rpcClient: rpc);

      final result = await gateway.confirm(_confirmCommand());

      expect(rpc.lastProcedure, 'confirm_sales_order_cancellation');
      expect(rpc.lastParams?['expected_order_version'], 7);
      expect(rpc.lastParams?['expected_settlement_version'], 3);
      expect(result.cancellationId, 'cancellation-1');
      expect(result.status, SalesOrderCancellationStatus.confirmed);
    });

    test('uses get_sales_order_cancellation and maps detail', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'result': _resultJson('completed'),
          'reason': <String, dynamic>{
            'reasonCode': 'CUSTOMER_REQUEST',
            'reasonText': 'Customer request',
          },
          'cancelledAt': '2026-08-10T02:03:04Z',
          'cancelledByActorId': 'actor-7',
          'netConfirmedCollectionMinor': 0,
        },
      );
      final gateway = SupabaseSalesOrderCancellationGateway(rpcClient: rpc);

      final detail = await gateway.getDetail(
        GetSalesOrderCancellationQuery(
          id: 'query-2',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_sales_order_cancellation');
      expect(detail.result.status, SalesOrderCancellationStatus.completed);
    });

    test('maps detail with blank reasonText', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'result': _resultJson('completed'),
          'reason': <String, dynamic>{
            'reasonCode': 'CUSTOMER_REQUEST',
            'reasonText': '',
          },
          'cancelledAt': '2026-08-10T02:03:04Z',
          'cancelledByActorId': 'actor-7',
          'netConfirmedCollectionMinor': 0,
        },
      );
      final gateway = SupabaseSalesOrderCancellationGateway(rpcClient: rpc);

      final detail = await gateway.getDetail(
        GetSalesOrderCancellationQuery(
          id: 'query-3',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(detail.reason.reasonText, isEmpty);
      expect(detail.cancelledAt.isUtc, isTrue);
    });

    test('uses list_sales_order_cancellation_reasons once and maps policies', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'items': <Object?>[
            <String, dynamic>{
              'reasonCode': 'OTHER',
              'displayName': 'Khác',
              'requiresNote': true,
              'sortOrder': 900,
            },
          ],
        },
      );
      final gateway = SupabaseSalesOrderCancellationGateway(rpcClient: rpc);

      final policies = await gateway.listReasons(
        ListSalesOrderCancellationReasonsQuery(
          id: 'query-9',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
        ),
      );

      expect(rpc.lastProcedure, 'list_sales_order_cancellation_reasons');
      expect(rpc.callCount, 1);
      expect(rpc.lastParams, <String, dynamic>{
        'query_id': 'query-9',
        'tenant_id': 'tenant-1',
        'actor_id': 'actor-1',
      });
      expect(policies.single.reasonCode, 'OTHER');
      expect(policies.single.displayName, 'Khác');
      expect(policies.single.requiresNote, isTrue);
    });

    for (final code in <String>{
      'CANCELLATION_BLOCKED',
      'STALE_VERSION',
      'IDEMPOTENCY_CONFLICT',
      'IMPACT_PENDING',
      'PERMISSION_DENIED',
      'NOT_FOUND',
      'DATA_SCOPE_DENIED',
      'DEPENDENCY_UNAVAILABLE',
    }) {
      test('preserves stable $code error envelopes', () async {
        final rpc = _FakeRpcClient(
          error: RpcException(jsonEncode(<String, dynamic>{'code': code, 'message': 'Safe.'})),
        );
        final gateway = SupabaseSalesOrderCancellationGateway(rpcClient: rpc);

        await expectLater(
          () => gateway.confirm(_confirmCommand()),
          throwsA(isA<SalesContractException>().having((error) => error.code, 'code', code)),
        );
      });
    }

    test('maps malformed result responses to DEPENDENCY_UNAVAILABLE', () async {
      final gateway = SupabaseSalesOrderCancellationGateway(
        rpcClient: _FakeRpcClient(response: <String, dynamic>{'status': 'confirmed'}),
      );

      await expectLater(
        () => gateway.confirm(_confirmCommand()),
        throwsA(
          isA<SalesContractException>()
              .having((error) => error.code, 'code', 'DEPENDENCY_UNAVAILABLE')
              .having(
                (error) => error.message,
                'message',
                'Sales order cancellation operation failed.',
              ),
        ),
      );
    });

    test('maps malformed RPC envelopes to DEPENDENCY_UNAVAILABLE', () async {
      final gateway = SupabaseSalesOrderCancellationGateway(
        rpcClient: _FakeRpcClient(error: RpcException('not-json')),
      );

      await expectLater(
        () => gateway.precheck(
          PrecheckSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'DEPENDENCY_UNAVAILABLE',
          ),
        ),
      );
    });

    test('maps unknown RPC codes to DEPENDENCY_UNAVAILABLE', () async {
      final gateway = SupabaseSalesOrderCancellationGateway(
        rpcClient: _FakeRpcClient(
          error: RpcException(
            jsonEncode(<String, dynamic>{'code': 'UNKNOWN_CODE', 'message': 'Nope.'}),
          ),
        ),
      );

      await expectLater(
        () => gateway.getDetail(
          GetSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'DEPENDENCY_UNAVAILABLE',
          ),
        ),
      );
    });

    test('maps generic RPC failures to DEPENDENCY_UNAVAILABLE', () async {
      final gateway = SupabaseSalesOrderCancellationGateway(
        rpcClient: _FakeRpcClient(error: StateError('transport failed')),
      );

      await expectLater(
        () => gateway.confirm(_confirmCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'DEPENDENCY_UNAVAILABLE',
          ),
        ),
      );
    });
  });
}

ConfirmSalesOrderCancellationCommand _confirmCommand() => ConfirmSalesOrderCancellationCommand(
  id: 'command-1',
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: 'order-1',
  reason: const CancellationReasonDto(
    reasonText: 'Customer request',
  ),
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
  expectedVersion: 7,
  expectedSettlementVersion: 3,
);

Map<String, dynamic> _resultJson(String status) => <String, dynamic>{
  'cancellationId': 'cancellation-1',
  'salesOrderId': 'order-1',
  'salesOrderVersion': 8,
  'status': status,
};

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.response = const <String, dynamic>{}, this.error});

  final Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    callCount += 1;
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}
