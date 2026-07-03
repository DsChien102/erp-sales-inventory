import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'partner_transaction_history_event_payload.dart';

final class AccountingReceivableCreatedIntegrationEvent
    extends TenantScopedIntegrationEvent {
  const AccountingReceivableCreatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.businessPartnerId,
    required this.receivableId,
    this.receivableCode,
    this.amount,
    this.status,
    this.description,
    this.transactionDate,
  }) : super(eventType: type);

  static const type = 'accounting.receivable.created';

  final String businessPartnerId;
  final String receivableId;
  final String? receivableCode;
  final double? amount;
  final String? status;
  final String? description;
  final DateTime? transactionDate;

  factory AccountingReceivableCreatedIntegrationEvent.fromInbox({
    required String messageId,
    required DateTime occurredOn,
    required Map<String, dynamic> payload,
  }) {
    final normalized = normalizeIntegrationEventJson({
      ...payload,
      'id': messageId,
    });
    return AccountingReceivableCreatedIntegrationEvent(
      id: messageId,
      occurredOn: occurredOn,
      tenantId: PartnerTransactionHistoryEventPayload.requireTenantId(normalized),
      businessPartnerId:
          PartnerTransactionHistoryEventPayload.requireBusinessPartnerId(
        normalized,
      ),
      receivableId: normalized['receivable_id'] as String? ??
          PartnerTransactionHistoryEventPayload.requireSourceId(normalized),
      receivableCode: normalized['receivable_code'] as String? ??
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
        'receivable_id': receivableId,
        if (receivableCode != null) 'receivable_code': receivableCode,
        if (amount != null) 'amount': amount,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
        if (transactionDate != null)
          'transaction_date': transactionDate!.toUtc().toIso8601String(),
      };
}
