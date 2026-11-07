import 'package:vet45_sales_application/application.dart';

/// Dựng tham số + đọc JSON của `get_sales_order` (chép từ SalesOrderReadRpcMapper).
/// 8-A3 mở rộng cho list / search / detail / timeline.
abstract final class SalesOrderGetJson {
  static Map<String, dynamic> params({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) {
    return <String, dynamic>{
      'p_query_id': queryId,
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
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

  static DateTime _dateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected required timestamp value, got $value.');
    }
    return DateTime.parse(value).toUtc();
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

  static int? _optionalInt(Object? value) => value == null ? null : _int(value);

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Expected nullable string value, got $value.');
  }
}
