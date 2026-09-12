import 'package:vet45_sales_application/application.dart';

/// Maps S13 read queries/results to/from the `sales.*` read RPC wire shape.
/// Params are p-prefixed snake_case; result envelopes are camelCase (enum wire
/// values are the Dart enum `.name`, e.g. `partiallyPaid`, `notRequired`,
/// `completed`).
abstract final class SalesOrderReadRpcMapper {
  static Map<String, dynamic> getSalesOrderParams(GetSalesOrderQuery query) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_sales_order_id': query.salesOrderId,
    };
  }

  static Map<String, dynamic> paymentSummaryParams(
    GetSalesOrderPaymentSummaryQuery query,
  ) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_sales_order_id': query.salesOrderId,
      if (query.expectedSourceVersion != null)
        'p_expected_source_version': query.expectedSourceVersion,
    };
  }

  static SalesOrderResultDto salesOrderResultFromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return SalesOrderResultDto(
      order: salesOrderFromJson(_map(json['order'])),
      committedAt: _dateTime(json['committedAt']),
      store: _store(_map(json['store'])),
      seller: _actor(_map(json['seller'])),
      customer: customer == null ? null : _customer(_map(customer)),
    );
  }

  static SalesOrderDto salesOrderFromJson(Map<String, dynamic> json) {
    return SalesOrderDto(
      salesOrderId: _string(json, 'salesOrderId'),
      orderNumber: _string(json, 'orderNumber'),
      version: _int(json['version']),
      lifecycleStatus: _lifecycleStatus(_string(json, 'lifecycleStatus')),
      lockStatus: _lockStatus(_string(json, 'lockStatus')),
      total: _money(_map(json['total'])),
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
                    paidCashExtra: paidCashExtra == null
                        ? null
                        : _money(_map(paidCashExtra)),
                    paidBankExtra: paidBankExtra == null
                        ? null
                        : _money(_map(paidBankExtra)),
                  );
                })
                .toList(growable: false),
    );
  }

  static SalesOrderLifecycleStatus _lifecycleStatus(String value) {
    return switch (value) {
      'completed' => SalesOrderLifecycleStatus.completed,
      'cancelled' => SalesOrderLifecycleStatus.cancelled,
      _ => throw FormatException('Unknown sales order lifecycle status: $value.'),
    };
  }

  static SalesOrderLockStatus _lockStatus(String value) {
    return switch (value) {
      'unlocked' => SalesOrderLockStatus.unlocked,
      'locked' => SalesOrderLockStatus.locked,
      _ => throw FormatException('Unknown sales order lock status: $value.'),
    };
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

  static MoneyDto _money(Map<String, dynamic> json) {
    return MoneyDto(
      amountMinor: _int(json['amountMinor']),
      currencyCode: _string(json, 'currencyCode'),
    );
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
}
