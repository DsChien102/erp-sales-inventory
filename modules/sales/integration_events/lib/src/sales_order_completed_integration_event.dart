import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Integration event published when a sales order is completed.
final class SalesOrderCompletedIntegrationEvent
    extends TenantScopedIntegrationEvent {
  const SalesOrderCompletedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.salesOrderId,
    required this.sourceVersion,
  }) : super(eventType: type);

  static const String type = 'sales.order.completed';

  final String salesOrderId;
  final String sourceVersion;

  @override
  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': tenantId,
      'sales_order_id': salesOrderId,
      'source_version': sourceVersion,
      'event_type': type,
    };
  }

  factory SalesOrderCompletedIntegrationEvent.fromPayload(
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
      json['sales_order_id'] ?? json['salesOrderId'],
      'sales_order_id',
    );
    final sourceVersion = _requireNonEmptyString(
      json['source_version'] ?? json['sourceVersion'],
      'source_version',
    );

    final occurredOnRaw = json['occurred_on'] ?? json['occurredOn'];
    final DateTime occurredOn;
    if (occurredOnRaw is String && occurredOnRaw.trim().isNotEmpty) {
      occurredOn = DateTime.parse(occurredOnRaw).toUtc();
    } else if (occurredOnRaw is DateTime) {
      occurredOn = occurredOnRaw.toUtc();
    } else {
      throw const FormatException(
        'SalesOrderCompletedIntegrationEvent missing occurred_on',
      );
    }

    return SalesOrderCompletedIntegrationEvent(
      id: id,
      occurredOn: occurredOn,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      sourceVersion: sourceVersion,
    );
  }

  static String _requireNonEmptyString(Object? value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'SalesOrderCompletedIntegrationEvent missing or empty $fieldName',
      );
    }
    return value.trim();
  }
}
