import 'package:test/test.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';

void main() {
  group('ProviderObservationAttentionRequiredIntegrationEvent', () {
    test('payload exposes only safe observation attention fields', () {
      final event = ProviderObservationAttentionRequiredIntegrationEvent(
        id: 'event-1',
        occurredOn: DateTime.utc(2026, 8, 31, 9),
        tenantId: 'tenant-1',
        observationId: 'obs-1',
        electronicInvoiceId: 'invoice-1',
        providerStateCode: 'MISMATCH',
        correlationId: 'corr-1',
      );

      final payload = event.toPayload();
      expect(payload['event_type'], ProviderObservationAttentionRequiredIntegrationEvent.type);
      expect(payload['observation_id'], 'obs-1');
      expect(payload['electronic_invoice_id'], 'invoice-1');
      expect(payload['provider_state_code'], 'MISMATCH');
      expect(payload['correlation_id'], 'corr-1');
      expect(payload, isNot(contains('raw_response')));
      expect(payload, isNot(contains('details_snapshot')));
      expect(payload, isNot(contains('access_token')));
    });

    test('round-trips through fromPayload', () {
      final event = ProviderObservationAttentionRequiredIntegrationEvent(
        id: 'event-1',
        occurredOn: DateTime.utc(2026, 8, 31, 9),
        tenantId: 'tenant-1',
        observationId: 'obs-1',
        electronicInvoiceId: 'invoice-1',
        providerStateCode: 'NOT_FOUND',
        correlationId: 'corr-1',
      );

      final decoded = ProviderObservationAttentionRequiredIntegrationEvent.fromPayload(
        event.toPayload(),
      );

      expect(decoded.id, event.id);
      expect(decoded.tenantId, event.tenantId);
      expect(decoded.observationId, event.observationId);
      expect(decoded.electronicInvoiceId, event.electronicInvoiceId);
      expect(decoded.providerStateCode, event.providerStateCode);
      expect(decoded.correlationId, event.correlationId);
    });
  });
}
