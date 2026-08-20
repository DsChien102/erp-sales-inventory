/// iam integration event contracts.
library;

// Inbox handler contract re-exported here so the application layer can implement
// integration-event consumers without importing the infrastructure package
// directly (mirrors the codegen golden fixture layout).
export 'package:vet45_shared_infrastructure/infrastructure.dart'
    show IIntegrationEventNotificationHandler, IntegrationEvent;

export 'src/events/email_delivery_requested_integration_event.dart';
export 'src/events/membership_deactivated_integration_event.dart';
