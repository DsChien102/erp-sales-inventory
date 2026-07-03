import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../events/accounting_payable_created_integration_event.dart';
import '../events/accounting_receivable_created_integration_event.dart';
import '../events/inventory_inbound_recorded_integration_event.dart';
import '../events/sales_order_checked_out_integration_event.dart';

/// Deserializes inbound partner-consumed integration events by wire `event_type`.
abstract final class PartnerIntegrationEventRegistry {
  /// Returns the typed event for a claimed inbox row, or `null` when the
  /// `event_type` is not consumed by the partner module (poison message).
  static TenantScopedIntegrationEvent? fromInbox({
    required String eventType,
    required String messageId,
    required DateTime occurredOn,
    required Map<String, dynamic> payload,
  }) {
    return switch (eventType) {
      SalesOrderCheckedOutIntegrationEvent.type =>
        SalesOrderCheckedOutIntegrationEvent.fromInbox(
          messageId: messageId,
          occurredOn: occurredOn,
          payload: payload,
        ),
      InventoryInboundRecordedIntegrationEvent.type =>
        InventoryInboundRecordedIntegrationEvent.fromInbox(
          messageId: messageId,
          occurredOn: occurredOn,
          payload: payload,
        ),
      AccountingReceivableCreatedIntegrationEvent.type =>
        AccountingReceivableCreatedIntegrationEvent.fromInbox(
          messageId: messageId,
          occurredOn: occurredOn,
          payload: payload,
        ),
      AccountingPayableCreatedIntegrationEvent.type =>
        AccountingPayableCreatedIntegrationEvent.fromInbox(
          messageId: messageId,
          occurredOn: occurredOn,
          payload: payload,
        ),
      _ => null,
    };
  }
}
