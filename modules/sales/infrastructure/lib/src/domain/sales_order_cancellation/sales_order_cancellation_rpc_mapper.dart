import 'package:vet45_sales_application/application.dart';

/// Maps S23–S27 cancellation contracts to/from the `sales.*` RPC wire shape.
/// Parameters are snake_case; RPC results use camelCase field names.
abstract final class SalesOrderCancellationRpcMapper {
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

  static const _detailKeys = <String>{
    'result',
    'reason',
    'cancelledAt',
    'cancelledByActorId',
    'cancelledByActorName',
    'netConfirmedCollectionMinor',
  };

  // Accept legacy response codes during rollout, but never expose them.
  static const _reasonKeys = <String>{'reasonCode', 'reasonText'};

  static const _reasonPolicyEnvelopeKeys = <String>{'items'};

  static const _reasonPolicyKeys = <String>{
    'reasonCode',
    'displayName',
    'requiresNote',
    'sortOrder',
  };

  static const _blockerKeys = <String>{'code', 'message', 'field'};

  static Map<String, dynamic> listReasonsParams(
    ListSalesOrderCancellationReasonsQuery query,
  ) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
    };
  }

  static List<CancellationReasonPolicyDto> reasonsFromJson(
    Map<String, dynamic> json,
  ) {
    _rejectUnknownKeys(json, _reasonPolicyEnvelopeKeys);
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Expected items list.');
    }
    return items.map(_reasonPolicyFromJson).toList(growable: false);
  }

  static CancellationReasonPolicyDto _reasonPolicyFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected reason policy object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _reasonPolicyKeys);
    return CancellationReasonPolicyDto(
      reasonCode: _string(json, 'reasonCode'),
      displayName: _string(json, 'displayName'),
      requiresNote: _bool(json, 'requiresNote'),
      sortOrder: _int(json['sortOrder']),
    );
  }

  static Map<String, dynamic> precheckParams(
    PrecheckSalesOrderCancellationQuery query,
  ) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'sales_order_id': query.salesOrderId,
      'expected_source_version': query.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> confirmParams(
    ConfirmSalesOrderCancellationCommand command,
  ) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'sales_order_id': command.salesOrderId,
      'reason_text': command.reason.reasonText,
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_order_version': command.expectedVersion,
      'expected_settlement_version': command.expectedSettlementVersion,
    };
  }

  static Map<String, dynamic> detailParams(GetSalesOrderCancellationQuery query) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'sales_order_id': query.salesOrderId,
      'expected_source_version': query.expectedSourceVersion,
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

  static SalesOrderCancellationDetailDto detailFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _detailKeys);
    final result = json['result'];
    final reason = json['reason'];
    if (result is! Map) {
      throw const FormatException('Expected result object.');
    }
    if (reason is! Map) {
      throw const FormatException('Expected reason object.');
    }
    return SalesOrderCancellationDetailDto(
      result: resultFromJson(result.cast<String, dynamic>()),
      reason: _reasonFromJson(reason.cast<String, dynamic>()),
      cancelledAt: DateTime.parse(_string(json, 'cancelledAt')).toUtc(),
      cancelledByActorId: _string(json, 'cancelledByActorId'),
      cancelledByActorName: _nullableString(json, 'cancelledByActorName')?.trim() ?? '',
      netConfirmedCollectionMinor: _int(json['netConfirmedCollectionMinor']),
    );
  }

  static CancellationReasonDto _reasonFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _reasonKeys);
    return CancellationReasonDto(
      // Cancellation reason is optional.
      reasonText: _requiredStringAllowBlank(json, 'reasonText'),
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

  /// Required string key that may be blank (rejects missing / null / non-string).
  static String _requiredStringAllowBlank(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
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
