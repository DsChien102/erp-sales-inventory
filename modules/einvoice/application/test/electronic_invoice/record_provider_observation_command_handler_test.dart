import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 's4_test_support.dart';

void main() {
  group('RecordProviderObservationCommandHandler', () {
    test('delegates typed record to command gateway', () async {
      final gateway = RecordingElectronicInvoiceCommandGateway();
      final handler = RecordProviderObservationCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RecordProviderObservationCommand(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'invoice-1',
          providerStateCode: 'NOT_FOUND',
          safeDescription: 'PROVIDER_STATUS_NOT_FOUND',
          providerReference: 'tx-1',
          observedAt: DateTime.utc(2026, 8, 31, 9),
          deduplicationKey: 'provider_observation:cmd-1',
          detailsSnapshot: const {'transactionId': 'tx-1'},
          correlationId: 'corr-1',
          source: 'WORKER',
        ),
      );

      expect(gateway.observationRecords.single.electronicInvoiceId, 'invoice-1');
      expect(gateway.observationRecords.single.providerStateCode, 'NOT_FOUND');
      expect(result.observationId, 'obs-1');
      expect(result.correlationId, 'corr-1');
      expect(result.providerStateCode, 'NOT_FOUND');
    });
  });

  group('RecordProviderObservationCommandValidator', () {
    final validator = RecordProviderObservationCommandValidator();

    test('rejects blank correlation id', () async {
      await expectLater(
        validator.validate(
          RecordProviderObservationCommand(
            tenantId: 'tenant-1',
            electronicInvoiceId: 'invoice-1',
            providerStateCode: 'PS_1_ES_2',
            observedAt: DateTime.utc(2026, 8, 31, 9),
            deduplicationKey: 'provider_observation:cmd-1',
            detailsSnapshot: const {},
            correlationId: '  ',
            source: 'WORKER',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-allow-listed details snapshot keys', () async {
      await expectLater(
        validator.validate(
          RecordProviderObservationCommand(
            tenantId: 'tenant-1',
            electronicInvoiceId: 'invoice-1',
            providerStateCode: 'PS_1_ES_2',
            observedAt: DateTime.utc(2026, 8, 31, 9),
            deduplicationKey: 'provider_observation:cmd-1',
            detailsSnapshot: const {'rawPayload': 'secret'},
            correlationId: 'corr-1',
            source: 'WORKER',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
