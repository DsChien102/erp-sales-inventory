import 'package:test/test.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';

void main() {
  group('SalesOrderFinalizedIntegrationEvent', () {
    test('parses canonical numeric SalesOrder version', () {
      final event = SalesOrderFinalizedIntegrationEvent.fromPayload({
        'id': 'event-1',
        'occurred_on': '2026-09-15T10:02:57.620729Z',
        'tenant_id': 'tenant-1',
        'salesOrderId': 'order-1',
        'salesOrderVersion': 1,
      });
      expect(event.eventType, 'sales_order_finalized.v1');
      expect(event.salesOrderId, 'order-1');
      expect(event.sourceVersion, '1');
    });

    test('legacy finalized payload resolves checkout version 1', () {
      final event = SalesOrderFinalizedIntegrationEvent.fromPayload({
        'id': 'event-1',
        'occurred_on': '2026-09-15T10:02:57.620729Z',
        'tenant_id': 'tenant-1',
        'salesOrderId': 'order-1',
      });
      expect(event.sourceVersion, '1');
    });

    test('round-trips payload with numeric salesOrderVersion', () {
      final event = SalesOrderFinalizedIntegrationEvent(
        id: 'event-1',
        occurredOn: DateTime.utc(2026, 9, 15, 10, 2, 57, 620, 729),
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        sourceVersion: '1',
      );

      final payload = event.toPayload();
      expect(payload['event_type'], SalesOrderFinalizedIntegrationEvent.type);
      expect(payload['salesOrderId'], 'order-1');
      expect(payload['salesOrderVersion'], 1);

      final decoded = SalesOrderFinalizedIntegrationEvent.fromPayload(payload);
      expect(decoded.id, event.id);
      expect(decoded.occurredOn, event.occurredOn);
      expect(decoded.tenantId, event.tenantId);
      expect(decoded.salesOrderId, event.salesOrderId);
      expect(decoded.sourceVersion, event.sourceVersion);
    });

    test('rejects missing or empty required identifier fields', () {
      final valid = {
        'id': 'event-1',
        'occurred_on': '2026-09-15T10:02:57.620729Z',
        'tenant_id': 'tenant-1',
        'salesOrderId': 'order-1',
        'salesOrderVersion': 1,
      };

      expect(
        () => SalesOrderFinalizedIntegrationEvent.fromPayload({
          ...valid,
          'id': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderFinalizedIntegrationEvent.fromPayload({
          ...valid,
          'tenant_id': '   ',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderFinalizedIntegrationEvent.fromPayload({
          ...valid,
          'salesOrderId': '',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
