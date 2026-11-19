import 'package:c45_shared_infrastructure/infrastructure.dart';
import 'package:test/test.dart';

void main() {
  setUp(IntegrationEventTypeRegistry.clear);

  group('IntegrationEventBus', () {
    test('publishes to subscribed handlers', () async {
      IntegrationEventTypeRegistry.registerAll({
        _TestEvent: _TestEvent.type,
      });

      final bus = IntegrationEventBus();
      _TestEvent? receivedEvent;

      bus.subscribe<_TestEvent>(
        _TestIntegrationEventHandler((event) async {
          receivedEvent = event;
        }),
      );

      await bus.publish(
        _TestEvent(
          id: 'event-1',
          occurredOn: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(receivedEvent?.id, 'event-1');
    });
  });
}

final class _TestIntegrationEventHandler implements IIntegrationEventHandler<_TestEvent> {
  _TestIntegrationEventHandler(this._handle);

  final Future<void> Function(_TestEvent event) _handle;

  @override
  Future<void> handle(_TestEvent event) => _handle(event);
}

final class _TestEvent extends IntegrationEvent {
  _TestEvent({
    required super.id,
    required super.occurredOn,
  }) : super(eventType: type);

  static const type = 'test.event';
}
