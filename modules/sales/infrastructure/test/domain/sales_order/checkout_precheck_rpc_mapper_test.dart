import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_order/checkout_precheck_rpc_mapper.dart';

void main() {
  group('CheckoutPrecheckRpcMapper', () {
    test('precheck params match frozen S08-S11 RPC contract', () {
      final params = CheckoutPrecheckRpcMapper.precheckParams(_query());

      expect(params['p_query_id'], 'query-1');
      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'actor-1');
      expect(params['p_store_id'], 'store-1');
      expect(params['p_customer_id'], 'customer-1');
      expect(params['p_currency_code'], 'VND');
      expect(params['p_payment_due_date'], '2026-08-30');
      expect(params['p_expected_source_version'], 7);
      expect(params['p_lines'], isA<List<Map<String, dynamic>>>());
      expect((params['p_lines'] as List).single['product_id'], 'product-1');
      expect((params['p_lines'] as List).single['unit_price']['amount_minor'], 1000000);
      expect(params['p_payment_intents'], isA<List<Map<String, dynamic>>>());
      expect((params['p_payment_intents'] as List).single['method'], 'cash');
      expect((params['p_payment_intents'] as List).single['amount']['currency_code'], 'VND');
      expect(params, isNot(contains('query_id')));
    });

    test('finalize and status params use exact p-prefixed contracts', () {
      final params = CheckoutPrecheckRpcMapper.finalizeParams(_command());

      expect(params['p_command_id'], 'attempt-1');
      expect(params['p_source_draft_id'], 'draft-7');
      expect(params['p_customer_id'], 'customer-2');
      expect(params['p_order_note'], ' Giao chiều ');
      expect(params['p_payment_due_date'], '2026-08-30');
      expect(params['p_expected_source_version'], 3);
      expect(params['p_commercial_snapshot'], <String, Object?>{
        'store': <String, Object?>{
          'storeId': 'store-1',
          'storeCode': 'HCM-01',
          'displayName': 'Chi nhánh Quận 1',
        },
        'seller': <String, Object?>{
          'actorId': 'actor-1',
          'displayName': 'Minh Anh',
        },
        'customer': <String, Object?>{
          'customerId': 'customer-2',
          'displayName': 'Nguyễn Văn An',
          'phoneNumber': '0903000000',
          'taxCode': null,
          'buyerType': null,
          'invoiceLegalName': null,
          'invoiceAddress': null,
          'invoiceEmail': null,
        },
        'lines': <Object?>[
          <String, Object?>{
            'lineId': 'line-1',
            'product': <String, Object?>{
              'productId': 'product-1',
              'sku': null,
              'displayName': 'Vaccine A',
            },
            'unit': <String, Object?>{
              'productUnitId': 'unit-1',
              'unitCode': null,
              'unitName': 'Lọ',
            },
            'quantityMicros': QuantityDto.scale,
            'unitPrice': <String, Object?>{'amountMinor': 100000, 'currencyCode': 'VND'},
            'discountTotal': <String, Object?>{'amountMinor': 0, 'currencyCode': 'VND'},
            'lineTotal': <String, Object?>{'amountMinor': 100000, 'currencyCode': 'VND'},
          },
        ],
      });
      expect(params, isNot(contains('command_id')));
      expect(params, isNot(contains('customer_id')));

      final status = CheckoutPrecheckRpcMapper.statusParams(
        GetCheckoutResultQuery(
          storeId: 'store-1',
          id: 'status-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          idempotencyKey: 'attempt-1',
        ),
      );
      expect(status['p_query_id'], 'status-1');
      expect(status['p_tenant_id'], 'tenant-1');
      expect(status['p_actor_id'], 'actor-1');
      expect(status['p_idempotency_key'], 'attempt-1');
      expect(status, isNot(contains('query_id')));
    });

    test('precheck response maps to CheckoutPrecheckDto', () {
      final dto = CheckoutPrecheckRpcMapper.precheckFromJson({
        'canFinalize': false,
        'blockers': [
          {'code': 'DEPENDENCY_UNAVAILABLE', 'message': 'Retry later.', 'field': null},
        ],
        'monetarySummary': {
          'subtotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
          'discountTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
          'grandTotal': {'amountMinor': 1000000, 'currencyCode': 'VND'},
        },
        'receivableRequirement': {
          'isRequired': true,
          'amount': {'amountMinor': 600000, 'currencyCode': 'VND'},
          'customerId': 'customer-1',
        },
      });

      expect(dto.canFinalize, isFalse);
      expect(dto.blockers.single.code, 'DEPENDENCY_UNAVAILABLE');
      expect(dto.monetarySummary.grandTotal.amountMinor, 1000000);
      expect(dto.receivableRequirement.amount.amountMinor, 600000);
    });
  });
}

FinalizeSalesOrderCommand _command() {
  return FinalizeSalesOrderCommand(
    id: 'attempt-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    sourceDraftId: 'draft-7',
    customerId: 'customer-2',
    currencyCode: 'VND',
    orderNote: ' Giao chiều ',
    paymentDueDate: DateTime(2026, 8, 30, 16),
    lines: const <CheckoutLineInput>[
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      ),
    ],
    paymentIntents: const <PaymentIntentInput>[],
    idempotencyKey: 'checkout:attempt-1',
    payloadHash: 'hash-1',
    correlationId: 'corr-1',
    expectedSourceVersion: 3,
    commercialSnapshot: _commercialSnapshot(),
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
    customerId: 'customer-2',
    displayName: 'Nguyễn Văn An',
    phoneNumber: '0903000000',
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
      unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    ),
  ],
);

PrecheckSalesOrderCheckoutQuery _query() {
  return PrecheckSalesOrderCheckoutQuery(
    id: 'query-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    customerId: 'customer-1',
    currencyCode: 'vnd',
    paymentDueDate: DateTime(2026, 8, 30, 9),
    expectedSourceVersion: 7,
    lines: const <CheckoutLineInput>[
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        note: 'note',
      ),
    ],
    paymentIntents: const <PaymentIntentInput>[
      PaymentIntentInput(
        method: SalesPaymentMethod.cash,
        amount: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
      ),
    ],
  );
}
