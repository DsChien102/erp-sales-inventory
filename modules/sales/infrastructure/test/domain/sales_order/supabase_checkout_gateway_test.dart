import 'dart:convert';
import 'dart:async';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('SupabaseCheckoutGateway', () {
    test('calls precheck_sales_order_checkout and maps response', () async {
      final rpc = _FakeRpcClient(
        response: {
          'canFinalize': true,
          'blockers': <Object?>[],
          'monetarySummary': {
            'subtotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
            'discountTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
            'grandTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          },
          'receivableRequirement': {
            'isRequired': false,
            'amount': {'amountMinor': 0, 'currencyCode': 'VND'},
            'customerId': 'customer-1',
          },
        },
      );
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      final dto = await gateway.precheck(_query());

      expect(rpc.lastProcedure, 'precheck_sales_order_checkout');
      expect(rpc.lastParams?['p_tenant_id'], 'tenant-1');
      expect(dto.canFinalize, isTrue);
    });

    test('S12 finalize sends idempotency envelope and maps succeeded result', () async {
      final rpc = _FakeRpcClient(
        response: {
          'idempotencyKey': 'attempt-1',
          'salesOrderId': 'order-1',
          'salesOrderVersion': 1,
          'status': 'succeeded',
        },
      );
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      final result = await gateway.finalize(_command());

      expect(rpc.lastProcedure, 'finalize_sales_order');
      expect(rpc.lastParams?['p_idempotency_key'], 'idem-1');
      expect(rpc.lastParams?['p_payload_hash'], 'hash-1');
      expect(rpc.lastParams?['p_correlation_id'], 'corr-1');
      expect(rpc.lastParams?['p_source_draft_id'], 'draft-1');
      expect(rpc.lastParams?['p_order_note'], ' Giao sau 17:00 ');
      expect(result.status, CheckoutResultStatus.succeeded);
      expect(result.salesOrderId, 'order-1');
    });

    test('S12 get_checkout_result maps succeeded recovery result', () async {
      final rpc = _FakeRpcClient(
        response: {
          'idempotencyKey': 'attempt-1',
          'salesOrderId': 'order-1',
          'salesOrderVersion': 1,
          'status': 'succeeded',
        },
      );
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      final result = await gateway.getResult(_statusQuery());

      expect(rpc.lastProcedure, 'get_checkout_result');
      expect(rpc.lastParams?['p_idempotency_key'], 'attempt-1');
      expect(result.status, CheckoutResultStatus.succeeded);
    });

    test('S12 finalize maps IDEMPOTENCY_CONFLICT envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(
          jsonEncode({
            'code': 'IDEMPOTENCY_CONFLICT',
            'message': 'Idempotency key was reused with a different payload.',
          }),
        ),
      );
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.finalize(_command()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'IDEMPOTENCY_CONFLICT',
          ),
        ),
      );
    });

    test('S12 finalize maps UNCERTAIN_RESULT envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(
          jsonEncode({
            'code': 'UNCERTAIN_RESULT',
            'message': 'Checkout result is uncertain.',
          }),
        ),
      );
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.finalize(_command()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'UNCERTAIN_RESULT',
          ),
        ),
      );
    });

    test('finalize preserves product-not-sellable envelope code', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(
          jsonEncode({
            'code': 'PRODUCT_NOT_SELLABLE',
            'message': 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
          }),
        ),
      );
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.finalize(_command()),
        throwsA(
          isA<SalesContractException>()
              .having((error) => error.code, 'code', 'PRODUCT_NOT_SELLABLE')
              .having(
                (error) => error.message,
                'message',
                'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
              ),
        ),
      );
    });

    test('S12 finalize maps malformed result to DEPENDENCY_UNAVAILABLE', () async {
      final rpc = _FakeRpcClient(response: {'status': 'not-a-real-status'});
      final gateway = SupabaseCheckoutGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.finalize(_command()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'DEPENDENCY_UNAVAILABLE',
          ),
        ),
      );
    });

    test('S12 finalize timeout becomes UNCERTAIN_RESULT', () async {
      final gateway = SupabaseCheckoutGateway(
        rpcClient: _FakeRpcClient(error: TimeoutException('late response')),
      );

      await expectLater(
        () => gateway.finalize(_command()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'UNCERTAIN_RESULT',
          ),
        ),
      );
    });
  });
}

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.response = const <String, dynamic>{}, this.error});

  final Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;

  @override
  Future<Map<String, dynamic>> call(
    String procedure, {
    Map<String, dynamic>? params,
  }) async {
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}

PrecheckSalesOrderCheckoutQuery _query() {
  return PrecheckSalesOrderCheckoutQuery(
    id: 'query-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    customerId: 'customer-1',
    currencyCode: 'VND',
    lines: const <CheckoutLineInput>[
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
    paymentIntents: const <PaymentIntentInput>[],
  );
}

FinalizeSalesOrderCommand _command() {
  return FinalizeSalesOrderCommand(
    id: 'cmd-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    sourceDraftId: 'draft-1',
    customerId: 'customer-1',
    currencyCode: 'VND',
    orderNote: ' Giao sau 17:00 ',
    lines: const <CheckoutLineInput>[
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
    paymentIntents: const <PaymentIntentInput>[
      PaymentIntentInput(
        method: SalesPaymentMethod.cash,
        amount: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
    commercialSnapshot: _commercialSnapshot(),
    idempotencyKey: 'idem-1',
    payloadHash: 'hash-1',
    correlationId: 'corr-1',
  );
}

SalesCommercialSnapshotInput _commercialSnapshot() => SalesCommercialSnapshotInput(
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Nguyễn Văn An',
  ),
  lines: const [
    SalesReceiptLineDto(
      lineId: 'line-1',
      product: ProductSnapshotDto(
        productId: 'product-1',
        sku: null,
        displayName: 'Vaccine A',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-1',
        unitCode: null,
        unitName: 'Lọ',
      ),
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
  ],
);

GetCheckoutResultQuery _statusQuery() {
  return GetCheckoutResultQuery(
    storeId: 'store-1',
id: 'query-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    idempotencyKey: 'attempt-1',
  );
}
