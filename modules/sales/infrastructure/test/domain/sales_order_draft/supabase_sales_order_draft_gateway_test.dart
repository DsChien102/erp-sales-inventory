import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_order_draft/supabase_sales_order_draft_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('SupabaseSalesOrderDraftGateway error envelopes', () {
    for (final code in <String>{
      'PERMISSION_DENIED',
      'DATA_SCOPE_DENIED',
      'CONTEXT_INVALID',
      'REFERENCE_UNAVAILABLE',
      'STALE_DATA',
      'IDEMPOTENCY_CONFLICT',
    }) {
      test('preserves stable $code envelopes', () async {
        final gateway = SupabaseSalesOrderDraftGateway(
          rpcClient: _FakeRpcClient(
            error: RpcException(jsonEncode(<String, dynamic>{'code': code, 'message': 'Safe.'})),
          ),
        );

        await expectLater(
          () => gateway.save(_saveCommand()),
          throwsA(isA<SalesContractException>().having((error) => error.code, 'code', code)),
        );
      });
    }

    test('unwraps nested PostgREST message JSON for DATA_SCOPE_DENIED', () async {
      final nested = jsonEncode(<String, dynamic>{
        'code': 'DATA_SCOPE_DENIED',
        'message': 'Store scope denied.',
      });
      final gateway = SupabaseSalesOrderDraftGateway(
        rpcClient: _FakeRpcClient(
          error: RpcException(
            jsonEncode(<String, dynamic>{
              'code': 'P0001',
              'message': nested,
            }),
          ),
        ),
      );

      await expectLater(
        () => gateway.list(
          ListSalesOrderDraftsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            storeId: 'store-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>()
              .having((error) => error.code, 'code', 'DATA_SCOPE_DENIED')
              .having((error) => error.message, 'message', 'Store scope denied.'),
        ),
      );
    });

    test('unwraps nested PostgREST message JSON for IDEMPOTENCY_CONFLICT', () async {
      final nested = jsonEncode(<String, dynamic>{
        'code': 'IDEMPOTENCY_CONFLICT',
        'message': 'Idempotency key was reused with a different payload.',
      });
      final gateway = SupabaseSalesOrderDraftGateway(
        rpcClient: _FakeRpcClient(
          error: RpcException(
            jsonEncode(<String, dynamic>{
              'hint': 'PostgREST wrapped',
              'message': nested,
            }),
          ),
        ),
      );

      await expectLater(
        () => gateway.save(_saveCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'IDEMPOTENCY_CONFLICT',
          ),
        ),
      );
    });

    test('maps unknown envelopes to CONTEXT_INVALID without forcing known codes', () async {
      final gateway = SupabaseSalesOrderDraftGateway(
        rpcClient: _FakeRpcClient(
          error: RpcException(
            jsonEncode(<String, dynamic>{'code': 'UNKNOWN_CODE', 'message': 'Nope.'}),
          ),
        ),
      );

      await expectLater(
        () => gateway.save(_saveCommand()),
        throwsA(
          isA<SalesContractException>()
              .having((error) => error.code, 'code', 'CONTEXT_INVALID')
              .having((error) => error.message, 'message', 'Sales draft operation failed.'),
        ),
      );
    });

    test('maps malformed RPC envelopes to CONTEXT_INVALID', () async {
      final gateway = SupabaseSalesOrderDraftGateway(
        rpcClient: _FakeRpcClient(error: RpcException('not-json')),
      );

      await expectLater(
        () => gateway.cancel(
          CancelSalesOrderDraftCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            draftId: 'draft-1',
            storeId: 'store-1',
            expectedVersion: 1,
            idempotencyKey: 'idem-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
    });
  });
}

SaveSalesOrderDraftCommand _saveCommand() {
  return SaveSalesOrderDraftCommand(
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    currencyCode: 'VND',
    lines: [
      SalesOrderDraftLineInput(
        productId: 'product-1',
        productSku: 'SKU-1',
        productName: 'Thuoc A',
        productUnitId: 'unit-1',
        unitCode: 'BOX',
        unitName: 'Hop',
        quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
        appliedUnitPrice: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
        lineTotal: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
        listUnitPrice: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
        pricingSourceCode: 'list',
      ),
    ],
    idempotencyKey: 'idem-1',
  );
}

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.error}) : response = const <String, dynamic>{};

  final Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}
