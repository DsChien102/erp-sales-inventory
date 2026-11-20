import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/models.dart';

abstract final class SalesCancellationJson {
  static const _precheckKeys = <String>{
    'allowed',
    'sourceVersion',
    'sourceSettlementVersion',
    'blockers',
  };

  static const _resultKeys = <String>{
    'cancellationId',
    'salesOrderId',
    'salesOrderVersion',
    'status',
  };

  static const _blockerKeys = <String>{'code', 'message', 'field'};

  static Map<String, dynamic> precheckParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': salesOrderId,
      'expected_source_version': expectedSourceVersion,
    };
  }

  static Map<String, dynamic> confirmParams({
    required SalesOrderCancellationRequest request,
    required String tenantId,
    required String actorId,
  }) {
    return <String, dynamic>{
      'command_id': request.commandId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': request.salesOrderId,
      'reason_text': request.reasonText,
      'idempotency_key': request.idempotencyKey,
      'payload_hash': request.payloadHash,
      'correlation_id': request.correlationId,
      'causation_id': null,
      'expected_order_version': request.expectedOrderVersion,
      'expected_settlement_version': request.expectedSettlementVersion,
    };
  }

  static CancellationPrecheckDto precheckFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _precheckKeys);
    return CancellationPrecheckDto(
      allowed: _bool(json, 'allowed'),
      sourceVersion: _int(json['sourceVersion']),
      sourceSettlementVersion: _int(json['sourceSettlementVersion']),
      blockers: _blockers(json['blockers']),
    );
  }

  static SalesOrderCancellationResultDto resultFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _resultKeys);
    return SalesOrderCancellationResultDto(
      cancellationId: _string(json, 'cancellationId'),
      salesOrderId: _string(json, 'salesOrderId'),
      salesOrderVersion: _int(json['salesOrderVersion']),
      status: _status(_string(json, 'status')),
    );
  }

  static List<SalesBlockerDto> _blockers(Object? value) {
    if (value is! List) {
      throw const FormatException('Expected blockers list.');
    }
    return value.map(_blockerFromJson).toList(growable: false);
  }

  static SalesBlockerDto _blockerFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected blocker object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _blockerKeys);
    return SalesBlockerDto(
      code: _string(json, 'code'),
      message: _string(json, 'message'),
      field: _nullableString(json, 'field'),
    );
  }

  static SalesOrderCancellationStatus _status(String value) => switch (value) {
    'confirmed' => SalesOrderCancellationStatus.confirmed,
    'processing' => SalesOrderCancellationStatus.processing,
    'completed' => SalesOrderCancellationStatus.completed,
    'failed' => SalesOrderCancellationStatus.failed,
    _ => throw FormatException('Unknown cancellation status: $value.'),
  };

  static void _rejectUnknownKeys(Map<String, dynamic> json, Set<String> allowed) {
    for (final key in json.keys) {
      if (!allowed.contains(key)) {
        throw FormatException('Unexpected field $key.');
      }
    }
  }

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Expected required bool field $key.');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected required string field $key.');
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('Expected nullable string field $key.');
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected integer value, got $value.');
  }
}

