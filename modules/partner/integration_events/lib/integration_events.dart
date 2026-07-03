/// partner integration events — add contracts here.
library;

// Re-export the consumer-handler contract so module application handlers can
// depend on it without importing the shared infrastructure package directly
// (keeps the application layer free of *_infrastructure imports).
export 'package:vet45_shared_infrastructure/infrastructure.dart'
    show IIntegrationEventNotificationHandler;

export 'src/events/accounting_payable_created_integration_event.dart';
export 'src/events/accounting_receivable_created_integration_event.dart';
export 'src/events/inventory_inbound_recorded_integration_event.dart';
export 'src/events/partner_transaction_history_event_payload.dart';
export 'src/events/sales_order_checked_out_integration_event.dart';
export 'src/serialization/partner_integration_event_registry.dart';
