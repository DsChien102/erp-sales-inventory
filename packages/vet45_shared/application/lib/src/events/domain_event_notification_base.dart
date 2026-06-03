import 'package:vet45_shared_application/src/events/i_domain_event_notification.dart';

class DomainEventNotificationBase<T> implements IDomainEventNotification<T> {
  @override
  final T domainEvent;

  @override
  String id;

  DomainEventNotificationBase(this.domainEvent, this.id);
}
