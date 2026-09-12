import 'package:vet45_sales_application/application.dart';

abstract final class CheckoutPrecheckRpcMapper {
  static Map<String, dynamic> precheckParams(
    PrecheckSalesOrderCheckoutQuery query,
  ) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_store_id': query.storeId,
      'p_customer_id': query.customerId,
      'p_currency_code': query.currencyCode.trim().toUpperCase(),
      'p_payment_due_date': _dateOnly(query.paymentDueDate),
      'p_lines': _lineInputs(query.lines),
      'p_payment_intents': _paymentIntents(query.paymentIntents),
      if (query.expectedSourceVersion != null)
        'p_expected_source_version': query.expectedSourceVersion,
    };
  }

  static CheckoutPrecheckDto precheckFromJson(Map<String, dynamic> json) {
    final blockers = json['blockers'];
    return CheckoutPrecheckDto(
      canFinalize: json['canFinalize'] as bool? ?? false,
      blockers: blockers is List
          ? blockers
                .whereType<Map>()
                .map((item) => _blocker(item.cast<String, dynamic>()))
                .toList(growable: false)
          : const <SalesBlockerDto>[],
      monetarySummary: _summary(_map(json['monetarySummary'])),
      receivableRequirement: _receivable(
        _map(json['receivableRequirement']),
      ),
    );
  }

  static Map<String, dynamic> finalizeParams(FinalizeSalesOrderCommand command) {
    return <String, dynamic>{
      'p_command_id': command.id,
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_store_id': command.storeId,
      'p_source_draft_id': command.sourceDraftId,
      'p_customer_id': command.customerId,
      'p_currency_code': command.currencyCode.trim().toUpperCase(),
      'p_order_note': command.orderNote,
      'p_payment_due_date': _dateOnly(command.paymentDueDate),
      'p_commercial_snapshot': _commercialSnapshot(command.commercialSnapshot),
      'p_lines': _lineInputs(command.lines),
      'p_payment_intents': _paymentIntents(command.paymentIntents),
      'p_idempotency_key': command.idempotencyKey,
      'p_payload_hash': command.payloadHash,
      'p_correlation_id': command.correlationId,
      'p_causation_id': command.causationId,
      if (command.expectedSourceVersion != null)
        'p_expected_source_version': command.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> statusParams(GetCheckoutResultQuery query) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_idempotency_key': query.idempotencyKey,
      'p_store_id': query.storeId,
    };
  }

  static CheckoutResultDto checkoutResultFromJson(Map<String, dynamic> json) {
    return CheckoutResultDto(
      idempotencyKey: _string(json, 'idempotencyKey'),
      salesOrderId: json['salesOrderId'] as String? ?? '',
      salesOrderVersion: _int(json['salesOrderVersion']),
      status: _checkoutAttemptStatus(_string(json, 'status')),
    );
  }

  static CheckoutResultStatus _checkoutAttemptStatus(String value) {
    return switch (value) {
      'processing' => CheckoutResultStatus.processing,
      'succeeded' => CheckoutResultStatus.succeeded,
      'blocked' => CheckoutResultStatus.blocked,
      'failed' => CheckoutResultStatus.failed,
      'uncertain' => CheckoutResultStatus.uncertain,
      _ => throw FormatException('Unknown checkout attempt status: $value.'),
    };
  }

  static List<Map<String, dynamic>> _lineInputs(List<CheckoutLineInput> lines) {
    return [
      for (final line in lines)
        <String, dynamic>{
          'product_id': line.productId,
          'product_unit_id': line.productUnitId,
          'quantity_micros': line.quantity.quantityMicros,
          'unit_price': line.unitPrice == null ? null : _money(line.unitPrice!),
          'note': line.note,
        },
    ];
  }

  static List<Map<String, dynamic>> _paymentIntents(
    List<PaymentIntentInput> intents,
  ) {
    return [
      for (final intent in intents)
        <String, dynamic>{
          'method': _paymentMethod(intent.method),
          'amount': _money(intent.amount),
          'reference': intent.reference,
        },
    ];
  }

  static Map<String, dynamic> _money(MoneyDto money) {
    return <String, dynamic>{
      'amount_minor': money.amountMinor,
      'currency_code': money.currencyCode,
    };
  }

  static Map<String, Object?> _commercialSnapshot(SalesCommercialSnapshotInput snapshot) =>
      <String, Object?>{
        'store': <String, Object?>{
          'storeId': snapshot.store.storeId.trim(),
          'storeCode': snapshot.store.storeCode.trim(),
          'displayName': snapshot.store.displayName.trim(),
        },
        'seller': <String, Object?>{
          'actorId': snapshot.seller.actorId.trim(),
          'displayName': snapshot.seller.displayName.trim(),
        },
        'customer': snapshot.customer == null
            ? null
            : <String, Object?>{
                'customerId': snapshot.customer!.customerId.trim(),
                'displayName': snapshot.customer!.displayName.trim(),
                'phoneNumber': _trimToNull(snapshot.customer!.phoneNumber),
                'taxCode': _trimToNull(snapshot.customer!.taxCode),
              },
        'lines': [
          for (final line in snapshot.lines)
            <String, Object?>{
              'lineId': line.lineId.trim(),
              'product': <String, Object?>{
                'productId': line.product.productId.trim(),
                'sku': _trimToNull(line.product.sku),
                'displayName': line.product.displayName.trim(),
              },
              'unit': <String, Object?>{
                'productUnitId': line.unit.productUnitId.trim(),
                'unitCode': _trimToNull(line.unit.unitCode),
                'unitName': line.unit.unitName.trim(),
              },
              'quantityMicros': line.quantity.quantityMicros,
              'unitPrice': _commercialMoney(line.unitPrice),
              'discountTotal': _commercialMoney(line.discountTotal),
              'lineTotal': _commercialMoney(line.lineTotal),
            },
        ],
      };

  static Map<String, Object?> _commercialMoney(MoneyDto money) => <String, Object?>{
    'amountMinor': money.amountMinor,
    'currencyCode': money.currencyCode.trim().toUpperCase(),
  };

  static String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final date = DateTime(value.year, value.month, value.day);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static SalesBlockerDto _blocker(Map<String, dynamic> json) {
    return SalesBlockerDto(
      code: _string(json, 'code'),
      message: _string(json, 'message'),
      field: json['field'] as String?,
    );
  }

  static CheckoutMonetarySummaryDto _summary(Map<String, dynamic> json) {
    return CheckoutMonetarySummaryDto(
      subtotal: _moneyFromJson(_map(json['subtotal'])),
      discountTotal: _moneyFromJson(_map(json['discountTotal'])),
      grandTotal: _moneyFromJson(_map(json['grandTotal'])),
    );
  }

  static ReceivableRequirementDto _receivable(Map<String, dynamic> json) {
    return ReceivableRequirementDto(
      isRequired: json['isRequired'] as bool? ?? false,
      amount: _moneyFromJson(_map(json['amount'])),
      customerId: json['customerId'] as String?,
    );
  }

  static MoneyDto _moneyFromJson(Map<String, dynamic> json) {
    return MoneyDto(
      amountMinor: _int(json['amountMinor']),
      currencyCode: _string(json, 'currencyCode'),
    );
  }

  static String _paymentMethod(SalesPaymentMethod method) {
    return switch (method) {
      SalesPaymentMethod.cash => 'cash',
      SalesPaymentMethod.manualBankTransfer => 'manualBankTransfer',
    };
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
}
