// ignore_for_file: use_null_aware_elements

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

const inquiryTenantId = 'tenant-1';
const inquiryActorId = 'user-1';
const inquiryOrderId = 'order-1';
const inquiryReceiptId = 'receipt-1';
const inquiryQueryId = '00000000-0000-4000-8000-000000000001';
const inquiryCommandId = '00000000-0000-4000-8000-000000000002';

SalesOrderListFilterInput fullFilter() => SalesOrderListFilterInput(
  completedFrom: DateTime(2026, 11, 1),
  completedTo: DateTime(2026, 11, 30, 23, 59, 59),
  storeId: 'store-1',
  sellerId: 'seller-1',
  customerId: 'customer-1',
  lifecycleStatus: SalesOrderLifecycleStatus.completed,
  lockStatus: SalesOrderLockStatus.unlocked,
  settlementStatus: SalesSettlementStatus.partiallyPaid,
  hasReturnExchange: true,
  eInvoiceStatus: IntegrationDeliveryStatus.queued,
  hasOutstandingReceivable: true,
);

Map<String, dynamic> expectedListParams({
  SalesOrderListFilterInput? filter,
  String? cursor,
  int pageSize = 50,
  String queryId = inquiryQueryId,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'cursor': cursor,
  'page_size': pageSize,
  'completed_from': filter?.completedFrom?.toUtc().toIso8601String(),
  'completed_to': filter?.completedTo?.toUtc().toIso8601String(),
  'store_id': filter?.storeId,
  'seller_id': filter?.sellerId,
  'customer_id': filter?.customerId,
  'lifecycle_status': filter?.lifecycleStatus?.name,
  'lock_status': filter?.lockStatus?.name,
  'settlement_status': filter?.settlementStatus?.name,
  'has_return_exchange': filter?.hasReturnExchange,
  'e_invoice_status': filter?.eInvoiceStatus?.name,
  'has_outstanding_receivable': filter?.hasOutstandingReceivable,
};

Map<String, dynamic> expectedSearchParams({
  required String searchText,
  SalesOrderListFilterInput? filter,
  String? cursor,
  int pageSize = 50,
  String queryId = inquiryQueryId,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'search_text': searchText,
  'cursor': cursor,
  'page_size': pageSize,
  'completed_from': filter?.completedFrom?.toUtc().toIso8601String(),
  'completed_to': filter?.completedTo?.toUtc().toIso8601String(),
  'store_id': filter?.storeId,
  'seller_id': filter?.sellerId,
  'customer_id': filter?.customerId,
  'lifecycle_status': filter?.lifecycleStatus?.name,
  'lock_status': filter?.lockStatus?.name,
  'settlement_status': filter?.settlementStatus?.name,
  'has_return_exchange': filter?.hasReturnExchange,
  'e_invoice_status': filter?.eInvoiceStatus?.name,
  'has_outstanding_receivable': filter?.hasOutstandingReceivable,
};

Map<String, dynamic> expectedOrderScopedParams({
  required String salesOrderId,
  int? expectedSourceVersion,
  String queryId = inquiryQueryId,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
}) => <String, dynamic>{
  'query_id': queryId,
  'tenant_id': tenantId,
  'actor_id': actorId,
  'sales_order_id': salesOrderId,
  'expected_source_version': expectedSourceVersion,
};

Map<String, dynamic> samplePagedListJson() => <String, dynamic>{
  'items': [
    {
      'salesOrderId': '11111111-1111-1111-1111-111111111111',
      'orderNumber': 'SO-2026-00125',
      'sourceVersion': 7,
      'committedAt': '2026-08-12T03:15:00.000Z',
      'customer': {
        'customerId': 'customer-1',
        'displayName': 'Dai ly An Binh',
        'phoneNumber': '0903456789',
        'taxCode': '0312345678',
        'existingDebtMinor': 0,
      },
      'store': {
        'storeId': 'store-1',
        'storeCode': 'HCM-01',
        'displayName': 'Chi nhanh Quan 1',
      },
      'total': {'amountMinor': 1250000, 'currencyCode': 'VND'},
      'lifecycleStatus': 'completed',
      'lockStatus': 'unlocked',
      'settlementStatus': 'partiallyPaid',
      'returnStatus': 'none',
      'eInvoiceStatus': 'queued',
    },
  ],
  'hasMore': true,
  'nextCursor': 'cursor-2',
  'totalMatching': 10,
  'facets': {
    'all': 10,
    'outstandingReceivable': 4,
    'eInvoicePending': 3,
  },
};

void expectPagedListDto(PagedSalesOrderListDto dto) {
  expect(dto.totalMatching, 10);
  expect(dto.page.hasMore, isTrue);
  expect(dto.page.nextCursor, 'cursor-2');
  expect(dto.page.items, hasLength(1));
  final item = dto.page.items.single;
  expect(item.salesOrderId, '11111111-1111-1111-1111-111111111111');
  expect(item.orderNumber, 'SO-2026-00125');
  expect(item.sourceVersion, 7);
  expect(item.committedAt, DateTime.parse('2026-08-12T03:15:00.000Z'));
  expect(item.customer?.displayName, 'Dai ly An Binh');
  expect(item.store.storeCode, 'HCM-01');
  expect(item.total.amountMinor, 1250000);
  expect(item.lifecycleStatus, SalesOrderLifecycleStatus.completed);
  expect(item.lockStatus, SalesOrderLockStatus.unlocked);
  expect(item.settlementStatus, SalesSettlementStatus.partiallyPaid);
  expect(item.returnStatus, SalesOrderReturnProjectionStatus.none);
  expect(item.eInvoiceStatus, IntegrationDeliveryStatus.queued);
  expect(dto.facets?.all, 10);
  expect(dto.facets?.outstandingReceivable, 4);
  expect(dto.facets?.eInvoicePending, 3);
}

Map<String, dynamic> sampleDetailJson() => <String, dynamic>{
  'order': {
    'salesOrderId': '11111111-1111-1111-1111-111111111111',
    'orderNumber': 'SO-2026-00125',
    'version': 7,
    'lifecycleStatus': 'completed',
    'lockStatus': 'unlocked',
    'total': {'amountMinor': 1250000, 'currencyCode': 'VND'},
  },
  'committedAt': '2026-08-12T03:15:00.000Z',
  'store': {
    'storeId': 'store-1',
    'storeCode': 'HCM-01',
    'displayName': 'Chi nhanh Quan 1',
  },
  'seller': {'actorId': 'actor-1', 'displayName': 'Minh Anh'},
  'customer': {
    'customerId': 'customer-1',
    'displayName': 'Dai ly An Binh',
    'phoneNumber': '0903456789',
    'taxCode': '0312345678',
    'existingDebtMinor': 0,
  },
  'orderNote': 'Giao gio hanh chinh',
  'currentReceiptId': 'receipt-1',
  'lines': [
    {
      'lineId': 'line-1',
      'product': {
        'productId': 'product-1',
        'sku': 'SKU-1',
        'displayName': 'Amoxicillin 500mg',
      },
      'unit': {
        'productUnitId': 'unit-1',
        'unitCode': 'BOX',
        'unitName': 'Hop',
      },
      'quantityMicros': 1000000,
      'unitPrice': {'amountMinor': 1250000, 'currencyCode': 'VND'},
      'lineTotal': {'amountMinor': 1250000, 'currencyCode': 'VND'},
      'discountTotal': {'amountMinor': 20000, 'currencyCode': 'VND'},
      'note': 'hang de vo',
    },
  ],
  'currentLines': [
    {
      'product': {'productId': 'p-a', 'sku': null, 'displayName': 'A'},
      'unit': {'productUnitId': 'u-a', 'unitCode': null, 'unitName': 'lọ'},
      'heldQuantity': {'quantityMicros': 2000000},
      'unitPrice': {'amountMinor': 90000, 'currencyCode': 'VND'},
      'originalUnitPrice': {'amountMinor': 100000, 'currencyCode': 'VND'},
      'source': 'exchange',
    },
  ],
};

void expectDetailDto(SalesOrderDetailDto dto) {
  expect(dto.order.salesOrderId, '11111111-1111-1111-1111-111111111111');
  expect(dto.order.version, 7);
  expect(dto.committedAt, DateTime.parse('2026-08-12T03:15:00.000Z'));
  expect(dto.store.storeCode, 'HCM-01');
  expect(dto.seller.displayName, 'Minh Anh');
  expect(dto.customer?.displayName, 'Dai ly An Binh');
  expect(dto.orderNote, 'Giao gio hanh chinh');
  expect(dto.currentReceiptId, 'receipt-1');
  expect(dto.lines, hasLength(1));
  expect(dto.lines.single.product.displayName, 'Amoxicillin 500mg');
  expect(dto.lines.single.discountTotal?.amountMinor, 20000);
  expect(dto.lines.single.note, 'hang de vo');
  expect(dto.currentLines, hasLength(1));
  expect(dto.currentLines.single.source, SalesOrderLineSource.exchange);
  expect(dto.currentLines.single.heldQuantity.quantityMicros, 2000000);
  expect(dto.currentLines.single.originalUnitPrice?.amountMinor, 100000);
}

Map<String, dynamic> sampleTimelineJson() => <String, dynamic>{
  'salesOrderId': 'order-1',
  'entries': [
    {
      'eventId': 'evt-1',
      'eventType': 'order_note_updated',
      'occurredAt': '2026-08-07T00:00:00.000Z',
      'sourceVersion': 2,
      'actor': {'actorId': 'actor-1', 'displayName': 'Minh Anh'},
      'description': 'Giao sáng → Giao chiều',
      'amount': {'amountMinor': 50000, 'currencyCode': 'VND'},
    },
  ],
};

void expectTimelineDto(SalesOrderTimelineDto dto) {
  expect(dto.salesOrderId, 'order-1');
  expect(dto.entries, hasLength(1));
  final entry = dto.entries.single;
  expect(entry.eventId, 'evt-1');
  expect(entry.eventType, 'order_note_updated');
  expect(entry.occurredAt, DateTime.parse('2026-08-07T00:00:00.000Z'));
  expect(entry.sourceVersion, 2);
  expect(entry.actor?.displayName, 'Minh Anh');
  expect(entry.description, 'Giao sáng → Giao chiều');
  expect(entry.amount?.amountMinor, 50000);
}

Map<String, dynamic> sampleReturnSummaryJson() => <String, dynamic>{
  'salesOrderId': 'order-1',
  'returns': [
    {
      'returnExchangeId': 're-1',
      'referenceNumber': 're-1',
      'status': 'completed',
      'completedAt': '2026-08-10T04:00:00.000Z',
      'settlementDifference': {'amountMinor': 150000, 'currencyCode': 'VND'},
    },
  ],
};

void expectReturnSummaryDto(SalesOrderReturnSummaryDto dto) {
  expect(dto.salesOrderId, 'order-1');
  expect(dto.returns, hasLength(1));
  final item = dto.returns.single;
  expect(item.returnExchangeId, 're-1');
  expect(item.referenceNumber, 're-1');
  expect(item.status, ReturnExchangeStatus.completed);
  expect(item.completedAt, DateTime.parse('2026-08-10T04:00:00.000Z'));
  expect(item.settlementDifference.amountMinor, 150000);
}

Map<String, dynamic> sampleAvailableActionsJson() => <String, dynamic>{
  'canCancel': true,
  'canReturnExchange': false,
};

void expectAvailableActionsDto(AvailablePostSaleActionsDto dto) {
  expect(dto.canCancel, isTrue);
  expect(dto.canReturnExchange, isFalse);
}

Map<String, dynamic> sampleCancellationDetailJson() => <String, dynamic>{
  'result': {
    'cancellationId': 'cancel-1',
    'salesOrderId': 'order-1',
    'salesOrderVersion': 8,
    'status': 'completed',
  },
  'reason': {
    'reasonCode': 'CUSTOMER_REQUEST',
    'reasonText': 'Khách đổi ý',
  },
  'cancelledAt': '2026-08-10T09:00:00+07:00',
  'cancelledByActorId': 'actor-7',
  'cancelledByActorName': 'Minh Anh',
  'netConfirmedCollectionMinor': 0,
};

void expectCancellationDetailDto(SalesOrderCancellationDetailDto dto) {
  expect(dto.result.cancellationId, 'cancel-1');
  expect(dto.result.salesOrderId, 'order-1');
  expect(dto.result.salesOrderVersion, 8);
  expect(dto.result.status, SalesOrderCancellationStatus.completed);
  expect(dto.reason.reasonText, 'Khách đổi ý');
  expect(dto.cancelledAt, DateTime.utc(2026, 8, 10, 2, 0, 0));
  expect(dto.cancelledByActorId, 'actor-7');
  expect(dto.cancelledByActorName, 'Minh Anh');
  expect(dto.netConfirmedCollectionMinor, 0);
}

Map<String, dynamic> expectedGenerateParams({
  required int expectedVersion,
  String idempotencyKey = 'idem-1',
  String commandId = inquiryCommandId,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
  String salesOrderId = inquiryOrderId,
  String? correlationId = 'corr-1',
}) => <String, dynamic>{
  'p_command_id': commandId,
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_sales_order_id': salesOrderId,
  'p_idempotency_key': idempotencyKey,
  'p_payload_hash': null,
  'p_correlation_id': correlationId,
  'p_causation_id': null,
  'p_expected_source_version': expectedVersion,
};

Map<String, dynamic> expectedGetReceiptParams({
  int? expectedSourceVersion,
  String queryId = inquiryQueryId,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
  String receiptId = inquiryReceiptId,
}) => <String, dynamic>{
  'p_query_id': queryId,
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_receipt_id': receiptId,
  if (expectedSourceVersion != null) 'p_expected_source_version': expectedSourceVersion,
};

Map<String, dynamic> expectedOriginalReceiptParams({
  String queryId = inquiryQueryId,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
  String salesOrderId = inquiryOrderId,
}) => <String, dynamic>{
  'p_query_id': queryId,
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_sales_order_id': salesOrderId,
};

Map<String, dynamic> expectedPrintedParams({
  required String commandId,
  required String idempotencyKey,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
  String receiptId = inquiryReceiptId,
  String? correlationId,
}) => <String, dynamic>{
  'p_command_id': commandId,
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_receipt_id': receiptId,
  'p_activity_type': 'printed',
  'p_idempotency_key': idempotencyKey,
  'p_payload_hash': null,
  'p_correlation_id': correlationId,
  'p_causation_id': null,
  'p_expected_source_version': null,
};

Map<String, dynamic> expectedSharedParams({
  required String commandId,
  required String idempotencyKey,
  String tenantId = inquiryTenantId,
  String actorId = inquiryActorId,
  String receiptId = inquiryReceiptId,
  String? correlationId,
}) => <String, dynamic>{
  'p_command_id': commandId,
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_receipt_id': receiptId,
  'p_activity_type': 'shared',
  'p_idempotency_key': idempotencyKey,
  'p_payload_hash': null,
  'p_correlation_id': correlationId,
  'p_causation_id': null,
  'p_expected_source_version': null,
};

Map<String, dynamic> sampleReceiptJson() => <String, dynamic>{
  'receiptId': 'receipt-1',
  'salesOrderId': 'order-1',
  'version': 1,
  'status': 'generated',
  'generatedAt': '2026-08-12T02:41:00.000Z',
  'document': sampleOriginalDocumentJson(),
};

Map<String, dynamic> sampleOriginalDocumentJson() => <String, dynamic>{
  'receiptNumber': 'PBH-20260812-0129',
  'orderNumber': 'SO-000129',
  'soldAt': '2026-08-12T02:41:00.000Z',
  'store': <String, dynamic>{
    'storeId': 'store-1',
    'storeCode': 'HCM-01',
    'displayName': 'Store One',
  },
  'seller': <String, dynamic>{'actorId': 'actor-1', 'displayName': 'Minh Anh'},
  'customer': <String, dynamic>{
    'customerId': 'customer-1',
    'displayName': 'Nguyen Van An',
    'phoneNumber': null,
    'taxCode': null,
    'existingDebtMinor': 0,
  },
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'lineId': 'line-1',
      'product': <String, dynamic>{
        'productId': 'product-1',
        'sku': null,
        'displayName': 'Vaccine A',
      },
      'unit': <String, dynamic>{
        'productUnitId': 'unit-1',
        'unitCode': null,
        'unitName': 'Vial',
      },
      'quantityMicros': 1000000,
      'unitPrice': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
      'discountTotal': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
      'lineTotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
    },
  ],
  'subtotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
  'discountTotal': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
  'orderTotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
  'paidTotal': <String, dynamic>{'amountMinor': 60000, 'currencyCode': 'VND'},
  'outstandingTotal': <String, dynamic>{'amountMinor': 40000, 'currencyCode': 'VND'},
  'payments': <Map<String, dynamic>>[
    <String, dynamic>{
      'method': 'cash',
      'amount': <String, dynamic>{'amountMinor': 60000, 'currencyCode': 'VND'},
      'status': 'confirmed',
    },
  ],
  'dueAt': null,
};

void expectReceiptDto(SalesReceiptDto dto) {
  expect(dto.receiptId, 'receipt-1');
  expect(dto.salesOrderId, 'order-1');
  expect(dto.version, 1);
  expect(dto.status, SalesReceiptStatus.generated);
  expect(dto.generatedAt, DateTime.utc(2026, 8, 12, 2, 41));
  expectOriginalDocumentDto(dto.document);
}

void expectOriginalDocumentDto(SalesReceiptDocumentDto dto) {
  expect(dto.receiptNumber, 'PBH-20260812-0129');
  expect(dto.orderNumber, 'SO-000129');
  expect(dto.soldAt, DateTime.utc(2026, 8, 12, 2, 41));
  expect(dto.store.storeCode, 'HCM-01');
  expect(dto.seller.displayName, 'Minh Anh');
  expect(dto.customer?.displayName, 'Nguyen Van An');
  expect(dto.lines, hasLength(1));
  expect(dto.lines.single.product.displayName, 'Vaccine A');
  expect(dto.orderTotal.amountMinor, 100000);
  expect(dto.paidTotal.amountMinor, 60000);
  expect(dto.outstandingTotal.amountMinor, 40000);
  expect(dto.payments, hasLength(1));
  expect(dto.payments.single.method, SalesPaymentMethod.cash);
}
