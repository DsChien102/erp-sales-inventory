import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('RecordDeliveryResultCommandValidator', () {
    final validator = RecordDeliveryResultCommandValidator();

    test('accepts typed evidence command', () async {
      final command = RecordDeliveryResultCommand(
        tenantId: 'tenant-1',
        deliveryId: 'del-1',
        attemptId: 'att-1',
        expectedDeliveryVersion: 1,
        expectedAttemptVersion: 1,
        interactionReference: 'pi-1',
        evidence: const DeliveryResultEvidence(
          kind: DeliveryResultKind.success,
          providerReference: 'misa-tx-1',
        ),
      );

      expect(() => validator.validate(command), returnsNormally);
    });

    test('rejects empty interactionReference', () async {
      final command = RecordDeliveryResultCommand(
        tenantId: 'tenant-1',
        deliveryId: 'del-1',
        attemptId: 'att-1',
        expectedDeliveryVersion: 1,
        expectedAttemptVersion: 1,
        interactionReference: ' ',
        evidence: const DeliveryResultEvidence(
          kind: DeliveryResultKind.undetermined,
          safeCode: 'PROVIDER_TIMEOUT',
        ),
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('RecordDeliveryResultCommandHandler', () {
    test('forwards DeliveryResultRecord to gateway', () async {
      final gateway = FakeDeliveryCommandGateway();
      final handler = RecordDeliveryResultCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RecordDeliveryResultCommand(
          tenantId: 'tenant-1',
          deliveryId: 'del-1',
          attemptId: 'att-1',
          expectedDeliveryVersion: 3,
          expectedAttemptVersion: 2,
          interactionReference: 'pi-del-1',
          evidence: const DeliveryResultEvidence(
            kind: DeliveryResultKind.retryableFailure,
            safeCode: 'HTTP_429',
          ),
        ),
      );

      expect(result.deliveryStatus, DeliveryStatus.processing);
      expect(gateway.lastRecordResult, isNotNull);
      expect(gateway.lastRecordResult!.tenantId, 'tenant-1');
      expect(gateway.lastRecordResult!.deliveryId, 'del-1');
      expect(gateway.lastRecordResult!.attemptId, 'att-1');
      expect(gateway.lastRecordResult!.expectedDeliveryVersion, 3);
      expect(gateway.lastRecordResult!.expectedAttemptVersion, 2);
      expect(gateway.lastRecordResult!.interactionReference, 'pi-del-1');
      expect(
        gateway.lastRecordResult!.evidence.kind,
        DeliveryResultKind.retryableFailure,
      );
      expect(gateway.lastRecordResult!.evidence.safeCode, 'HTTP_429');
    });
  });
}
