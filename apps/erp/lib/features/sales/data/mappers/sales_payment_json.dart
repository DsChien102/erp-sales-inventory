import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:erp/features/sales/data/models.dart';

/// Dựng tham số + đọc JSON của 3 RPC thanh toán (chép từ SalesOrderReadRpcMapper /
/// SalesOrderInquiryRpcMapper). Summary dùng khoá `p_*`; settlement / transactions
/// dùng khoá trần (RPC khai báo không tiền tố).
abstract final class SalesPaymentJson {
  static Map<String, dynamic> summaryParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    int? expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'p_query_id': queryId,
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
      'p_expected_source_version': ?expectedSourceVersion,
    };
  }

  static Map<String, dynamic> settlementParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _orderScopedParams(queryId, tenantId, actorId, salesOrderId, expectedSourceVersion);

  static Map<String, dynamic> transactionsParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    int? expectedSourceVersion,
    String? cursor,
    required int pageSize,
  }) => <String, dynamic>{
    ..._orderScopedParams(queryId, tenantId, actorId, salesOrderId, expectedSourceVersion),
    'cursor': cursor,
    'page_size': pageSize,
  };

  static Map<String, dynamic> recordParams({
    required String tenantId,
    required String actorId,
    required SalesRecordPaymentRequest request,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_store_id': request.storeId,
      'p_sales_order_id': request.salesOrderId,
      'p_amount_minor': request.amountMinor,
      'p_payment_method_code': switch (request.method) {
        SalesPaymentMethod.cash => 'cash',
        SalesPaymentMethod.manualBankTransfer => 'manualBankTransfer',
        SalesPaymentMethod.offset =>
          throw ArgumentError('offset is never sent by the app'),
      },
      'p_idempotency_key': request.idempotencyKey,
      'p_payload_hash': request.payloadHash,
      'p_source_context': 'additional_collection',
      'p_payment_method_snapshot': null,
      'p_external_reference': request.externalReference,
      'p_correlation_id': request.correlationId,
    };
  }

  static SalesRecordPaymentResult recordResultFromJson(Map<String, dynamic> json) {
    return SalesRecordPaymentResult(
      transactionId: _string(json, 'transactionId'),
      outstandingMinor: _int(json['outstandingMinor']),
      paymentStatus: _string(json, 'paymentStatus'),
      version: _int(json['version']),
    );
  }

  static SalesOrderPaymentSummaryDto paymentSummaryFromJson(
    Map<String, dynamic> json,
  ) {
    final originalOrder = json['originalOrder'];
    final returnSlips = json['returnSlips'];
    return SalesOrderPaymentSummaryDto(
      status: _settlementStatus(_string(json, 'status')),
      orderTotal: _money(_map(json['orderTotal'])),
      paidTotal: _money(_map(json['paidTotal'])),
      outstandingTotal: _money(_map(json['outstandingTotal'])),
      refundedTotal: _money(_map(json['refundedTotal'])),
      netCollectedTotal: _money(_map(json['netCollectedTotal'])),
      originalPayableTotal: _money(_map(json['originalPayableTotal'])),
      adjustmentTotal: _money(_map(json['adjustmentTotal'])),
      collectedCash: _money(_map(json['collectedCash'])),
      collectedBank: _money(_map(json['collectedBank'])),
      collectedOffset: json['collectedOffset'] == null
          ? const MoneyDto(amountMinor: 0, currencyCode: 'VND')
          : _money(_map(json['collectedOffset'])),
      refundedOffset: json['refundedOffset'] == null
          ? const MoneyDto(amountMinor: 0, currencyCode: 'VND')
          : _money(_map(json['refundedOffset'])),
      dueAt: _nullableDateOnly(json['dueAt']),
      originalOrder: originalOrder == null
          ? null
          : SalesOrderPaymentOriginalBreakdownDto(
              orderTotal: _money(_map(_map(originalOrder)['orderTotal'])),
              paidCash: _money(_map(_map(originalOrder)['paidCash'])),
              paidBank: _money(_map(_map(originalOrder)['paidBank'])),
              outstanding: _money(_map(_map(originalOrder)['outstanding'])),
            ),
      returnSlips: returnSlips is! List
          ? const []
          : returnSlips
                .map((item) {
                  final slip = _map(item);
                  final paidCashExtra = slip['paidCashExtra'];
                  final paidBankExtra = slip['paidBankExtra'];
                  return SalesOrderPaymentReturnSlipBreakdownDto(
                    slipNumber: _string(slip, 'slipNumber'),
                    customerPaysExtra: _money(_map(slip['customerPaysExtra'])),
                    paidCashExtra: paidCashExtra == null ? null : _money(_map(paidCashExtra)),
                    paidBankExtra: paidBankExtra == null ? null : _money(_map(paidBankExtra)),
                  );
                })
                .toList(growable: false),
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
      counterpartSalesOrderId: _nullableString(json['counterpartSalesOrderId']),
      counterpartOrderCode: _nullableString(json['counterpartOrderCode']),
      customerCollectionId: _nullableString(json['customerCollectionId']),
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
      'offset' => SalesPaymentMethod.offset,
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

  /// Payment due date is persisted as date-only. Parse `YYYY-MM-DD` as UTC
  /// midnight so a reload does not shift the calendar day.
  static DateTime? _nullableDateOnly(Object? value) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected date value, got $value.');
    }
    final text = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match != null) {
      return DateTime.utc(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    return DateTime.parse(text).toUtc();
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

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected integer value, got $value.');
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

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    throw FormatException('Expected string value, got $value.');
  }
}
