import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_command_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

RetryIssuanceStartRequest _retryRequest() {
  return const RetryIssuanceStartRequest(
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    salesOrderId: 'order-1',
    expectedOrderVersion: 18,
    idempotencyKey: '692c44cb-03a4-456b-a8a8-c5973f4e93db',
    acknowledgeWarnings: true,
  );
}

void main() {
  group('SupabaseIssuanceCommandGateway.retryIssuance', () {
    test('retryIssuance sends exact retry parameters to RPC', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('retry_issuance', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
            'p_expected_order_version': '18',
            'p_idempotency_key': '692c44cb-03a4-456b-a8a8-c5973f4e93db',
            'p_acknowledge_warnings': true,
          });
          return [
            {
              'issuance_id': 'iss-1',
              'attempt_id': 'att-2',
              'status': 'PREPARING',
            },
          ];
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      final result = await gateway.retryIssuance(_retryRequest());

      expect(supabase.calls.single.functionName, 'retry_issuance');
      expect(result.issuanceId, 'iss-1');
      expect(result.attemptId, 'att-2');
      expect(result.status, IssuanceAttemptStatus.preparing);
    });

    test('maps OPERATION_IN_PROGRESS to EInvoiceBlockedException', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('retry_issuance', (_) async {
          throw RpcException(
            'OPERATION_IN_PROGRESS: issuance attempt currently PREPARING',
          );
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.retryIssuance(_retryRequest()),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.operationInProgress,
          ),
        ),
      );
    });

    test('maps INVALID_STATUS to EInvoiceBlockedException', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('retry_issuance', (_) async {
          throw RpcException('INVALID_STATUS: cannot retry from SUCCEEDED');
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.retryIssuance(_retryRequest()),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.invalidStatus,
          ),
        ),
      );
    });

    test(
      'maps STATE_CHANGED / VERSION_MISMATCH to EInvoiceBlockedException',
      () async {
        final supabase = FakeEinvoiceRpcSupabase()
          ..registerHandler('retry_issuance', (_) async {
            throw RpcException(
              'STATE_CHANGED: {"details":{"blockers":["VERSION_MISMATCH"]}}',
            );
          });
        final gateway = SupabaseIssuanceCommandGateway(
          rpcClient: _rpcClient(supabase),
        );

        await expectLater(
          gateway.retryIssuance(_retryRequest()),
          throwsA(
            isA<EInvoiceBlockedException>().having(
              (error) => error.code,
              'code',
              EInvoiceBlockedCodes.stateChanged,
            ),
          ),
        );
      },
    );

    test(
      'maps ISSUANCE_NOT_READY to IssuanceNotReadyException with blockers',
      () async {
        final supabase = FakeEinvoiceRpcSupabase()
          ..registerHandler('retry_issuance', (_) async {
            throw RpcException(
              'ISSUANCE_NOT_READY: {"details":{"blockers":["BUYER_SOURCE_UNAVAILABLE"]}}',
            );
          });
        final gateway = SupabaseIssuanceCommandGateway(
          rpcClient: _rpcClient(supabase),
        );

        await expectLater(
          gateway.retryIssuance(_retryRequest()),
          throwsA(
            isA<IssuanceNotReadyException>()
                .having((error) => error.blockers, 'blockers', [
                  'BUYER_SOURCE_UNAVAILABLE',
                ])
                .having(
                  (error) => error.code,
                  'code',
                  EInvoiceBlockedCodes.issuanceNotReady,
                ),
          ),
        );
      },
    );

    test('maps ALREADY_ISSUED to EInvoiceBlockedException', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('retry_issuance', (_) async {
          throw RpcException(
            'ALREADY_ISSUED: sales order already has electronic invoice',
          );
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.retryIssuance(_retryRequest()),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.alreadyIssued,
          ),
        ),
      );
    });

    test('maps IDEMPOTENCY_CONFLICT to EInvoiceBlockedException', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('retry_issuance', (_) async {
          throw RpcException(
            'IDEMPOTENCY_CONFLICT: payload differs for key 692c44cb-03a4-456b-a8a8-c5973f4e93db',
          );
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.retryIssuance(_retryRequest()),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.idempotencyConflict,
          ),
        ),
      );
    });

    test('throws systemError on empty rows', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('retry_issuance', (_) async => []);
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.retryIssuance(_retryRequest()),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.systemError,
          ),
        ),
      );
    });
  });
}
