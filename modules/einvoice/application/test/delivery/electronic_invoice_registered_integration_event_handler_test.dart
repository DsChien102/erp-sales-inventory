import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeDispatcher implements IEinvoiceCommandDispatcher {
  final List<StartAutoDeliveryCommand> startCalls = [];

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    switch (command) {
      case StartAutoDeliveryCommand c:
        startCalls.add(c);
        return const AutoDeliveryResultDto(
              disposition: AutoDeliveryDisposition.started,
              deliveryId: 'del-1',
            )
            as TResult;
      default:
        throw UnsupportedError('${command.runtimeType}');
    }
  }
}

void main() {
  group('ElectronicInvoiceRegisteredIntegrationEventHandler', () {
    test('dispatches StartAutoDeliveryCommand with event id as triggerId', () async {
      final dispatcher = _FakeDispatcher();
      final handler = ElectronicInvoiceRegisteredIntegrationEventHandler(
        commands: dispatcher,
      );

      final event = ElectronicInvoiceRegisteredIntegrationEvent(
        id: 'event-001',
        occurredOn: DateTime.utc(2026, 9, 2, 10),
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-99',
        salesOrderId: 'so-1',
      );

      await handler.handle(event);

      expect(dispatcher.startCalls, hasLength(1));
      final cmd = dispatcher.startCalls.single;
      expect(cmd.tenantId, 'tenant-1');
      expect(cmd.electronicInvoiceId, 'ei-99');
      expect(cmd.triggerId, 'event-001');
      expect(
        cmd.idempotencyKey,
        AutoDeliveryIdempotencyKey.generate(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'ei-99',
        ),
      );
    });

    test('duplicate registered events derive the same UUIDv5 auto key', () async {
      final dispatcher = _FakeDispatcher();
      final handler = ElectronicInvoiceRegisteredIntegrationEventHandler(
        commands: dispatcher,
      );

      final first = ElectronicInvoiceRegisteredIntegrationEvent(
        id: 'event-a',
        occurredOn: DateTime.utc(2026, 9, 2, 10),
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-99',
        salesOrderId: 'so-1',
      );
      final second = ElectronicInvoiceRegisteredIntegrationEvent(
        id: 'event-b',
        occurredOn: DateTime.utc(2026, 9, 2, 11),
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-99',
        salesOrderId: 'so-1',
      );

      await handler.handle(first);
      await handler.handle(second);

      expect(dispatcher.startCalls, hasLength(2));
      expect(
        dispatcher.startCalls[0].idempotencyKey,
        dispatcher.startCalls[1].idempotencyKey,
      );
      expect(dispatcher.startCalls[0].triggerId, 'event-a');
      expect(dispatcher.startCalls[1].triggerId, 'event-b');
    });
  });
}
