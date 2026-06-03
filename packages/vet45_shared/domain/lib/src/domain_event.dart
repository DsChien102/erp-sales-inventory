/// Base class for all domain events published on the [EventBus].
///
/// Domain events are immutable value objects that record something that
/// happened within a module's domain boundary.  Subscribers act on them
/// without querying the publisher's data store.
abstract interface class IDomainEvent {
  String get id;
  DateTime get occurredOn;
}
