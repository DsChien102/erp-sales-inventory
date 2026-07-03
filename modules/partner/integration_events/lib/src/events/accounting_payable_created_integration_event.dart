import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'partner_transaction_history_event_payload.dart';

final class AccountingPayableCreatedIntegrationEvent
    extends TenantScopedIntegrationEvent {
  const AccountingPayableCreatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.businessPartnerId,
    required this.payableId,
    this.payableCode,
    this.amount,
    this.status,
    this.description,
    this.transactionDate,
  }) : super(eventType: type);

  static const type = 'accounting.payable.created';

  final String businessPartnerId;
  final String payableId;
  final String? payableCode;
  final double? amount;
  final String? status;
  final String? description;
  final DateTime? transactionDate;

  factory AccountingPayableCreatedIntegrationEvent.fromInbox({
    required String messageId,
    required DateTime occurredOn,
    required Map<String, dynamic> payload,
  }) {
    final normalized = normalizeIntegrationEventJson({
      ...payload,
      'id': messageId,
    });
    return AccountingPayableCreatedIntegrationEvent(
      id: messageId,
      occurredOn: occurredOn,
      tenantId: PartnerTransactionHistoryEventPayload.requireTenantId(normalized),
      businessPartnerId:
          PartnerTransactionHistoryEventPayload.requireBusinessPartnerId(
        normalized,
      ),
      payableId: normalized['payable_id'] as String? ??
          PartnerTransactionHistoryEventPayload.requireSourceId(normalized),
      payableCode: normalized['payable_code'] as String? ??
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
        'payable_id': payableId,
        if (payableCode != null) 'payable_code': payableCode,
        if (amount != null) 'amount': amount,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
        if (transactionDate != null)
          'transaction_date': transactionDate!.toUtc().toIso8601String(),
      };
}
