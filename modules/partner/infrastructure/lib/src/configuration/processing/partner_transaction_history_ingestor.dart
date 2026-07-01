import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

/// Maps consumed integration events to projection upsert commands.
final class PartnerTransactionHistoryIngestor {
  PartnerTransactionHistoryIngestor({
    required RecordPartnerTransactionHistoryCommandHandler recordHandler,
  }) : _recordHandler = recordHandler;

  final RecordPartnerTransactionHistoryCommandHandler _recordHandler;

  Future<void> ingest({
    required String eventType,
    required String messageId,
    required DateTime occurredOn,
    required Map<String, dynamic> payload,
  }) {
    return switch (eventType) {
      SalesOrderCheckedOutIntegrationEvent.type => _recordHandler.handle(
          _fromSalesOrder(messageId, occurredOn, payload),
        ),
      InventoryInboundRecordedIntegrationEvent.type => _recordHandler.handle(
          _fromInbound(messageId, occurredOn, payload),
        ),
      AccountingReceivableCreatedIntegrationEvent.type => _recordHandler.handle(
          _fromReceivable(messageId, occurredOn, payload),
        ),
      AccountingPayableCreatedIntegrationEvent.type => _recordHandler.handle(
          _fromPayable(messageId, occurredOn, payload),
        ),
      _ => throw UnsupportedError('Unsupported partner inbox event: $eventType'),
    };
  }

  RecordPartnerTransactionHistoryCommand _fromSalesOrder(
    String messageId,
    DateTime occurredOn,
    Map<String, dynamic> payload,
  ) {
    final event = SalesOrderCheckedOutIntegrationEvent.fromInbox(
      messageId: messageId,
      occurredOn: occurredOn,
      payload: payload,
    );
    return RecordPartnerTransactionHistoryCommand(
      tenantId: event.tenantId,
      businessPartnerId: event.businessPartnerId,
      transactionRole: PartnerRole.customer,
      sourceModule: 'sales',
      sourceType: 'order',
      sourceId: event.orderId,
      sourceCode: event.orderCode,
      transactionDate: event.transactionDate ?? event.occurredOn,
      amount: event.amount,
      status: event.status,
      description: event.description,
    );
  }

  RecordPartnerTransactionHistoryCommand _fromInbound(
    String messageId,
    DateTime occurredOn,
    Map<String, dynamic> payload,
  ) {
    final event = InventoryInboundRecordedIntegrationEvent.fromInbox(
      messageId: messageId,
      occurredOn: occurredOn,
      payload: payload,
    );
    return RecordPartnerTransactionHistoryCommand(
      tenantId: event.tenantId,
      businessPartnerId: event.businessPartnerId,
      transactionRole: PartnerRole.supplier,
      sourceModule: 'inventory',
      sourceType: 'inbound',
      sourceId: event.inboundId,
      sourceCode: event.inboundCode,
      transactionDate: event.transactionDate ?? event.occurredOn,
      amount: event.amount,
      status: event.status,
      description: event.description,
    );
  }

  RecordPartnerTransactionHistoryCommand _fromReceivable(
    String messageId,
    DateTime occurredOn,
    Map<String, dynamic> payload,
  ) {
    final event = AccountingReceivableCreatedIntegrationEvent.fromInbox(
      messageId: messageId,
      occurredOn: occurredOn,
      payload: payload,
    );
    return RecordPartnerTransactionHistoryCommand(
      tenantId: event.tenantId,
      businessPartnerId: event.businessPartnerId,
      transactionRole: PartnerRole.customer,
      sourceModule: 'accounting',
      sourceType: 'receivable',
      sourceId: event.receivableId,
      sourceCode: event.receivableCode,
      transactionDate: event.transactionDate ?? event.occurredOn,
      amount: event.amount,
      status: event.status,
      description: event.description,
    );
  }

  RecordPartnerTransactionHistoryCommand _fromPayable(
    String messageId,
    DateTime occurredOn,
    Map<String, dynamic> payload,
  ) {
    final event = AccountingPayableCreatedIntegrationEvent.fromInbox(
      messageId: messageId,
      occurredOn: occurredOn,
      payload: payload,
    );
    return RecordPartnerTransactionHistoryCommand(
      tenantId: event.tenantId,
      businessPartnerId: event.businessPartnerId,
      transactionRole: PartnerRole.supplier,
      sourceModule: 'accounting',
      sourceType: 'payable',
      sourceId: event.payableId,
      sourceCode: event.payableCode,
      transactionDate: event.transactionDate ?? event.occurredOn,
      amount: event.amount,
      status: event.status,
      description: event.description,
    );
  }
}
