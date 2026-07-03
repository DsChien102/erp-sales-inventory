import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'partner_transaction_history_event_payload.dart';

/// Consumed from `inventory.inbound.recorded` — supplier role history.
final class InventoryInboundRecordedIntegrationEvent
    extends TenantScopedIntegrationEvent {
  const InventoryInboundRecordedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.businessPartnerId,
    required this.inboundId,
    this.inboundCode,
    this.amount,
    this.status,
    this.description,
    this.transactionDate,
  }) : super(eventType: type);

  static const type = 'inventory.inbound.recorded';

  final String businessPartnerId;
  final String inboundId;
  final String? inboundCode;
  final double? amount;
  final String? status;
  final String? description;
  final DateTime? transactionDate;

  factory InventoryInboundRecordedIntegrationEvent.fromInbox({
    required String messageId,
    required DateTime occurredOn,
    required Map<String, dynamic> payload,
  }) {
    final normalized = normalizeIntegrationEventJson({
      ...payload,
      'id': messageId,
    });
    return InventoryInboundRecordedIntegrationEvent(
      id: messageId,
      occurredOn: occurredOn,
      tenantId: PartnerTransactionHistoryEventPayload.requireTenantId(normalized),
      businessPartnerId:
          PartnerTransactionHistoryEventPayload.requireBusinessPartnerId(
        normalized,
      ),
      inboundId: normalized['inbound_id'] as String? ??
          PartnerTransactionHistoryEventPayload.requireSourceId(normalized),
      inboundCode: normalized['inbound_code'] as String? ??
          normalized['source_code'] as String?,
      amount: (normalized['amount'] as num?)?.toDouble(),
      status: normalized['status'] as String?,
      description: normalized['description'] as String?,
      transactionDate: PartnerTransactionHistoryEventPayload.resolveTransactionDate(
        normalized,
      ),
    );
  }

  @override
  Map<String, dynamic> toPayload() => {
        'id': id,
        'occurred_on': occurredOn.toUtc().toIso8601String(),
        'tenant_id': tenantId,
        'business_partner_id': businessPartnerId,
        'inbound_id': inboundId,
        if (inboundCode != null) 'inbound_code': inboundCode,
        if (amount != null) 'amount': amount,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
        if (transactionDate != null)
          'transaction_date': transactionDate!.toUtc().toIso8601String(),
      };
}
