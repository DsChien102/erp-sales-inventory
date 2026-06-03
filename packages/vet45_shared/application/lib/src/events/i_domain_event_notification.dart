abstract interface class IDomainEventNotification<TEventType> {
  TEventType get domainEvent;
  String get id;
}
