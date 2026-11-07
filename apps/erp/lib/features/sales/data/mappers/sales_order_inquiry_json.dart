import 'package:erp/features/sales/data/mappers/sales_order_get_json.dart';
import 'package:vet45_sales_application/application.dart';

/// Dựng tham số + đọc JSON cho các RPC tra cứu đơn của schema `sales`
/// (chép từ SalesOrderInquiryRpcMapper, PostSaleActionsRpcMapper, SalesOrderCancellationRpcMapper).
abstract final class SalesOrderInquiryJson {
  static Map<String, dynamic> listParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'cursor': cursor,
      'page_size': pageSize,
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

  static Map<String, dynamic> searchParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String searchText,
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'search_text': searchText,
      'cursor': cursor,
      'page_size': pageSize,
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

  static Map<String, dynamic> orderScopedParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    int? expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': salesOrderId,
      'expected_source_version': expectedSourceVersion,
    };
  }

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
      order: SalesOrderGetJson.salesOrderFromJson(_map(json['order'])),
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

  static AvailablePostSaleActionsDto availableActionsFromJson(Map<String, dynamic> json) {
    return AvailablePostSaleActionsDto(
      canCancel: json['canCancel'] as bool? ?? false,
      canReturnExchange: json['canReturnExchange'] as bool? ?? false,
    );
  }

  static const _cancellationDetailKeys = <String>{
    'result',
    'reason',
    'cancelledAt',
    'cancelledByActorId',
    'cancelledByActorName',
    'netConfirmedCollectionMinor',
  };

  static const _cancellationResultKeys = <String>{
    'cancellationId',
    'salesOrderId',
    'salesOrderVersion',
    'status',
  };

  static const _cancellationReasonKeys = <String>{'reasonCode', 'reasonText'};

  static SalesOrderCancellationDetailDto cancellationDetailFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _cancellationDetailKeys);
    final result = json['result'];
    final reason = json['reason'];
    if (result is! Map) {
      throw const FormatException('Expected result object.');
    }
    if (reason is! Map) {
      throw const FormatException('Expected reason object.');
    }
    return SalesOrderCancellationDetailDto(
      result: _cancellationResultFromJson(result.cast<String, dynamic>()),
      reason: _cancellationReasonFromJson(reason.cast<String, dynamic>()),
      cancelledAt: DateTime.parse(_string(json, 'cancelledAt')).toUtc(),
      cancelledByActorId: _string(json, 'cancelledByActorId'),
      cancelledByActorName: _nullableString(json['cancelledByActorName'])?.trim() ?? '',
      netConfirmedCollectionMinor: _int(json['netConfirmedCollectionMinor']),
    );
  }

  static SalesOrderCancellationResultDto _cancellationResultFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _cancellationResultKeys);
    return SalesOrderCancellationResultDto(
      cancellationId: _string(json, 'cancellationId'),
      salesOrderId: _string(json, 'salesOrderId'),
      salesOrderVersion: _int(json['salesOrderVersion']),
      status: _cancellationStatus(_string(json, 'status')),
    );
  }

  static CancellationReasonDto _cancellationReasonFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _cancellationReasonKeys);
    return CancellationReasonDto(
      reasonText: _requiredStringAllowBlank(json, 'reasonText'),
    );
  }

  static SalesOrderCancellationStatus _cancellationStatus(String value) => switch (value) {
    'requested' => SalesOrderCancellationStatus.requested,
    'validating' => SalesOrderCancellationStatus.validating,
    'confirmed' => SalesOrderCancellationStatus.confirmed,
    'processing' => SalesOrderCancellationStatus.processing,
    'completed' => SalesOrderCancellationStatus.completed,
    'blocked' => SalesOrderCancellationStatus.blocked,
    'failed' => SalesOrderCancellationStatus.failed,
    'cancelled' => SalesOrderCancellationStatus.cancelled,
    _ => throw FormatException('Unknown sales order cancellation status: $value.'),
  };

  static void _rejectUnknownKeys(Map<String, dynamic> json, Set<String> allowed) {
    for (final key in json.keys) {
      if (!allowed.contains(key)) {
        throw FormatException('Unexpected field $key.');
      }
    }
  }

  static String _requiredStringAllowBlank(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected required string field $key.');
  }

  static SalesOrderLineDto _line(Map<String, dynamic> json) {
    return SalesOrderLineDto(
      lineId: _string(json, 'lineId'),
      product: _product(_map(json['product'])),
      unit: _unit(_map(json['unit'])),
      quantity: QuantityDto(quantityMicros: _int(json['quantityMicros'])),
      unitPrice: _money(_map(json['unitPrice'])),
      lineTotal: _money(_map(json['lineTotal'])),
      discountTotal: json['discountTotal'] == null ? null : _money(_map(json['discountTotal'])),
      note: json['note'] as String?,
    );
  }

  static SalesOrderCurrentLineDto _currentLine(Map<String, dynamic> json) {
    return SalesOrderCurrentLineDto(
      product: _product(_map(json['product'])),
      unit: _unit(_map(json['unit'])),
      heldQuantity: QuantityDto(quantityMicros: _int(_map(json['heldQuantity'])['quantityMicros'])),
      unitPrice: _money(_map(json['unitPrice'])),
      originalUnitPrice: json['originalUnitPrice'] == null
          ? null
          : _money(_map(json['originalUnitPrice'])),
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
