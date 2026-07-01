import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'partner_transaction_history_event_payload.dart';

/// Consumed from `sales.order.checked_out` — updates partner history as customer.
final class SalesOrderCheckedOutIntegrationEvent
    extends TenantScopedIntegrationEvent {
  const SalesOrderCheckedOutIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.businessPartnerId,
    required this.orderId,
    this.orderCode,
    this.amount,
    this.status,
    this.description,
    this.transactionDate,
  }) : super(eventType: type);

  static const type = 'sales.order.checked_out';

  final String businessPartnerId;
  final String orderId;
  final String? orderCode;
  final double? amount;
  final String? status;
  final String? description;
  final DateTime? transactionDate;

  factory SalesOrderCheckedOutIntegrationEvent.fromInbox({
    required String messageId,
    required DateTime occurredOn,
    required Map<String, dynamic> payload,
  }) {
    final normalized = normalizeIntegrationEventJson({
      ...payload,
      'id': messageId,
    });
    return SalesOrderCheckedOutIntegrationEvent(
      id: messageId,
      occurredOn: occurredOn,
      tenantId: PartnerTransactionHistoryEventPayload.requireTenantId(normalized),
      businessPartnerId:
          PartnerTransactionHistoryEventPayload.requireBusinessPartnerId(
        normalized,
      ),
      orderId: normalized['order_id'] as String? ??
          PartnerTransactionHistoryEventPayload.requireSourceId(normalized),
      orderCode: normalized['order_code'] as String? ??
          normalized['source_code'] as String?,
      amount: (normalized['amount'] as num?)?.toDouble() ??
          (normalized['total_amount'] as num?)?.toDouble(),
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
        'order_id': orderId,
        if (orderCode != null) 'order_code': orderCode,
        if (amount != null) 'amount': amount,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
        if (transactionDate != null)
          'transaction_date': transactionDate!.toUtc().toIso8601String(),
      };
}
