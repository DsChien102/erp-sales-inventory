import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';

void main() {
  group('AutoIssuanceIdempotencyKey', () {
    test('generates canonical trigger key from event type, order, and version', () {
      final key = AutoIssuanceIdempotencyKey.triggerKey(
        eventType: SalesOrderFinalizedIntegrationEvent.type,
        eventId: 'evt-123',
        salesOrderId: 'order-456',
        sourceVersion: '1',
      );

      expect(
        key,
        'sales_order_finalized.v1:evt-123:order-456:1',
      );
    });

    test('generates valid canonical UUIDv5 for idempotency key', () {
      final key = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-456',
        sourceVersion: 'sales-v17',
      );

      expect(Uuid.isValidUUID(fromString: key), isTrue);
    });

    test('is deterministic for identical inputs', () {
      final key1 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-456',
        sourceVersion: 'sales-v17',
      );
      final key2 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-456',
        sourceVersion: 'sales-v17',
      );

      expect(key1, equals(key2));
    });

    test('changes when sourceVersion changes', () {
      final keyV1 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-456',
        sourceVersion: 'sales-v1',
      );
      final keyV2 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-456',
        sourceVersion: 'sales-v2',
      );

      expect(keyV1, isNot(equals(keyV2)));
    });

    test('changes when salesOrderId changes', () {
      final key1 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        sourceVersion: 'sales-v1',
      );
      final key2 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-2',
        sourceVersion: 'sales-v1',
      );

      expect(key1, isNot(equals(key2)));
    });

    test('changes when tenantId changes', () {
      final key1 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        sourceVersion: 'sales-v1',
      );
      final key2 = AutoIssuanceIdempotencyKey.generate(
        tenantId: 'tenant-2',
        salesOrderId: 'order-1',
        sourceVersion: 'sales-v1',
      );

      expect(key1, isNot(equals(key2)));
    });
  });
}
