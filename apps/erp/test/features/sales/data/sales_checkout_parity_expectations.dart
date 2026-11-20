
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

const checkoutTenantId = 'tenant-1';
const checkoutActorId = 'user-1';
const checkoutStoreId = 'store-1';
const checkoutQueryId = '00000000-0000-4000-8000-000000000001';
const checkoutCommandId = '00000000-0000-4000-8000-000000000002';
const checkoutCurrencyRaw = ' vnd ';

List<CheckoutLineInput> checkoutLines() => const [
  CheckoutLineInput(
    productId: 'product-1',
    productUnitId: 'unit-1',
    quantity: QuantityDto(quantityMicros: 2000000),
    manualUnitPriceMinor: 90000,
    note: 'n1',
  ),
  CheckoutLineInput(
    productId: 'product-2',
    productUnitId: 'unit-2',
    quantity: QuantityDto(quantityMicros: 1000000),
    unitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
    manualDiscountBasisPoints: 1000,
  ),
];

List<PaymentIntentInput> checkoutIntents() => const [
  PaymentIntentInput(
    method: SalesPaymentMethod.cash,
    amount: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  ),
  PaymentIntentInput(
    method: SalesPaymentMethod.manualBankTransfer,
    amount: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
    reference: 'FT123',
  ),
];

SalesCommercialSnapshotInput checkoutSnapshot({bool withCustomer = true}) =>
    SalesCommercialSnapshotInput(
      store: const StoreSnapshotDto(storeId: 'store-1', storeCode: 'HCM-01', displayName: 'Q1'),
      seller: const ActorSnapshotDto(actorId: 'user-1', displayName: 'Minh Anh'),
      customer: withCustomer
          ? const CustomerSnapshotDto(
              customerId: 'customer-1',
              displayName: ' Nguyễn An ',
              phoneNumber: '0903000000',
              taxCode: '0312345678',
              invoiceEmail: 'an@example.com',
            )
          : null,
      lines: const [
        SalesReceiptLineDto(
          lineId: 'line-1',
          product: ProductSnapshotDto(
            productId: 'product-1',
            sku: 'SKU1',
            displayName: 'Vaccine A',
          ),
          unit: ProductUnitSnapshotDto(productUnitId: 'unit-1', unitCode: 'LO', unitName: 'Lọ'),
          quantity: QuantityDto(quantityMicros: 2000000),
          unitPrice: MoneyDto(amountMinor: 90000, currencyCode: 'vnd'),
          discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          lineTotal: MoneyDto(amountMinor: 180000, currencyCode: 'VND'),
        ),
      ],
    );

final expectedLineParams = <Map<String, dynamic>>[
  {
    'product_id': 'product-1',
    'product_unit_id': 'unit-1',
    'quantity_micros': 2000000,
    'unit_price': null,
    'manual_unit_price_minor': 90000,
    'manual_discount_minor': null,
    'manual_discount_basis_points': null,
    'note': 'n1',
  },
  {
    'product_id': 'product-2',
    'product_unit_id': 'unit-2',
    'quantity_micros': 1000000,
    'unit_price': {'amount_minor': 50000, 'currency_code': 'VND'},
    'manual_unit_price_minor': null,
    'manual_discount_minor': null,
    'manual_discount_basis_points': 1000,
    'note': null,
  },
];

final expectedIntentParams = <Map<String, dynamic>>[
  {
    'method': 'cash',
    'amount': {'amount_minor': 100000, 'currency_code': 'VND'},
    'reference': null,
  },
  {
    'method': 'manualBankTransfer',
    'amount': {'amount_minor': 50000, 'currency_code': 'VND'},
    'reference': 'FT123',
  },
];

Map<String, dynamic> expectedPrecheckParams({int? expectedVersion = 4}) => {
  'p_query_id': checkoutQueryId,
  'p_tenant_id': checkoutTenantId,
  'p_actor_id': checkoutActorId,
  'p_store_id': checkoutStoreId,
  'p_customer_id': 'customer-1',
  'p_currency_code': 'VND',
  'p_payment_due_date': '2026-11-09',
  'p_lines': expectedLineParams,
  'p_payment_intents': expectedIntentParams,
  'p_expected_source_version': ?expectedVersion,
};

Map<String, dynamic> expectedFinalizeParams() => {
  'p_command_id': checkoutCommandId,
  'p_tenant_id': checkoutTenantId,
  'p_actor_id': checkoutActorId,
  'p_store_id': checkoutStoreId,
  'p_source_draft_id': 'draft-7',
  'p_customer_id': 'customer-1',
  'p_currency_code': 'VND',
  'p_order_note': ' Giao chiều ',
  'p_payment_due_date': '2026-11-09',
  'p_commercial_snapshot': {
    'store': {'storeId': 'store-1', 'storeCode': 'HCM-01', 'displayName': 'Q1'},
    'seller': {'actorId': 'user-1', 'displayName': 'Minh Anh'},
    'customer': {
      'customerId': 'customer-1',
      'displayName': 'Nguyễn An',
      'phoneNumber': '0903000000',
      'taxCode': '0312345678',
      'buyerType': null,
      'invoiceLegalName': null,
      'invoiceAddress': null,
      'invoiceEmail': 'an@example.com',
    },
    'lines': [
      {
        'lineId': 'line-1',
        'product': {'productId': 'product-1', 'sku': 'SKU1', 'displayName': 'Vaccine A'},
        'unit': {'productUnitId': 'unit-1', 'unitCode': 'LO', 'unitName': 'Lọ'},
        'quantityMicros': 2000000,
        'unitPrice': {'amountMinor': 90000, 'currencyCode': 'VND'},
        'discountTotal': {'amountMinor': 0, 'currencyCode': 'VND'},
        'lineTotal': {'amountMinor': 180000, 'currencyCode': 'VND'},
      },
    ],
  },
  'p_lines': expectedLineParams,
  'p_payment_intents': expectedIntentParams,
  'p_idempotency_key': 'checkout:attempt-1',
  'p_payload_hash': 'hash-1',
  'p_correlation_id': 'corr-1',
  'p_causation_id': null,
  'p_expected_source_version': 4,
};

Map<String, dynamic> expectedStatusParams() => {
  'p_query_id': checkoutQueryId,
  'p_tenant_id': checkoutTenantId,
  'p_actor_id': checkoutActorId,
  'p_idempotency_key': 'checkout:attempt-1',
  'p_store_id': checkoutStoreId,
};

Map<String, dynamic> precheckJson() => {
  'canFinalize': false,
  'blockers': [
    {'code': 'PRICE_CHANGED', 'message': 'Retry.', 'field': null},
  ],
  'monetarySummary': {
    'subtotal': {'amountMinor': 230000, 'currencyCode': 'VND'},
    'discountTotal': {'amountMinor': 5000, 'currencyCode': 'VND'},
    'grandTotal': {'amountMinor': 225000, 'currencyCode': 'VND'},
  },
  'receivableRequirement': {
    'isRequired': true,
    'amount': {'amountMinor': 75000, 'currencyCode': 'VND'},
    'customerId': 'customer-1',
  },
};

void expectPrecheck(CheckoutPrecheckDto dto) {
  expect(dto.canFinalize, isFalse);
  expect(dto.blockers.single.code, 'PRICE_CHANGED');
  expect(dto.monetarySummary.grandTotal.amountMinor, 225000);
  expect(dto.receivableRequirement.isRequired, isTrue);
  expect(dto.receivableRequirement.amount.amountMinor, 75000);
  expect(dto.receivableRequirement.customerId, 'customer-1');
}

Map<String, dynamic> checkoutResultJson(
  String status, {
  String? blockedCode,
  String? blockedMessage,
}) => {
  'idempotencyKey': 'checkout:attempt-1',
  'salesOrderId': status == 'succeeded' ? 'order-1' : '',
  'salesOrderVersion': status == 'succeeded' ? 1 : 0,
  'status': status,
  'blockedCode': ?blockedCode,
  'blockedMessage': ?blockedMessage,
};

const checkoutStatuses = {
  'processing': CheckoutResultStatus.processing,
  'succeeded': CheckoutResultStatus.succeeded,
  'blocked': CheckoutResultStatus.blocked,
  'failed': CheckoutResultStatus.failed,
  'uncertain': CheckoutResultStatus.uncertain,
};

void expectCheckoutResult(CheckoutResultDto dto, String status) {
  expect(dto.status, checkoutStatuses[status]);
  expect(dto.idempotencyKey, 'checkout:attempt-1');
  expect(dto.salesOrderId, status == 'succeeded' ? 'order-1' : '');
}

// ----- payment / order -----

Map<String, dynamic> _m(int v) => {'amountMinor': v, 'currencyCode': 'VND'};

Map<String, dynamic> orderResultJson() => {
  'order': {
    'salesOrderId': 'order-1',
    'orderNumber': 'SO-001',
    'version': 3,
    'lifecycleStatus': 'completed',
    'lockStatus': 'unlocked',
    'total': _m(1000000),
  },
  'committedAt': '2026-08-12T02:41:00Z',
  'store': {'storeId': 'store-1', 'storeCode': 'HCM-01', 'displayName': 'Q1'},
  'seller': {'actorId': 'user-1', 'displayName': 'Minh Anh'},
  'customer': {
    'customerId': 'customer-1',
    'displayName': 'Nguyen Van An',
    'phoneNumber': '0903000000',
    'existingDebtMinor': 5000,
  },
};

void expectOrderResult(SalesOrderResultDto dto) {
  expect(dto.order.salesOrderId, 'order-1');
  expect(dto.order.version, 3);
  expect(dto.order.lifecycleStatus, SalesOrderLifecycleStatus.completed);
  expect(dto.order.lockStatus, SalesOrderLockStatus.unlocked);
  expect(dto.committedAt, DateTime.utc(2026, 8, 12, 2, 41));
  expect(dto.store.storeCode, 'HCM-01');
  expect(dto.seller.displayName, 'Minh Anh');
  expect(dto.customer?.existingDebtMinor, 5000);
}

Map<String, dynamic> summaryJson() => {
  'status': 'partiallyPaid',
  'orderTotal': _m(1000000),
  'paidTotal': _m(400000),
  'refundedTotal': _m(0),
  'netCollectedTotal': _m(400000),
  'originalPayableTotal': _m(1000000),
  'adjustmentTotal': _m(0),
  'collectedCash': _m(300000),
  'collectedBank': _m(100000),
  'outstandingTotal': _m(600000),
  'dueAt': '2026-11-09',
  'originalOrder': {
    'orderTotal': _m(1000000),
    'paidCash': _m(300000),
    'paidBank': _m(100000),
    'outstanding': _m(600000),
  },
  'returnSlips': [
    {'slipNumber': 'RT-1', 'customerPaysExtra': _m(10000), 'paidCashExtra': _m(10000)},
  ],
};

void expectSummary(SalesOrderPaymentSummaryDto dto) {
  expect(dto.status, SalesSettlementStatus.partiallyPaid);
  expect(dto.outstandingTotal.amountMinor, 600000);
  expect(dto.collectedCash?.amountMinor, 300000);
  expect(dto.collectedBank?.amountMinor, 100000);
  expect(dto.dueAt, DateTime.utc(2026, 11, 9));
  expect(dto.originalOrder?.paidCash.amountMinor, 300000);
  expect(dto.returnSlips.single.slipNumber, 'RT-1');
  expect(dto.returnSlips.single.paidCashExtra?.amountMinor, 10000);
  expect(dto.returnSlips.single.paidBankExtra, isNull);
}

Map<String, dynamic> settlementJson() => {
  'settlementId': 'settlement-1',
  'salesOrderId': 'order-1',
  'version': 3,
  'status': 'partiallyPaid',
  'orderTotal': _m(1000000),
  'paidTotal': _m(400000),
  'refundedTotal': _m(50000),
  'outstanding': _m(650000),
  'dueAt': '2026-08-30T00:00:00.000Z',
};

void expectSettlement(SalesOrderSettlementDto dto) {
  expect(dto.settlementId, 'settlement-1');
  expect(dto.version, 3);
  expect(dto.paidTotal.amountMinor, 400000);
  expect(dto.refundedTotal.amountMinor, 50000);
  expect(dto.outstanding.amountMinor, 650000);
  expect(dto.dueAt, DateTime.parse('2026-08-30T00:00:00.000Z'));
}

Map<String, dynamic> transactionsJson() => {
  'items': [
    {
      'transactionId': 'txn-1',
      'method': 'cash',
      'amount': _m(300000),
      'status': 'confirmed',
      'recordedAt': '2026-08-12T02:41:00Z',
      'transactionType': 'collection',
      'direction': 'inflow',
      'relatedTransactionId': null,
      'sourceContext': 'checkout',
      'actorId': 'user-1',
    },
    {
      'transactionId': 'txn-2',
      'method': 'manualBankTransfer',
      'amount': _m(50000),
      'status': 'voided',
      'recordedAt': '2026-08-13T02:41:00Z',
      'transactionType': 'refund',
      'direction': 'outflow',
      'relatedTransactionId': 'txn-1',
      'reasonCode': 'R1',
      'reason': 'sai',
    },
  ],
  'hasMore': true,
  'nextCursor': 'cur-2',
};

void expectTransactions(SalesPaymentTransactionsDto dto) {
  final items = dto.page.items;
  expect(items, hasLength(2));
  expect(items[0].method, SalesPaymentMethod.cash);
  expect(items[0].transactionType, SalesPaymentTransactionType.collection);
  expect(items[0].direction, SalesPaymentDirection.inflow);
  expect(items[0].sourceContext, 'checkout');
  expect(items[1].status, SalesPaymentStatus.voided);
  expect(items[1].transactionType, SalesPaymentTransactionType.refund);
  expect(items[1].relatedTransactionId, 'txn-1');
  expect(items[1].reason, 'sai');
  expect(dto.page.hasMore, isTrue);
  expect(dto.page.nextCursor, 'cur-2');
}

Map<String, dynamic> expectedSummaryParams({int? version}) => {
  'p_query_id': checkoutQueryId,
  'p_tenant_id': checkoutTenantId,
  'p_actor_id': checkoutActorId,
  'p_sales_order_id': 'order-1',
  'p_expected_source_version': ?version,
};

Map<String, dynamic> expectedSettlementParams() => {
  'query_id': checkoutQueryId,
  'tenant_id': checkoutTenantId,
  'actor_id': checkoutActorId,
  'sales_order_id': 'order-1',
  'expected_source_version': 7,
};

Map<String, dynamic> expectedTransactionsParams() => {
  ...expectedSettlementParams(),
  'cursor': 'cur-1',
  'page_size': 10,
};

Map<String, dynamic> expectedGetOrderParams() => {
  'p_query_id': checkoutQueryId,
  'p_tenant_id': checkoutTenantId,
  'p_actor_id': checkoutActorId,
  'p_sales_order_id': 'order-1',
};
