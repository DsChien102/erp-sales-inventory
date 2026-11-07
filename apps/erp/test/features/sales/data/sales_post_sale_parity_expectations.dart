// ignore_for_file: use_null_aware_elements

import 'package:erp/features/sales/data/models.dart';

const parityTenantId = 'tenant-1';
const parityActorId = 'user-1';
const parityOrderId = 'order-1';
const parityReturnExchangeId = 're-1';
const parityQueryId = '00000000-0000-4000-8000-000000000001';
const parityCommandId = '00000000-0000-4000-8000-000000000002';
const parityCorrelationId = 'corr-1';

// Expected hashes established in Task 0.3 via original attempt factories
const expectedCancelHash = 'a00aa48869d779491d95d79d1bc542d8d3f5df88642ce3797003e795927dbbb6';
const expectedStartHash = '82242892ca73c26f6fe046ef2bb7b26bb496467764d6b827817c584a5ae4084c';
const expectedConfirmHash = '1f610d6d1c2bb5d57011d008b9cd051d10160f8d0b01180d3649bf8b08ca7d12';

final sampleParityLines = <ReturnExchangeLineInput>[
  const ReturnExchangeLineInput(
    kind: ReturnExchangeLineKind.returnLine,
    productId: 'product-return-1',
    productUnitId: 'unit-return-1',
    quantity: QuantityDto(quantityMicros: QuantityDto.scale),
    originalSalesOrderLineId: 'line-1',
    reasonCode: 'DAMAGED',
    conditionCode: 'OPENED',
  ),
  const ReturnExchangeLineInput(
    kind: ReturnExchangeLineKind.exchangeLine,
    productId: 'product-ex-full',
    productUnitId: 'unit-ex-full',
    quantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
    exchangeProductSnapshot: ProductSnapshotDto(
      productId: 'product-ex-full',
      sku: 'SKU-EX-FULL',
      displayName: 'Exchange Product Full',
    ),
    exchangeUnitSnapshot: ProductUnitSnapshotDto(
      productUnitId: 'unit-ex-full',
      unitCode: 'BOX',
      unitName: 'Hộp',
    ),
    exchangeUnitPrice: MoneyDto(
      amountMinor: 50000,
      currencyCode: 'VND',
    ),
  ),
  const ReturnExchangeLineInput(
    kind: ReturnExchangeLineKind.exchangeLine,
    productId: 'product-ex-missing',
    productUnitId: 'unit-ex-missing',
    quantity: QuantityDto(quantityMicros: QuantityDto.scale),
    exchangeProductSnapshot: null,
    exchangeUnitSnapshot: null,
    exchangeUnitPrice: null,
  ),
];

final samplePricingLines = <ReturnExchangePricingLineInput>[
  const ReturnExchangePricingLineInput(
    productId: 'product-ex-full',
    productUnitId: 'unit-ex-full',
  ),
  const ReturnExchangePricingLineInput(
    productId: 'product-ex-missing',
    productUnitId: 'unit-ex-missing',
  ),
];

Map<String, dynamic> expectedCancelPrecheckParams({
  String queryId = parityQueryId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String salesOrderId = parityOrderId,
  int expectedSourceVersion = 7,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'sales_order_id': salesOrderId,
  'expected_source_version': expectedSourceVersion,
};

Map<String, dynamic> expectedCancelConfirmParams({
  String commandId = parityCommandId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String salesOrderId = parityOrderId,
  String reasonText = 'Khách yêu cầu huỷ',
  String idempotencyKey = 'sales-order-cancellation:$parityCommandId',
  String payloadHash = expectedCancelHash,
  String correlationId = parityCorrelationId,
  dynamic causationId,
  int expectedOrderVersion = 7,
  int expectedSettlementVersion = 3,
}) => <String, dynamic>{
  'command_id': commandId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'sales_order_id': salesOrderId,
  'reason_text': reasonText,
  'idempotency_key': idempotencyKey,
  'payload_hash': payloadHash,
  'correlation_id': correlationId,
  'causation_id': causationId,
  'expected_order_version': expectedOrderVersion,
  'expected_settlement_version': expectedSettlementVersion,
};

Map<String, dynamic> expectedReturnExchangePrecheckParams({
  String queryId = parityQueryId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String salesOrderId = parityOrderId,
  int? expectedSourceVersion = 7,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'sales_order_id': salesOrderId,
  'expected_source_version': expectedSourceVersion,
};

Map<String, dynamic> expectedReturnableParams({
  String queryId = parityQueryId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String salesOrderId = parityOrderId,
  int? expectedSourceVersion,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'sales_order_id': salesOrderId,
  'expected_source_version': expectedSourceVersion,
};

Map<String, dynamic> expectedPreviewPricingParams({
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String salesOrderId = parityOrderId,
  List<ReturnExchangePricingLineInput>? lines,
}) => <String, dynamic>{
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_sales_order_id': salesOrderId,
  'p_lines': [
    for (final line in lines ?? samplePricingLines)
      <String, dynamic>{
        'product_id': line.productId,
        'product_unit_id': line.productUnitId,
      },
  ],
};

Map<String, dynamic> expectedReturnExchangeDetailParams({
  String queryId = parityQueryId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String returnExchangeId = parityReturnExchangeId,
  int? expectedVersion,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'return_exchange_id': returnExchangeId,
  'expected_version': expectedVersion,
};

Map<String, dynamic> expectedStartParams({
  String commandId = parityCommandId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String salesOrderId = parityOrderId,
  String entrySource = 'standard',
  required List<Map<String, dynamic>> lines,
  String idempotencyKey = 'return-exchange:start:$parityCommandId',
  String payloadHash = expectedStartHash,
  String correlationId = parityCorrelationId,
  dynamic causationId,
  int expectedSourceVersion = 7,
  required Map<String, dynamic> referenceDecision,
}) => <String, dynamic>{
  'command_id': commandId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'sales_order_id': salesOrderId,
  'entry_source': entrySource,
  'lines': lines,
  'idempotency_key': idempotencyKey,
  'payload_hash': payloadHash,
  'correlation_id': correlationId,
  'causation_id': causationId,
  'expected_source_version': expectedSourceVersion,
  'reference_decision': referenceDecision,
};

Map<String, dynamic> expectedUpdateParams({
  String commandId = parityCommandId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String returnExchangeId = parityReturnExchangeId,
  required List<Map<String, dynamic>> lines,
  String idempotencyKey = 'return-exchange:update:$parityCommandId',
  required String payloadHash,
  String correlationId = parityCorrelationId,
  dynamic causationId,
  int expectedVersion = 3,
  required Map<String, dynamic> referenceDecision,
}) => <String, dynamic>{
  'command_id': commandId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'return_exchange_id': returnExchangeId,
  'lines': lines,
  'idempotency_key': idempotencyKey,
  'payload_hash': payloadHash,
  'correlation_id': correlationId,
  'causation_id': causationId,
  'expected_version': expectedVersion,
  'reference_decision': referenceDecision,
};

Map<String, dynamic> expectedCancelReturnExchangeParams({
  String commandId = parityCommandId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String returnExchangeId = parityReturnExchangeId,
  String idempotencyKey = 'return-exchange:discard:$parityCommandId',
  required String payloadHash,
  String correlationId = parityCorrelationId,
  dynamic causationId,
  int? expectedVersion = 3,
}) => <String, dynamic>{
  'command_id': commandId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'return_exchange_id': returnExchangeId,
  'idempotency_key': idempotencyKey,
  'payload_hash': payloadHash,
  'correlation_id': correlationId,
  'causation_id': causationId,
  'expected_version': expectedVersion,
};

Map<String, dynamic> expectedConfirmReturnExchangeParams({
  String commandId = parityCommandId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String returnExchangeId = parityReturnExchangeId,
  String idempotencyKey = 'return-exchange:confirm:$parityCommandId',
  String payloadHash = expectedConfirmHash,
  String correlationId = parityCorrelationId,
  dynamic causationId,
  int expectedVersion = 4,
  required Map<String, dynamic> referenceDecision,
  int? settledNowMinor = 100000,
  String paymentMethod = 'cash',
  String? paymentDueDate = '2026-11-20',
}) => <String, dynamic>{
  'command_id': commandId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'return_exchange_id': returnExchangeId,
  'idempotency_key': idempotencyKey,
  'payload_hash': payloadHash,
  'correlation_id': correlationId,
  'causation_id': causationId,
  'expected_version': expectedVersion,
  'reference_decision': referenceDecision,
  'payment_settled_now_minor': settledNowMinor,
  'payment_method': paymentMethod,
  'payment_due_date': paymentDueDate,
};

Map<String, dynamic> expectedCompleteReturnExchangeParams({
  String commandId = parityCommandId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String returnExchangeId = parityReturnExchangeId,
  String idempotencyKey = 'return-exchange:complete:$parityCommandId',
  required String payloadHash,
  String correlationId = parityCorrelationId,
  dynamic causationId,
  int? expectedVersion = 5,
}) => <String, dynamic>{
  'command_id': commandId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'return_exchange_id': returnExchangeId,
  'idempotency_key': idempotencyKey,
  'payload_hash': payloadHash,
  'correlation_id': correlationId,
  'causation_id': causationId,
  'expected_version': expectedVersion,
};

Map<String, dynamic> expectedEvaluateParams({
  String queryId = parityQueryId,
  String tenantId = parityTenantId,
  String actorId = parityActorId,
  String returnExchangeId = parityReturnExchangeId,
  int expectedSourceVersion = 7,
  required Map<String, dynamic> referenceDecision,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'return_exchange_id': returnExchangeId,
  'expected_source_version': expectedSourceVersion,
  'reference_decision': referenceDecision,
};

Map<String, dynamic> expectedReferenceDecision() => <String, dynamic>{
  'blockers': <dynamic>[],
  'exchange_products_by_product_unit_id': <String, dynamic>{
    'unit-ex-full': <String, dynamic>{
      'productId': 'product-ex-full',
      'sku': 'SKU-EX-FULL',
      'displayName': 'Exchange Product Full',
    },
    'unit-ex-missing': <String, dynamic>{
      'productId': 'product-ex-missing',
      'sku': null,
      'displayName': 'product-ex-missing',
    },
  },
  'exchange_units_by_product_unit_id': <String, dynamic>{
    'unit-ex-full': <String, dynamic>{
      'productUnitId': 'unit-ex-full',
      'unitCode': 'BOX',
      'unitName': 'Hộp',
    },
    'unit-ex-missing': <String, dynamic>{
      'productUnitId': 'unit-ex-missing',
      'unitCode': null,
      'unitName': 'unit-ex-missing',
    },
  },
  'exchange_prices_by_product_unit_id': <String, dynamic>{
    'unit-ex-full': <String, dynamic>{
      'amountMinor': 50000,
      'currencyCode': 'VND',
    },
    'unit-ex-missing': <String, dynamic>{
      'amountMinor': 0,
      'currencyCode': 'VND',
    },
  },
  'pricing_source_version': null,
  'inventory_source_version': null,
};

Map<String, dynamic> sampleCancelPrecheckJson({bool allowed = true}) => <String, dynamic>{
  'allowed': allowed,
  'sourceVersion': 7,
  'sourceSettlementVersion': 3,
  'blockers': allowed
      ? <Object?>[]
      : <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'PAYMENT_ALREADY_COLLECTED',
            'message': 'Net confirmed collection must be zero.',
            'field': 'settlement',
          },
        ],
};

Map<String, dynamic> sampleCancelResultJson({String status = 'confirmed'}) => <String, dynamic>{
  'cancellationId': 'cancellation-1',
  'salesOrderId': parityOrderId,
  'salesOrderVersion': 8,
  'status': status,
};

Map<String, dynamic> sampleReturnExchangePrecheckJson({bool allowed = true}) => <String, dynamic>{
  'allowed': allowed,
  'sourceVersion': 7,
  'blockers': allowed
      ? <Object?>[]
      : <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'ORDER_ALREADY_CANCELLED',
            'message': 'Sales order is cancelled.',
            'field': 'order',
          },
        ],
};

Map<String, dynamic> sampleReturnableOrderLinesJson() => <String, dynamic>{
  'salesOrderId': parityOrderId,
  'sourceVersion': 7,
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'salesOrderLineId': 'line-1',
      'product': <String, dynamic>{
        'productId': 'product-return-1',
        'sku': 'SKU-RET-1',
        'displayName': 'Product Ret 1',
      },
      'unit': <String, dynamic>{
        'productUnitId': 'unit-return-1',
        'unitCode': 'BOX',
        'unitName': 'Box',
      },
      'soldQuantity': <String, dynamic>{'quantityMicros': 2000000},
      'returnableQuantity': <String, dynamic>{'quantityMicros': 1000000},
      'originalUnitPrice': <String, dynamic>{
        'amountMinor': 50000,
        'currencyCode': 'VND',
      },
    },
  ],
};

Map<String, dynamic> samplePreviewPricingJson() => <String, dynamic>{
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'productUnitId': 'unit-ex-full',
      'unitPrice': <String, dynamic>{
        'amountMinor': 60000,
        'currencyCode': 'VND',
      },
      'sourceCode': 'BASE_PRICE',
      'warningCodes': <String>[],
    },
  ],
};

Map<String, dynamic> sampleDraftJson() => <String, dynamic>{
  'returnExchangeId': parityReturnExchangeId,
  'salesOrderId': parityOrderId,
  'version': 1,
  'status': 'draft',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'kind': 'returnLine',
      'productId': 'product-return-1',
      'productUnitId': 'unit-return-1',
      'quantity': <String, dynamic>{'quantityMicros': 1000000},
      'originalSalesOrderLineId': 'line-1',
      'reasonCode': 'DAMAGED',
      'conditionCode': 'OPENED',
      'lineSnapshot': null,
    },
  ],
};

Map<String, dynamic> sampleReturnExchangeResultJson({String status = 'confirmed'}) =>
    <String, dynamic>{
      'returnExchangeId': parityReturnExchangeId,
      'salesOrderId': parityOrderId,
      'version': 4,
      'status': status,
    };

Map<String, dynamic> sampleValuationJson() => <String, dynamic>{
  'returnValue': <String, dynamic>{'amountMinor': 50000, 'currencyCode': 'VND'},
  'exchangeValue': <String, dynamic>{'amountMinor': 120000, 'currencyCode': 'VND'},
  'settlementDifference': <String, dynamic>{'amountMinor': 70000, 'currencyCode': 'VND'},
  'settlementPlan': <String, dynamic>{
    'currencyCode': 'VND',
    'netDifferenceMinor': 70000,
    'collectAmountMinor': 70000,
    'refundAmountMinor': 0,
    'receivableCreateAmountMinor': 0,
    'receivableReverseAmountMinor': 0,
    'processedCollectMinor': 0,
    'processedRefundMinor': 0,
    'pendingReceivableCreateMinor': 0,
    'pendingReceivableReverseMinor': 0,
    'remainderCollectMinor': 70000,
    'remainderRefundMinor': 0,
    'sourceOrderVersion': 7,
    'sourceSettlementVersion': 3,
  },
  'sourceOrderVersion': 7,
};

Map<String, dynamic> sampleWrappedDetailJson() => <String, dynamic>{
  'result': sampleReturnExchangeResultJson(),
  'referenceNumber': 'RE-2026-0001',
  'entrySource': 'standard',
  'createdAt': '2026-11-01T10:00:00.000Z',
  'confirmedByActorId': parityActorId,
  'confirmedAt': '2026-11-01T10:05:00.000Z',
  'completedAt': null,
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'kind': 'returnLine',
      'productId': 'product-return-1',
      'productUnitId': 'unit-return-1',
      'quantity': <String, dynamic>{'quantityMicros': 1000000},
      'originalSalesOrderLineId': 'line-1',
      'reasonCode': 'DAMAGED',
      'conditionCode': 'OPENED',
      'lineSnapshot': null,
    },
  ],
  'valuation': sampleValuationJson(),
  'settlementPlan': sampleValuationJson()['settlementPlan'],
  'completionReady': false,
};

Map<String, dynamic> sampleLiveDetailJson() => <String, dynamic>{
  'returnExchangeId': parityReturnExchangeId,
  'salesOrderId': parityOrderId,
  'version': 4,
  'status': 'confirmed',
  'referenceNumber': 'RE-2026-0001',
  'entrySource': 'standard',
  'createdAt': '2026-11-01T10:00:00.000Z',
  'confirmedAt': '2026-11-01T10:05:00.000Z',
  'completedAt': null,
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'kind': 'returnLine',
      'productId': 'product-return-1',
      'productUnitId': 'unit-return-1',
      'quantity': <String, dynamic>{'quantityMicros': 1000000},
      'originalSalesOrderLineId': 'line-1',
      'reasonCode': 'DAMAGED',
      'conditionCode': 'OPENED',
      'lineSnapshot': null,
    },
  ],
  'valuation': sampleValuationJson(),
  'settlementPlan': sampleValuationJson()['settlementPlan'],
  'completionReady': false,
};
