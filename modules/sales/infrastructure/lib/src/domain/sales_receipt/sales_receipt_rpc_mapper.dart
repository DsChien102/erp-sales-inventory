import 'package:vet45_sales_application/application.dart';

/// Maps S14 receipt commands/queries to/from the `sales.*` receipt RPC wire
/// shape. Params are snake_case; result envelope is camelCase. Receipt status
/// wire values are the Dart enum `.name` (`generated`, `superseded`, `archived`).
abstract final class SalesReceiptRpcMapper {
  static Map<String, dynamic> generateParams(GenerateSalesReceiptCommand command) {
    return <String, dynamic>{
      'p_command_id': command.id,
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_sales_order_id': command.salesOrderId,
      'p_idempotency_key': command.idempotencyKey,
      'p_payload_hash': command.payloadHash,
      'p_correlation_id': command.correlationId,
      'p_causation_id': command.causationId,
      if (command.expectedSourceVersion != null)
        'p_expected_source_version': command.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> printedParams(RecordSalesReceiptPrintedCommand command) {
    return _activityParams(
      commandId: command.id,
      tenantId: command.tenantId,
      actorId: command.actorId,
      receiptId: command.receiptId,
      activityType: 'printed',
      idempotencyKey: command.idempotencyKey,
      payloadHash: command.payloadHash,
      correlationId: command.correlationId,
      causationId: command.causationId,
      expectedSourceVersion: command.expectedSourceVersion,
    );
  }

  static Map<String, dynamic> sharedParams(RecordSalesReceiptSharedCommand command) {
    return _activityParams(
      commandId: command.id,
      tenantId: command.tenantId,
      actorId: command.actorId,
      receiptId: command.receiptId,
      activityType: 'shared',
      idempotencyKey: command.idempotencyKey,
      payloadHash: command.payloadHash,
      correlationId: command.correlationId,
      causationId: command.causationId,
      expectedSourceVersion: command.expectedSourceVersion,
    );
  }

  static Map<String, dynamic> archiveParams(ArchiveSalesReceiptCommand command) {
    return _activityParams(
      commandId: command.id,
      tenantId: command.tenantId,
      actorId: command.actorId,
      receiptId: command.receiptId,
      activityType: 'archived',
      idempotencyKey: command.idempotencyKey,
      payloadHash: command.payloadHash,
      correlationId: command.correlationId,
      causationId: command.causationId,
      expectedSourceVersion: command.expectedSourceVersion,
    );
  }

  static Map<String, dynamic> getReceiptParams(GetSalesReceiptQuery query) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_receipt_id': query.receiptId,
      if (query.expectedSourceVersion != null)
        'p_expected_source_version': query.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> originalReceiptParams(GetSalesOrderOriginalReceiptQuery query) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_sales_order_id': query.salesOrderId,
    };
  }

  /// The as-sold receipt RPC returns the document directly (no envelope).
  static SalesReceiptDocumentDto documentFromJson(Map<String, dynamic> json) => _document(json);

  static SalesReceiptDto salesReceiptFromJson(Map<String, dynamic> json) {
    return SalesReceiptDto(
      receiptId: _string(json, 'receiptId'),
      salesOrderId: _string(json, 'salesOrderId'),
      version: _int(json['version']),
      status: _receiptStatus(_string(json, 'status')),
      generatedAt: _dateTime(json['generatedAt']),
      document: _document(_map(json['document'])),
    );
  }

  static SalesReceiptDocumentDto _document(Map<String, dynamic> json) {
    final customer = json['customer'];
    final settlement = json['settlementSnapshot'];
    return SalesReceiptDocumentDto(
      receiptNumber: _string(json, 'receiptNumber'),
      orderNumber: _string(json, 'orderNumber'),
      soldAt: _dateTime(json['soldAt']),
      store: _store(_map(json['store'])),
      seller: _actor(_map(json['seller'])),
      customer: customer == null ? null : _customer(_map(customer)),
      lines: _array(json['lines'], 'lines').map(_line).toList(growable: false),
      subtotal: _money(_map(json['subtotal'])),
      discountTotal: _money(_map(json['discountTotal'])),
      taxTotal: json['taxTotal'] == null ? null : _money(_map(json['taxTotal'])),
      roundingTotal: json['roundingTotal'] == null
          ? null
          : _money(_map(json['roundingTotal'])),
      orderTotal: _money(_map(json['orderTotal'])),
      paidTotal: _money(_map(json['paidTotal'])),
      outstandingTotal: _money(_map(json['outstandingTotal'])),
      payments: _array(json['payments'], 'payments').map(_payment).toList(growable: false),
      dueAt: _nullableDateTime(json['dueAt']),
      settlementSnapshot: settlement == null
          ? null
          : _settlementSnapshot(_map(settlement)),
    );
  }

  static SalesReceiptSettlementSnapshotDto _settlementSnapshot(Map<String, dynamic> json) {
    final sources = json['adjustmentSources'];
    return SalesReceiptSettlementSnapshotDto(
      originalPayable: _money(_map(json['originalPayable'])),
      adjustment: _money(_map(json['adjustment'])),
      currentPayable: _money(_map(json['currentPayable'])),
      collected: _money(_map(json['collected'])),
      refunded: _money(_map(json['refunded'])),
      netCollected: _money(_map(json['netCollected'])),
      outstanding: _money(_map(json['outstanding'])),
      adjustmentSources: sources is! List
          ? const []
          : sources.map((item) => _adjustmentSource(_map(item))).toList(growable: false),
    );
  }

  static SalesReceiptAdjustmentSourceDto _adjustmentSource(Map<String, dynamic> json) {
    return SalesReceiptAdjustmentSourceDto(
      sourceKind: _string(json, 'sourceKind'),
      sourceId: _string(json, 'sourceId'),
      amount: _money(_map(json['amount'])),
    );
  }

  static SalesReceiptLineDto _line(Map<String, dynamic> json) {
    return SalesReceiptLineDto(
      lineId: _string(json, 'lineId'),
      product: ProductSnapshotDto(
        productId: _string(_map(json['product']), 'productId'),
        sku: _nullableString(_map(json['product'])['sku']),
        displayName: _string(_map(json['product']), 'displayName'),
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: _string(_map(json['unit']), 'productUnitId'),
        unitCode: _nullableString(_map(json['unit'])['unitCode']),
        unitName: _string(_map(json['unit']), 'unitName'),
      ),
      quantity: QuantityDto(quantityMicros: _int(json['quantityMicros'])),
      unitPrice: _money(_map(json['unitPrice'])),
      discountTotal: _money(_map(json['discountTotal'])),
      lineTotal: _money(_map(json['lineTotal'])),
    );
  }

  static PaymentIntentSummaryDto _payment(Map<String, dynamic> json) {
    return PaymentIntentSummaryDto(
      method: _paymentMethod(_string(json, 'method')),
      amount: _money(_map(json['amount'])),
      status: _paymentStatus(_string(json, 'status')),
    );
  }

  static Map<String, dynamic> _activityParams({
    required String commandId,
    required String tenantId,
    required String actorId,
    required String receiptId,
    required String activityType,
    required String idempotencyKey,
    String? payloadHash,
    String? correlationId,
    String? causationId,
    int? expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'p_command_id': commandId,
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_receipt_id': receiptId,
      'p_activity_type': activityType,
      'p_idempotency_key': idempotencyKey,
      'p_payload_hash': payloadHash,
      'p_correlation_id': correlationId,
      'p_causation_id': causationId,
      'p_expected_source_version': expectedSourceVersion,
    };
  }

  static SalesReceiptStatus _receiptStatus(String value) {
    return switch (value) {
      'generated' => SalesReceiptStatus.generated,
      'superseded' => SalesReceiptStatus.superseded,
      'archived' => SalesReceiptStatus.archived,
      _ => throw FormatException('Unknown sales receipt status: $value.'),
    };
  }

  static SalesPaymentMethod _paymentMethod(String value) {
    return switch (value) {
      'cash' => SalesPaymentMethod.cash,
      'manualBankTransfer' => SalesPaymentMethod.manualBankTransfer,
      _ => throw FormatException('Unknown sales payment method: $value.'),
    };
  }

  static SalesPaymentStatus _paymentStatus(String value) {
    return switch (value) {
      'pending' => SalesPaymentStatus.pending,
      'confirmed' => SalesPaymentStatus.confirmed,
      'failed' => SalesPaymentStatus.failed,
      'voided' => SalesPaymentStatus.voided,
      _ => throw FormatException('Unknown sales payment status: $value.'),
    };
  }

  static StoreSnapshotDto _store(Map<String, dynamic> json) {
    return StoreSnapshotDto(
      storeId: _string(json, 'storeId'),
      storeCode: _string(json, 'storeCode'),
      displayName: _string(json, 'displayName'),
    );
  }

  static ActorSnapshotDto _actor(Map<String, dynamic> json) {
    return ActorSnapshotDto(
      actorId: _string(json, 'actorId'),
      displayName: _string(json, 'displayName'),
    );
  }

  static CustomerSnapshotDto _customer(Map<String, dynamic> json) {
    return CustomerSnapshotDto(
      customerId: _string(json, 'customerId'),
      displayName: _string(json, 'displayName'),
      phoneNumber: _nullableString(json['phoneNumber']),
      taxCode: _nullableString(json['taxCode']),
      existingDebtMinor: _optionalInt(json['existingDebtMinor']) ?? 0,
    );
  }

  static MoneyDto _money(Map<String, dynamic> json) {
    return MoneyDto(
      amountMinor: _int(json['amountMinor']),
      currencyCode: _string(json, 'currencyCode'),
    );
  }

  static List<Map<String, dynamic>> _array(Object? value, String field) {
    if (value is! List) throw FormatException('Expected JSON array field $field.');
    return value.map(_map).toList(growable: false);
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

  static int? _optionalInt(Object? value) => value == null ? null : _int(value);

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Expected nullable string value, got $value.');
  }

  static DateTime _dateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected required timestamp value, got $value.');
    }
    return DateTime.parse(value).toUtc();
  }

  static DateTime? _nullableDateTime(Object? value) => value == null ? null : _dateTime(value);
}
