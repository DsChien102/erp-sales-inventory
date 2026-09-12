import 'package:vet45_sales_application/application.dart';

import 'sales_order_read_rpc_mapper.dart';

/// Maps S15–S18 inquiry queries/results to/from the `sales.*` read RPC wire
/// shape. Params snake_case; result envelopes camelCase (enum wire = Dart enum
/// `.name`). Cursor pages use `{items, hasMore, nextCursor}`.
abstract final class SalesOrderInquiryRpcMapper {
  static Map<String, dynamic> listParams(ListSalesOrdersQuery query) {
    final filter = query.filter;
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'cursor': query.cursor,
      'page_size': query.pageSize,
      'completed_from': _toUtcIsoString(filter?.completedFrom),
      'completed_to': _toUtcIsoString(filter?.completedTo),
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
  }

  static Map<String, dynamic> searchParams(SearchSalesOrdersQuery query) {
    final filter = query.filter;
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'search_text': query.searchText,
      'cursor': query.cursor,
      'page_size': query.pageSize,
      'completed_from': _toUtcIsoString(filter?.completedFrom),
      'completed_to': _toUtcIsoString(filter?.completedTo),
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
  }

  static Map<String, dynamic> detailParams(GetSalesOrderDetailQuery query) => _orderScopedParams(
    query.id,
    query.tenantId,
    query.actorId,
    query.salesOrderId,
    query.expectedSourceVersion,
  );

  static Map<String, dynamic> settlementParams(GetSalesOrderSettlementQuery query) =>
      _orderScopedParams(
        query.id,
        query.tenantId,
        query.actorId,
        query.salesOrderId,
        query.expectedSourceVersion,
      );

  static Map<String, dynamic> transactionsParams(GetSalesOrderPaymentTransactionsQuery query) =>
      <String, dynamic>{
        ..._orderScopedParams(
          query.id,
          query.tenantId,
          query.actorId,
          query.salesOrderId,
          query.expectedSourceVersion,
        ),
        'cursor': query.cursor,
        'page_size': query.pageSize,
      };

  static Map<String, dynamic> timelineParams(GetSalesOrderTimelineQuery query) =>
      _orderScopedParams(
        query.id,
        query.tenantId,
        query.actorId,
        query.salesOrderId,
        query.expectedSourceVersion,
      );

  static Map<String, dynamic> returnSummaryParams(GetSalesOrderReturnSummaryQuery query) =>
      _orderScopedParams(
        query.id,
        query.tenantId,
        query.actorId,
        query.salesOrderId,
        query.expectedSourceVersion,
      );

  static PagedSalesOrderListDto pagedListFromJson(Map<String, dynamic> json) {
    return PagedSalesOrderListDto(
      page: OpaqueCursorPageDto<SalesOrderListItemDto>(
        items: _list(json['items']).map(_listItemFromJson).toList(growable: false),
        hasMore: json['hasMore'] as bool? ?? false,
        nextCursor: json['nextCursor'] as String?,
      ),
      totalMatching: json['totalMatching'] as int?,
      facets: json['facets'] is Map
          ? _facetsFromJson((json['facets'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  static SalesOrderListItemDto _listItemFromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return SalesOrderListItemDto(
      salesOrderId: _string(json, 'salesOrderId'),
      orderNumber: _string(json, 'orderNumber'),
      sourceVersion: _int(json['sourceVersion']),
      committedAt: DateTime.parse(_string(json, 'committedAt')),
      customer: customer is Map ? _customer(customer.cast<String, dynamic>()) : null,
      store: _store(_map(json['store'])),
      total: _money(_map(json['total'])),
      lifecycleStatus: SalesOrderLifecycleStatus.values.byName(_string(json, 'lifecycleStatus')),
      lockStatus: SalesOrderLockStatus.values.byName(_string(json, 'lockStatus')),
      settlementStatus: _settlementStatus(_string(json, 'settlementStatus')),
      returnStatus: SalesOrderReturnProjectionStatus.values.byName(
        _string(json, 'returnStatus'),
      ),
      eInvoiceStatus: IntegrationDeliveryStatus.values.byName(_string(json, 'eInvoiceStatus')),
    );
  }

  static SalesOrderListFacetsDto _facetsFromJson(Map<String, dynamic> json) {
    return SalesOrderListFacetsDto(
      all: _int(json['all']),
      outstandingReceivable: _int(json['outstandingReceivable']),
      eInvoicePending: _int(json['eInvoicePending']),
    );
  }

  static SalesOrderDetailDto detailFromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return SalesOrderDetailDto(
      order: SalesOrderReadRpcMapper.salesOrderFromJson(_map(json['order'])),
      committedAt: DateTime.parse(_string(json, 'committedAt')),
      store: _store(_map(json['store'])),
      seller: _actor(_map(json['seller'])),
      customer: customer is Map ? _customer(customer.cast<String, dynamic>()) : null,
      lines: _list(json['lines']).map(_line).toList(growable: false),
      orderNote: json['orderNote'] as String?,
      currentReceiptId: json['currentReceiptId'] as String?,
      currentLines: _list(json['currentLines']).map(_currentLine).toList(growable: false),
    );
  }

  static SalesOrderSettlementDto settlementFromJson(Map<String, dynamic> json) {
    final dueAt = json['dueAt'];
    return SalesOrderSettlementDto(
      settlementId: _string(json, 'settlementId'),
      salesOrderId: _string(json, 'salesOrderId'),
      version: _int(json['version']),
      status: _settlementStatus(_string(json, 'status')),
      orderTotal: _money(_map(json['orderTotal'])),
      paidTotal: _money(_map(json['paidTotal'])),
      refundedTotal: _money(_map(json['refundedTotal'])),
      outstanding: _money(_map(json['outstanding'])),
      dueAt: dueAt == null ? null : DateTime.parse(_string(json, 'dueAt')),
    );
  }

  static SalesPaymentTransactionsDto transactionsFromJson(Map<String, dynamic> json) {
    return SalesPaymentTransactionsDto(
      page: OpaqueCursorPageDto<SalesPaymentTransactionDto>(
        items: _list(json['items']).map(_transaction).toList(growable: false),
        hasMore: json['hasMore'] as bool? ?? false,
        nextCursor: json['nextCursor'] as String?,
      ),
    );
  }

  static SalesOrderTimelineDto timelineFromJson(Map<String, dynamic> json) {
    return SalesOrderTimelineDto(
      salesOrderId: _string(json, 'salesOrderId'),
      entries: _list(json['entries']).map(_timelineEntry).toList(growable: false),
    );
  }

  static SalesOrderReturnSummaryDto returnSummaryFromJson(Map<String, dynamic> json) {
    return SalesOrderReturnSummaryDto(
      salesOrderId: _string(json, 'salesOrderId'),
      returns: _list(json['returns']).map(_returnSummary).toList(growable: false),
    );
  }

  static Map<String, dynamic> _orderScopedParams(
    String id,
    String tenantId,
    String actorId,
    String salesOrderId,
    int? expectedSourceVersion,
  ) {
    return <String, dynamic>{
      'query_id': id,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': salesOrderId,
      'expected_source_version': expectedSourceVersion,
    };
  }

  static SalesOrderLineDto _line(Map<String, dynamic> json) {
    return SalesOrderLineDto(
      lineId: _string(json, 'lineId'),
      product: _product(_map(json['product'])),
      unit: _unit(_map(json['unit'])),
      quantity: QuantityDto(quantityMicros: _int(json['quantityMicros'])),
      unitPrice: _money(_map(json['unitPrice'])),
      lineTotal: _money(_map(json['lineTotal'])),
      note: json['note'] as String?,
    );
  }

  static SalesOrderCurrentLineDto _currentLine(Map<String, dynamic> json) {
    return SalesOrderCurrentLineDto(
      product: _product(_map(json['product'])),
      unit: _unit(_map(json['unit'])),
      heldQuantity: QuantityDto(quantityMicros: _int(_map(json['heldQuantity'])['quantityMicros'])),
      unitPrice: _money(_map(json['unitPrice'])),
      source: _lineSource(_string(json, 'source')),
    );
  }

  static SalesOrderLineSource _lineSource(String value) {
    return switch (value) {
      'exchange' => SalesOrderLineSource.exchange,
      'original' => SalesOrderLineSource.original,
      _ => SalesOrderLineSource.original,
    };
  }

  static ProductSnapshotDto _product(Map<String, dynamic> json) {
    return ProductSnapshotDto(
      productId: _string(json, 'productId'),
      sku: _nullableString(json['sku']),
      displayName: _string(json, 'displayName'),
    );
  }

  static ProductUnitSnapshotDto _unit(Map<String, dynamic> json) {
    return ProductUnitSnapshotDto(
      productUnitId: _string(json, 'productUnitId'),
      unitCode: _nullableString(json['unitCode']),
      unitName: _string(json, 'unitName'),
    );
  }

  static StoreSnapshotDto _store(Map<String, dynamic> json) {
    return StoreSnapshotDto(
      storeId: _string(json, 'storeId'),
      storeCode: _string(json, 'storeCode'),
      displayName: _string(json, 'displayName'),
    );
  }

  static CustomerSnapshotDto _customer(Map<String, dynamic> json) {
    return CustomerSnapshotDto(
      customerId: _string(json, 'customerId'),
      displayName: _string(json, 'displayName'),
      phoneNumber: json['phoneNumber'] as String?,
      taxCode: json['taxCode'] as String?,
      existingDebtMinor: json['existingDebtMinor'] is int ? json['existingDebtMinor'] as int : 0,
    );
  }

  static SalesPaymentTransactionDto _transaction(Map<String, dynamic> json) {
    return SalesPaymentTransactionDto(
      transactionId: _string(json, 'transactionId'),
      method: _paymentMethod(_string(json, 'method')),
      amount: _money(_map(json['amount'])),
      status: _paymentStatus(_string(json, 'status')),
      recordedAt: DateTime.parse(_string(json, 'recordedAt')),
      transactionType: _transactionType(_string(json, 'transactionType')),
      direction: _direction(_string(json, 'direction')),
      relatedTransactionId: _nullableString(json['relatedTransactionId']),
      sourceContext: _nullableString(json['sourceContext']),
      actorId: _nullableString(json['actorId']),
      reasonCode: _nullableString(json['reasonCode']),
      reason: _nullableString(json['reason']),
    );
  }

  static SalesOrderTimelineEntryDto _timelineEntry(Map<String, dynamic> json) {
    final amount = json['amount'];
    final actor = json['actor'];
    return SalesOrderTimelineEntryDto(
      eventId: _string(json, 'eventId'),
      eventType: _string(json, 'eventType'),
      occurredAt: DateTime.parse(_string(json, 'occurredAt')),
      sourceVersion: _int(json['sourceVersion']),
      actor: actor is Map ? _actor(actor.cast<String, dynamic>()) : null,
      description: _nullableString(json['description']),
      amount: amount is Map ? _money(amount.cast<String, dynamic>()) : null,
    );
  }

  static ActorSnapshotDto _actor(Map<String, dynamic> json) {
    return ActorSnapshotDto(
      actorId: _string(json, 'actorId'),
      displayName: _string(json, 'displayName'),
    );
  }

  static ReturnExchangeSummaryDto _returnSummary(Map<String, dynamic> json) {
    return ReturnExchangeSummaryDto(
      returnExchangeId: _string(json, 'returnExchangeId'),
      referenceNumber: _string(json, 'referenceNumber'),
      status: _returnStatus(_string(json, 'status')),
      completedAt: DateTime.parse(_string(json, 'completedAt')),
      settlementDifference: _money(_map(json['settlementDifference'])),
    );
  }

  static SalesSettlementStatus _settlementStatus(String value) {
    return switch (value) {
      'unpaid' => SalesSettlementStatus.unpaid,
      'partiallyPaid' => SalesSettlementStatus.partiallyPaid,
      'paid' => SalesSettlementStatus.paid,
      'partiallyRefunded' => SalesSettlementStatus.partiallyRefunded,
      'refunded' => SalesSettlementStatus.refunded,
      'no_balance' => SalesSettlementStatus.noBalance,
      _ => throw FormatException('Unknown settlement status: $value.'),
    };
  }

  static SalesPaymentTransactionType _transactionType(String value) {
    return switch (value) {
      'collection' => SalesPaymentTransactionType.collection,
      'refund' => SalesPaymentTransactionType.refund,
      'reversal' => SalesPaymentTransactionType.reversal,
      _ => throw FormatException('Unknown payment transaction type: $value.'),
    };
  }

  static SalesPaymentDirection _direction(String value) {
    return switch (value) {
      'inflow' => SalesPaymentDirection.inflow,
      'outflow' => SalesPaymentDirection.outflow,
      _ => throw FormatException('Unknown payment direction: $value.'),
    };
  }

  static SalesPaymentMethod _paymentMethod(String value) {
    return switch (value) {
      'cash' => SalesPaymentMethod.cash,
      'manualBankTransfer' => SalesPaymentMethod.manualBankTransfer,
      _ => throw FormatException('Unknown payment method: $value.'),
    };
  }

  static SalesPaymentStatus _paymentStatus(String value) {
    return switch (value) {
      'pending' => SalesPaymentStatus.pending,
      'confirmed' => SalesPaymentStatus.confirmed,
      'failed' => SalesPaymentStatus.failed,
      'voided' => SalesPaymentStatus.voided,
      _ => throw FormatException('Unknown payment status: $value.'),
    };
  }

  static ReturnExchangeStatus _returnStatus(String value) {
    return switch (value) {
      'draft' => ReturnExchangeStatus.draft,
      'confirmed' => ReturnExchangeStatus.confirmed,
      'processing' => ReturnExchangeStatus.processing,
      'completed' => ReturnExchangeStatus.completed,
      'cancelled' => ReturnExchangeStatus.cancelled,
      'blocked' => ReturnExchangeStatus.blocked,
      'failed' => ReturnExchangeStatus.failed,
      _ => throw FormatException('Unknown return exchange status: $value.'),
    };
  }

  static MoneyDto _money(Map<String, dynamic> json) {
    return MoneyDto(
      amountMinor: _int(json['amountMinor']),
      currencyCode: _string(json, 'currencyCode'),
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return value.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $value.');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected required string field $key.');
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    throw FormatException('Expected string value, got $value.');
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected integer value, got $value.');
  }

  static String? _toUtcIsoString(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }
}
