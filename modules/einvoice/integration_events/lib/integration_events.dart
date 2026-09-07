/// E-invoice integration event contracts for cross-module messaging.
library;

// Inbox handler contract re-exported here so the application layer can implement
// integration-event consumers without importing the infrastructure package
// directly.
export 'package:vet45_shared_infrastructure/infrastructure.dart'
    show IIntegrationEventNotificationHandler, IntegrationEvent;

export 'src/configuration_readiness_changed_integration_event.dart';
export 'src/delivery_attention_required_integration_event.dart';
export 'src/delivery_result_recorded_integration_event.dart';
export 'src/einvoice_integration_event.dart';
export 'src/electronic_invoice_registered_integration_event.dart';
export 'src/issuance_failed_integration_event.dart';
export 'src/issuance_processing_integration_event.dart';
export 'src/provider_issuance_result_received_integration_event.dart';
export 'src/provider_observation_attention_required_integration_event.dart';
