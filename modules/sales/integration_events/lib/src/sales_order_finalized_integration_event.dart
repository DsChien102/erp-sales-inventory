import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Integration event published when a sales order is finalized (canonical TH-05 fact).
final class SalesOrderFinalizedIntegrationEvent extends TenantScopedIntegrationEvent {
  const SalesOrderFinalizedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.salesOrderId,
    required this.sourceVersion,
  }) : super(eventType: type);

  static const String type = 'sales_order_finalized.v1';

  final String salesOrderId;
  final String sourceVersion;

  @override
  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': tenantId,
      'salesOrderId': salesOrderId,
      'salesOrderVersion': int.parse(sourceVersion),
      'event_type': type,
    };
  }

  factory SalesOrderFinalizedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final id = _requireNonEmptyString(
      json['id'] ?? json['idempotency_key'],
      'id',
    );
    final tenantId = _requireNonEmptyString(
      json['tenant_id'] ?? json['tenantId'],
      'tenant_id',
    );
    final salesOrderId = _requireNonEmptyString(
      json['salesOrderId'] ?? json['sales_order_id'],
      'salesOrderId',
    );
    final sourceVersion = _resolveSourceVersion(json);

    final occurredOnRaw = json['occurred_on'] ?? json['occurredOn'];
    final DateTime occurredOn;
    if (occurredOnRaw is String && occurredOnRaw.trim().isNotEmpty) {
      occurredOn = DateTime.parse(occurredOnRaw).toUtc();
    } else if (occurredOnRaw is DateTime) {
      occurredOn = occurredOnRaw.toUtc();
    } else {
      throw const FormatException(
        'SalesOrderFinalizedIntegrationEvent missing occurred_on',
      );
    }

    return SalesOrderFinalizedIntegrationEvent(
      id: id,
      occurredOn: occurredOn,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      sourceVersion: sourceVersion,
    );
  }

  /// Reads version keys in priority order; missing all defaults to checkout `1`.
  static String _resolveSourceVersion(Map<String, dynamic> json) {
    final raw =
        json['salesOrderVersion'] ??
        json['sales_order_version'] ??
        json['sourceVersion'] ??
        json['source_version'];
    if (raw == null) {
      return '1';
    }
    if (raw is int) {
      return raw.toString();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return '1';
  }

  static String _requireNonEmptyString(Object? value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'SalesOrderFinalizedIntegrationEvent missing or empty $fieldName',
      );
    }
    return value.trim();
  }
}
