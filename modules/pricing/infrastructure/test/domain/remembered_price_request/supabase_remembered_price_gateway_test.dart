import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_pricing_rpc_supabase.dart';
import '../../../lib/src/domain/remembered_price_request/supabase_remembered_price_gateway.dart';

void main() {
  final request = RememberedPriceRequest.receive(
    id: '00000000-0000-4000-8000-000000000201',
    tenantId: '00000000-0000-4000-8000-000000000100',
    actorId: '00000000-0000-4000-8000-000000000099',
    sourceOrderId: '00000000-0000-4000-8000-000000000101',
    sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
    customerId: '00000000-0000-4000-8000-000000000103',
    productId: '00000000-0000-4000-8000-000000000104',
    productUnitId: '00000000-0000-4000-8000-000000000105',
    soldPrice: Money(amountMinor: 90000, currencyCode: 'VND'),
    soldAt: DateTime.utc(2026, 7, 16, 1, 30),
    idempotencyKey: 'order-line-102',
  );

  test('gateway calls save_remembered_price_from_order with exact params', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('save_remembered_price_from_order', (params) async {
        expect(params?['p_request_id'], request.id);
        return {
          'request_id': request.id,
          'result_type': 'created',
          'rule_id': '00000000-0000-4000-8000-000000000301',
          'rule_version': 1,
          'reason_code': null,
          'warnings': [],
          'is_replay': false,
        };
      });
    final gateway = SupabaseRememberedPriceGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final outcome = await gateway.save(request);

    expect(
      supabase.calls.single.functionName,
      'save_remembered_price_from_order',
    );
    expect(outcome.resultType, RememberedPriceResultType.created);
  });

  test('gateway maps IDEMPOTENCY_CONFLICT from RPC envelope', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('save_remembered_price_from_order', (_) async {
        throw RpcException(
          '{"code":"IDEMPOTENCY_CONFLICT","message":"Same key, different payload.","details":{}}',
        );
      });
    final gateway = SupabaseRememberedPriceGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    await expectLater(
      gateway.save(request),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.idempotencyConflict,
        ),
      ),
    );
  });

  test('gateway maps transport and malformed payload failures to SYSTEM_ERROR',
      () async {
    final transportSupabase = FakePricingRpcSupabase()
      ..registerHandler('save_remembered_price_from_order', (_) async {
        throw RpcException('transport failure');
      });
    final transportGateway = SupabaseRememberedPriceGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: transportSupabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );
    await expectLater(
      transportGateway.save(request),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );

    final malformedSupabase = FakePricingRpcSupabase()
      ..registerHandler('save_remembered_price_from_order', (_) async {
        return {
          'request_id': 'request-1',
          'result_type': 'created',
          'warnings': [],
          'is_replay': false,
        };
      });
    final malformedGateway = SupabaseRememberedPriceGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: malformedSupabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );
    await expectLater(
      malformedGateway.save(request),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );
  });
}
