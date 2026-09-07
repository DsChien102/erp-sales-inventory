import 'package:test/test.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';

void main() {
  group('ProviderIssuanceResultReceivedIntegrationEvent', () {
    test('callback payload excludes raw provider data and secrets', () {
      final event = ProviderIssuanceResultReceivedIntegrationEvent.success(
        id: 'event-2',
        occurredOn: DateTime.utc(2026, 8, 28, 10, 0),
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        idempotencyKey: '6e60dfa0-c244-40fd-b73e-65112cb73a96',
        payloadHash: 'sha256:invoice-1',
        providerReference: 'misa-1',
        invoiceNumber: '00000123',
        invoiceSeries: '1C26TVE',
        issuedAt: DateTime.utc(2026, 8, 28, 10, 0),
      );

      final payload = event.toPayload();
      expect(payload, isNot(contains('raw_response')));
      expect(payload, isNot(contains('access_token')));
      expect(payload, isNot(contains('token')));
      expect(payload, isNot(contains('secret')));
      expect(payload, isNot(contains('credentials')));
      expect(payload, isNot(contains('headers')));

      expect(payload['event_type'], ProviderIssuanceResultReceivedIntegrationEvent.type);
      expect(payload['outcome'], 'success');
      expect(payload['invoice_number'], '00000123');
      expect(payload['invoice_series'], '1C26TVE');
      expect(payload['issued_at'], '2026-08-28T10:00:00.000Z');
      expect(payload['payload_hash'], 'sha256:invoice-1');
      expect(payload['idempotency_key'], '6e60dfa0-c244-40fd-b73e-65112cb73a96');
    });

    test('success outcome round-trips cleanly', () {
      final event = ProviderIssuanceResultReceivedIntegrationEvent.success(
        id: 'event-success-1',
        occurredOn: DateTime.utc(2026, 8, 28, 11, 15),
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        providerReference: 'misa-ref-1',
        invoiceNumber: '00000999',
        invoiceSeries: '1C26TVE',
        issuedAt: DateTime.utc(2026, 8, 28, 11, 14),
      );

      final payload = event.toPayload();
      final decoded = ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(payload);

      expect(decoded.id, event.id);
      expect(decoded.occurredOn, event.occurredOn);
      expect(decoded.tenantId, event.tenantId);
      expect(decoded.attemptId, event.attemptId);
      expect(decoded.correlationId, event.correlationId);
      expect(decoded.idempotencyKey, event.idempotencyKey);
      expect(decoded.payloadHash, event.payloadHash);
      expect(decoded.outcome, ProviderIssuanceOutcome.success);
      expect(decoded.providerReference, 'misa-ref-1');
      expect(decoded.invoiceNumber, '00000999');
      expect(decoded.invoiceSeries, '1C26TVE');
      expect(decoded.issuedAt, DateTime.utc(2026, 8, 28, 11, 14));
      expect(decoded.errorCode, isNull);
      expect(decoded.errorMessage, isNull);
      expect(decoded.reasonCode, isNull);
    });

    test('definiteFailure outcome round-trips cleanly', () {
      final event = ProviderIssuanceResultReceivedIntegrationEvent.definiteFailure(
        id: 'event-fail-1',
        occurredOn: DateTime.utc(2026, 8, 28, 12, 0),
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        providerReference: 'misa-ref-2',
        errorCode: 'ERR_TAX_CODE_INVALID',
        errorMessage: 'Tax code does not exist or is inactive',
      );

      final payload = event.toPayload();
      expect(payload['outcome'], 'definiteFailure');
      expect(payload['error_code'], 'ERR_TAX_CODE_INVALID');
      expect(payload['error_message'], 'Tax code does not exist or is inactive');

      final decoded = ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(payload);
      expect(decoded.id, event.id);
      expect(decoded.outcome, ProviderIssuanceOutcome.definiteFailure);
      expect(decoded.errorCode, 'ERR_TAX_CODE_INVALID');
      expect(decoded.errorMessage, 'Tax code does not exist or is inactive');
      expect(decoded.providerReference, 'misa-ref-2');
      expect(decoded.invoiceNumber, isNull);
    });

    test('undetermined outcome round-trips cleanly', () {
      final event = ProviderIssuanceResultReceivedIntegrationEvent.undetermined(
        id: 'event-undet-1',
        occurredOn: DateTime.utc(2026, 8, 28, 13, 0),
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        providerReference: null,
        reasonCode: 'PROVIDER_TIMEOUT',
      );

      final payload = event.toPayload();
      expect(payload['outcome'], 'undetermined');
      expect(payload['reason_code'], 'PROVIDER_TIMEOUT');

      final decoded = ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(payload);
      expect(decoded.id, event.id);
      expect(decoded.outcome, ProviderIssuanceOutcome.undetermined);
      expect(decoded.reasonCode, 'PROVIDER_TIMEOUT');
      expect(decoded.providerReference, isNull);
      expect(decoded.errorCode, isNull);
      expect(decoded.invoiceNumber, isNull);
    });

    test('strips injected raw response or credentials on deserialization', () {
      final maliciousOrDirtyPayload = {
        'id': 'event-sec-1',
        'occurred_on': '2026-08-28T10:00:00.000Z',
        'tenant_id': 'tenant-1',
        'attempt_id': 'attempt-1',
        'correlation_id': 'corr-1',
        'idempotency_key': 'idem-1',
        'payload_hash': 'hash-1',
        'outcome': 'success',
        'provider_reference': 'misa-1',
        'invoice_number': '00000123',
        'invoice_series': '1C26TVE',
        'issued_at': '2026-08-28T10:00:00.000Z',
        'raw_response': '{"secret":"leaked_body"}',
        'access_token': 'secret-token-xyz',
        'headers': {'Authorization': 'Bearer 1234'},
      };

      final decoded = ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(
        maliciousOrDirtyPayload,
      );
      final reserialized = decoded.toPayload();
      expect(reserialized.containsKey('raw_response'), isFalse);
      expect(reserialized.containsKey('access_token'), isFalse);
      expect(reserialized.containsKey('headers'), isFalse);
    });

    test('rejects missing or empty required envelope fields', () {
      final validSuccess = {
        'id': 'event-1',
        'occurred_on': '2026-08-28T10:00:00.000Z',
        'tenant_id': 'tenant-1',
        'attempt_id': 'attempt-1',
        'correlation_id': 'corr-1',
        'idempotency_key': 'idem-1',
        'payload_hash': 'hash-1',
        'outcome': 'success',
        'invoice_number': '00000123',
        'invoice_series': '1C26TVE',
        'issued_at': '2026-08-28T10:00:00.000Z',
      };

      for (final requiredField in [
        'id',
        'tenant_id',
        'attempt_id',
        'correlation_id',
        'idempotency_key',
        'payload_hash',
        'outcome',
      ]) {
        expect(
          () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(
            Map<String, dynamic>.from(validSuccess)..remove(requiredField),
          ),
          throwsA(isA<FormatException>()),
          reason: 'Field $requiredField should be required',
        );

        expect(
          () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
            ...validSuccess,
            requiredField: '   ',
          }),
          throwsA(isA<FormatException>()),
          reason: 'Field $requiredField should not be empty whitespace',
        );
      }
    });

    test('rejects invalid outcome or mismatched variant fields', () {
      final base = {
        'id': 'event-1',
        'occurred_on': '2026-08-28T10:00:00.000Z',
        'tenant_id': 'tenant-1',
        'attempt_id': 'attempt-1',
        'correlation_id': 'corr-1',
        'idempotency_key': 'idem-1',
        'payload_hash': 'hash-1',
      };

      // Unknown outcome
      expect(
        () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
          ...base,
          'outcome': 'unknown_outcome',
        }),
        throwsA(isA<FormatException>()),
      );

      // Success missing invoice_number
      expect(
        () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
          ...base,
          'outcome': 'success',
          'invoice_series': '1C26TVE',
          'issued_at': '2026-08-28T10:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );

      // DefiniteFailure missing error_code
      expect(
        () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
          ...base,
          'outcome': 'definiteFailure',
          'error_message': 'Some error',
        }),
        throwsA(isA<FormatException>()),
      );

      // Undetermined missing reason_code
      expect(
        () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
          ...base,
          'outcome': 'undetermined',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
