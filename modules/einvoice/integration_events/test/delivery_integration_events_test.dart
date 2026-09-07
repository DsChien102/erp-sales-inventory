import 'package:test/test.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';

void main() {
  group('ElectronicInvoiceRegisteredIntegrationEvent', () {
    test('round-trips through fromPayload', () {
      final event = ElectronicInvoiceRegisteredIntegrationEvent(
        id: 'event-1',
        occurredOn: DateTime.utc(2026, 9, 2, 10),
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        salesOrderId: 'so-1',
      );

      final decoded = ElectronicInvoiceRegisteredIntegrationEvent.fromPayload(
        event.toPayload(),
      );

      expect(decoded.id, event.id);
      expect(decoded.tenantId, event.tenantId);
      expect(decoded.electronicInvoiceId, event.electronicInvoiceId);
      expect(decoded.salesOrderId, event.salesOrderId);
    });

    test('rejects missing required ids', () {
      expect(
        () => ElectronicInvoiceRegisteredIntegrationEvent.fromPayload({
          'id': 'event-1',
          'occurred_on': '2026-09-02T10:00:00.000Z',
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': '',
          'sales_order_id': 'so-1',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed timestamp', () {
      expect(
        () => ElectronicInvoiceRegisteredIntegrationEvent.fromPayload({
          'id': 'event-1',
          'occurred_on': 'not-a-date',
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': 'ei-1',
          'sales_order_id': 'so-1',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DeliveryResultRecordedIntegrationEvent', () {
    test('round-trips safe payload fields', () {
      final event = DeliveryResultRecordedIntegrationEvent(
        id: 'event-2',
        occurredOn: DateTime.utc(2026, 9, 2, 11),
        tenantId: 'tenant-1',
        salesOrderId: 'so-1',
        deliveryId: 'del-1',
        deliveryStatus: 'unknown',
        deliveryDisplayState: 'sent',
        deliveryVersion: 4,
        hasSecondaryAttention: true,
      );

      final payload = event.toPayload();
      expect(payload['sales_order_id'], 'so-1');
      expect(payload['delivery_id'], 'del-1');
      expect(payload['delivery_status'], 'unknown');
      expect(payload['delivery_display_state'], 'sent');
      expect(payload['delivery_version'], 4);
      expect(payload['has_secondary_attention'], isTrue);
      expect(payload, isNot(contains('recipient_email')));
      expect(payload, isNot(contains('provider_body')));
      expect(payload, isNot(contains('exception')));

      final decoded = DeliveryResultRecordedIntegrationEvent.fromPayload(payload);
      expect(decoded.salesOrderId, 'so-1');
      expect(decoded.deliveryId, 'del-1');
      expect(decoded.deliveryStatus, 'unknown');
      expect(decoded.deliveryDisplayState, 'sent');
      expect(decoded.deliveryVersion, 4);
      expect(decoded.hasSecondaryAttention, isTrue);
    });

    test('rejects malformed delivery status', () {
      expect(
        () => DeliveryResultRecordedIntegrationEvent.fromPayload({
          'id': 'event-2',
          'occurred_on': '2026-09-02T11:00:00.000Z',
          'tenant_id': 'tenant-1',
          'sales_order_id': 'so-1',
          'delivery_id': 'del-1',
          'delivery_status': 'HACKED',
          'delivery_display_state': 'sent',
          'delivery_version': 1,
          'has_secondary_attention': false,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DeliveryAttentionRequiredIntegrationEvent', () {
    test('round-trips ids and safe error only', () {
      final event = DeliveryAttentionRequiredIntegrationEvent(
        id: 'event-3',
        occurredOn: DateTime.utc(2026, 9, 2, 12),
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        salesOrderId: 'so-1',
        deliveryId: 'del-1',
        attemptId: 'att-1',
        reconciliationCaseId: 'case-1',
        safeErrorCode: 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      );

      final payload = event.toPayload();
      expect(payload['event_type'], DeliveryAttentionRequiredIntegrationEvent.type);
      expect(payload['electronic_invoice_id'], 'ei-1');
      expect(payload['sales_order_id'], 'so-1');
      expect(payload['delivery_id'], 'del-1');
      expect(payload['attempt_id'], 'att-1');
      expect(payload['reconciliation_case_id'], 'case-1');
      expect(payload['safe_error_code'], 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED');
      expect(payload, isNot(contains('recipient_email')));
      expect(payload, isNot(contains('raw_response')));
      expect(payload, isNot(contains('headers')));

      final decoded = DeliveryAttentionRequiredIntegrationEvent.fromPayload(payload);
      expect(decoded.reconciliationCaseId, 'case-1');
      expect(decoded.safeErrorCode, 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED');
    });

    test('rejects missing case id', () {
      expect(
        () => DeliveryAttentionRequiredIntegrationEvent.fromPayload({
          'id': 'event-3',
          'occurred_on': '2026-09-02T12:00:00.000Z',
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': 'ei-1',
          'sales_order_id': 'so-1',
          'delivery_id': 'del-1',
          'attempt_id': 'att-1',
          'reconciliation_case_id': '',
          'safe_error_code': 'X',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
