import 'package:test/test.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';

void main() {
  group('SalesOrderCompletedIntegrationEvent', () {
    test('sales completion round-trips its authoritative identity', () {
      final event = SalesOrderCompletedIntegrationEvent(
        id: 'event-1',
        occurredOn: DateTime.utc(2026, 8, 28, 12, 30),
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        sourceVersion: 'sales:v17',
      );

      final payload = event.toPayload();
      expect(payload['id'], 'event-1');
      expect(payload['occurred_on'], '2026-08-28T12:30:00.000Z');
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['sales_order_id'], 'order-1');
      expect(payload['source_version'], 'sales:v17');
      expect(payload['event_type'], SalesOrderCompletedIntegrationEvent.type);

      final decoded = SalesOrderCompletedIntegrationEvent.fromPayload(payload);
      expect(decoded.id, event.id);
      expect(decoded.occurredOn, event.occurredOn);
      expect(decoded.tenantId, event.tenantId);
      expect(decoded.salesOrderId, event.salesOrderId);
      expect(decoded.sourceVersion, event.sourceVersion);
      expect(decoded.eventType, SalesOrderCompletedIntegrationEvent.type);
    });

    test('rejects missing or empty required identifier fields', () {
      final valid = {
        'id': 'event-1',
        'occurred_on': '2026-08-28T12:30:00.000Z',
        'tenant_id': 'tenant-1',
        'sales_order_id': 'order-1',
        'source_version': 'sales:v17',
      };

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload({
          ...valid,
          'id': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('id'),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload({
          ...valid,
          'tenant_id': '   ',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('tenant_id'),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload({
          ...valid,
          'sales_order_id': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('sales_order_id'),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload({
          ...valid,
          'source_version': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SalesOrderCompletedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('source_version'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
