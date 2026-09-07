import 'package:test/test.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

void main() {
  group('PartnerProfileUpdatedIntegrationEvent', () {
    test('partner profile updated round-trips authoritative identity', () {
      final event = PartnerProfileUpdatedIntegrationEvent(
        id: 'event-partner-1',
        occurredOn: DateTime.utc(2026, 8, 28, 14, 0),
        tenantId: 'tenant-1',
        partnerId: 'partner-99',
      );

      final payload = event.toPayload();
      expect(payload['id'], 'event-partner-1');
      expect(payload['occurred_on'], '2026-08-28T14:00:00.000Z');
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['partner_id'], 'partner-99');
      expect(payload['event_type'], PartnerProfileUpdatedIntegrationEvent.type);

      final decoded = PartnerProfileUpdatedIntegrationEvent.fromPayload(payload);
      expect(decoded.id, event.id);
      expect(decoded.occurredOn, event.occurredOn);
      expect(decoded.tenantId, event.tenantId);
      expect(decoded.partnerId, event.partnerId);
      expect(decoded.eventType, PartnerProfileUpdatedIntegrationEvent.type);
    });

    test('rejects missing or empty required identifier fields', () {
      final valid = {
        'id': 'event-partner-1',
        'occurred_on': '2026-08-28T14:00:00.000Z',
        'tenant_id': 'tenant-1',
        'partner_id': 'partner-99',
      };

      expect(
        () => PartnerProfileUpdatedIntegrationEvent.fromPayload({
          ...valid,
          'id': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PartnerProfileUpdatedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('id'),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PartnerProfileUpdatedIntegrationEvent.fromPayload({
          ...valid,
          'tenant_id': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PartnerProfileUpdatedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('tenant_id'),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PartnerProfileUpdatedIntegrationEvent.fromPayload({
          ...valid,
          'partner_id': '',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => PartnerProfileUpdatedIntegrationEvent.fromPayload(
          Map<String, dynamic>.from(valid)..remove('partner_id'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
