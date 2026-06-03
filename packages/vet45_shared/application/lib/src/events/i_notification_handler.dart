import 'i_domain_event_notification.dart';

/// Handles a domain event notification raised from outbox processing.
abstract interface class INotificationHandler<TNotification extends IDomainEventNotification> {
  Future<void> handle(TNotification notification);
}
