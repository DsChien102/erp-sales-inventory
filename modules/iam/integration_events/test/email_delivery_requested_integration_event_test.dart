import 'package:test/test.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';

void main() {
  group('EmailDeliveryRequestedIntegrationEvent envelope v1', () {
    test('round-trips payload with event_version and nullable platform tenant', () {
      final event = EmailDeliveryRequestedIntegrationEvent(
        id: '11111111-1111-1111-1111-111111111111',
        occurredOn: DateTime.utc(2026, 7, 29, 10),
        tenantId:
            EmailDeliveryRequestedIntegrationEvent.platformMessagingTenantId,
        templateId: 'activation_invitation',
        toEmail: 'owner@example.com',
        correlationId: 'corr-1',
        outcomeId: 'out-1',
        refs: const <String, String>{'user_id': 'u-1'},
      );

      final payload = event.toPayload();
      expect(payload['event_version'], 1);
      expect(payload['tenant_id'], isNull);
      expect(payload['to_email'], 'owner@example.com');
      expect(payload['correlation_id'], 'corr-1');
      expect(payload['outcome_id'], 'out-1');
      expect(payload.containsKey('app_link_url'), isFalse);

      final restored =
          EmailDeliveryRequestedIntegrationEvent.fromPayload(payload);
      expect(restored.isPlatformScoped, isTrue);
      expect(
        restored.tenantId,
        EmailDeliveryRequestedIntegrationEvent.platformMessagingTenantId,
      );
      expect(restored.toEmail, 'owner@example.com');
      expect(restored.correlationId, 'corr-1');
      expect(restored.outcomeId, 'out-1');
    });

    test('rejects missing required envelope fields', () {
      expect(
        () => EmailDeliveryRequestedIntegrationEvent.fromPayload({
          'to_email': 'a@b.c',
          'correlation_id': 'c',
          'outcome_id': 'o',
          'template_id': 'activation_invitation',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => EmailDeliveryRequestedIntegrationEvent.fromPayload({
          'event_version': 1,
          'correlation_id': 'c',
          'outcome_id': 'o',
          'template_id': 'activation_invitation',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => EmailDeliveryRequestedIntegrationEvent.fromPayload({
          'event_version': 1,
          'to_email': 'a@b.c',
          'outcome_id': 'o',
          'template_id': 'activation_invitation',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => EmailDeliveryRequestedIntegrationEvent.fromPayload({
          'event_version': 1,
          'to_email': 'a@b.c',
          'correlation_id': 'c',
          'template_id': 'activation_invitation',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects secret material in refs', () {
      expect(
        () => EmailDeliveryRequestedIntegrationEvent.fromPayload({
          'event_version': 1,
          'id': '11111111-1111-1111-1111-111111111111',
          'occurred_on': '2026-07-29T10:00:00Z',
          'tenant_id': null,
          'template_id': 'tenant_invitation',
          'to_email': 'a@b.c',
          'correlation_id': 'c',
          'outcome_id': 'o',
          'refs': {'token': 'raw-secret-token-value'},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
