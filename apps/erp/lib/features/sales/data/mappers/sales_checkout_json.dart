import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/models.dart';

/// Dựng tham số RPC + đọc JSON của precheck / finalize / get_checkout_result
/// (chép từ CheckoutPrecheckRpcMapper). Trả DTO của `data/models.dart` (Q1).
abstract final class SalesCheckoutJson {
  static Map<String, dynamic> precheckParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String storeId,
    String? customerId,
    required String currencyCode,
    DateTime? paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    int? expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'p_query_id': queryId,
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_store_id': storeId,
      'p_customer_id': customerId,
      'p_currency_code': currencyCode.trim().toUpperCase(),
      'p_payment_due_date': _dateOnly(paymentDueDate),
      'p_lines': _lineInputs(lines),
      'p_payment_intents': _paymentIntents(paymentIntents),
      'p_expected_source_version': ?expectedSourceVersion,
    };
  }

  static Map<String, dynamic> finalizeParams(
    SalesFinalizeRequest request, {
    required String tenantId,
    required String actorId,
  }) {
    return <String, dynamic>{
      'p_command_id': request.commandId,
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_store_id': request.storeId,
      'p_source_draft_id': request.sourceDraftId,
      'p_customer_id': request.customerId,
      'p_currency_code': request.currencyCode.trim().toUpperCase(),
      'p_order_note': request.orderNote,
      'p_payment_due_date': _dateOnly(request.paymentDueDate),
      'p_commercial_snapshot': _commercialSnapshot(request.commercialSnapshot),
      'p_lines': _lineInputs(request.lines),
      'p_payment_intents': _paymentIntents(request.paymentIntents),
      'p_idempotency_key': request.idempotencyKey,
      'p_payload_hash': request.payloadHash,
      'p_correlation_id': request.correlationId,
      'p_causation_id': null,
      'p_expected_source_version': ?request.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> statusParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String idempotencyKey,
    required String storeId,
  }) {
    return <String, dynamic>{
      'p_query_id': queryId,
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_idempotency_key': idempotencyKey,
      'p_store_id': storeId,
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

  static CheckoutResultDto checkoutResultFromJson(Map<String, dynamic> json) {
    return CheckoutResultDto(
      idempotencyKey: _string(json, 'idempotencyKey'),
      salesOrderId: json['salesOrderId'] as String? ?? '',
      salesOrderVersion: _int(json['salesOrderVersion']),
      status: _checkoutAttemptStatus(_string(json, 'status')),
      blockedCode: json['blockedCode'] as String?,
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
          'manual_unit_price_minor': line.manualUnitPriceMinor,
          'manual_discount_minor': line.manualDiscountMinor,
          'manual_discount_basis_points': line.manualDiscountBasisPoints,
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
                'buyerType': _trimToNull(snapshot.customer!.buyerType),
                'invoiceLegalName': _trimToNull(snapshot.customer!.invoiceLegalName),
                'invoiceAddress': _trimToNull(snapshot.customer!.invoiceAddress),
                'invoiceEmail': _trimToNull(snapshot.customer!.invoiceEmail),
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
