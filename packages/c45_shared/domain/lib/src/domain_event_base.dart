import 'domain_event.dart';
import 'package:uuid/uuid.dart';

class DomainEventBase implements IDomainEvent {
  late final String _id;
  late final DateTime _occurredOn;

  DomainEventBase() {
    _id = Uuid().v7();
    _occurredOn = DateTime.now();
  }

  @override
  String get id => _id;

  @override
  DateTime get occurredOn => _occurredOn;
}
