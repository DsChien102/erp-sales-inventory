import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeIssuanceResultGateway implements IIssuanceResultGateway {
  int successCalls = 0;
  int failureCalls = 0;
  int undeterminedCalls = 0;
  int integrityCalls = 0;
  int deadLetterCalls = 0;

  IssuanceResultEvidenceDto? lastEvidence;
  String? lastTenantId;
  String? lastAttemptId;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) async => throw UnimplementedError();

  @override
  Future<void> markProviderCallStarted({
    required String tenantId,
    required String attemptId,
  }) async => throw UnimplementedError();

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    successCalls++;
    lastTenantId = tenantId;
    lastAttemptId = attemptId;
    lastEvidence = evidence;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.succeeded,
      electronicInvoiceId: 'ei-123',
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordDefiniteFailure({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    failureCalls++;
    lastTenantId = tenantId;
    lastAttemptId = attemptId;
    lastEvidence = evidence;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordUndetermined({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    undeterminedCalls++;
    lastTenantId = tenantId;
    lastAttemptId = attemptId;
    lastEvidence = evidence;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.reconciling,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordCommandIntegrityFailure({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async {
    integrityCalls++;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordPublishCommandDeadLetter({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async {
    deadLetterCalls++;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }
}

void main() {
  const validUuid = '88d18970-380a-4138-bbce-e25049ca9e3c';

  group('RecordIssuanceResultCommandHandler', () {
    test('success evidence routes only to recordSuccess', () async {
      final gateway = _FakeIssuanceResultGateway();
      final handler = RecordIssuanceResultCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RecordIssuanceResultCommand(
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-1',
          evidence: IssuanceResultEvidenceDto.success(
            idempotencyKey: validUuid,
            payloadHash: 'hash-abc',
            providerReference: 'misa-1',
            invoiceNumber: '00000123',
            invoiceSeries: '1C26TVE',
            issuedAt: DateTime.utc(2026, 8, 28),
          ),
        ),
      );

      expect(gateway.successCalls, 1);
      expect(gateway.failureCalls + gateway.undeterminedCalls, 0);
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastAttemptId, 'attempt-1');
      expect(gateway.lastEvidence, isA<IssuanceSuccessEvidenceDto>());
      expect(result.attemptStatus, IssuanceAttemptStatus.succeeded);
      expect(result.electronicInvoiceId, 'ei-123');
    });

    test('definiteFailure evidence routes only to recordDefiniteFailure', () async {
      final gateway = _FakeIssuanceResultGateway();
      final handler = RecordIssuanceResultCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RecordIssuanceResultCommand(
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-1',
          evidence: IssuanceResultEvidenceDto.definiteFailure(
            idempotencyKey: validUuid,
            payloadHash: 'hash-abc',
            providerCode: 'ERR_TAX_CODE_INVALID',
            providerMessage: 'Tax code does not exist',
          ),
        ),
      );

      expect(gateway.failureCalls, 1);
      expect(gateway.successCalls + gateway.undeterminedCalls, 0);
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastAttemptId, 'attempt-1');
      expect(gateway.lastEvidence, isA<IssuanceDefiniteFailureEvidenceDto>());
      expect(result.attemptStatus, IssuanceAttemptStatus.failed);
      expect(result.electronicInvoiceId, isNull);
    });

    test('undetermined evidence routes only to recordUndetermined', () async {
      final gateway = _FakeIssuanceResultGateway();
      final handler = RecordIssuanceResultCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RecordIssuanceResultCommand(
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-1',
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: validUuid,
            payloadHash: 'hash-abc',
            reasonCode: 'PROVIDER_TIMEOUT',
          ),
        ),
      );

      expect(gateway.undeterminedCalls, 1);
      expect(gateway.successCalls + gateway.failureCalls, 0);
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastAttemptId, 'attempt-1');
      expect(gateway.lastEvidence, isA<IssuanceUndeterminedEvidenceDto>());
      expect(result.attemptStatus, IssuanceAttemptStatus.reconciling);
    });
  });

  group('RecordIssuanceResultCommandValidator', () {
    final validator = RecordIssuanceResultCommandValidator();

    test('valid success command passes validation', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.success(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              providerReference: 'misa-1',
              invoiceNumber: '00000123',
              invoiceSeries: '1C26TVE',
              issuedAt: DateTime.utc(2026, 8, 28),
            ),
          ),
        ),
        completes,
      );
    });

    test('valid definiteFailure command passes validation', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.definiteFailure(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              providerCode: 'ERR_1',
              providerMessage: 'Bad request',
            ),
          ),
        ),
        completes,
      );
    });

    test('valid undetermined command passes validation', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              reasonCode: 'TIMEOUT',
            ),
          ),
        ),
        completes,
      );
    });

    test('rejects empty tenantId', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: '   ',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              reasonCode: 'TIMEOUT',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty attemptId', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: '',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              reasonCode: 'TIMEOUT',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty correlationId', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: '  ',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              reasonCode: 'TIMEOUT',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-UUID idempotencyKey', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: 'not-a-uuid',
              payloadHash: 'hash-abc',
              reasonCode: 'TIMEOUT',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty payloadHash', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: validUuid,
              payloadHash: '  ',
              reasonCode: 'TIMEOUT',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects success evidence with empty invoiceNumber or series', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.success(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              providerReference: 'misa-1',
              invoiceNumber: '  ',
              invoiceSeries: '1C26TVE',
              issuedAt: DateTime.utc(2026, 8, 28),
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.success(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              providerReference: 'misa-1',
              invoiceNumber: '000001',
              invoiceSeries: '',
              issuedAt: DateTime.utc(2026, 8, 28),
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects failure evidence with empty providerCode or message', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.definiteFailure(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              providerCode: '',
              providerMessage: 'Error msg',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.definiteFailure(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              providerCode: 'ERR_1',
              providerMessage: '  ',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects undetermined evidence with empty reasonCode', () async {
      await expectLater(
        validator.validate(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'attempt-1',
            correlationId: 'corr-1',
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: validUuid,
              payloadHash: 'hash-abc',
              reasonCode: ' ',
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
