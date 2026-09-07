import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort({this.log});

  final List<String>? log;
  MeInvoicePublishOutcome? publishOutcome;
  int publishCalls = 0;
  int validateCalls = 0;
  bool throwOnValidate = false;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async => throw UnimplementedError();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async => throw UnimplementedError();

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {
    validateCalls++;
    log?.add('validateCanonical');
    if (throwOnValidate) {
      throw const MeInvoiceCanonicalValidationException(
        'CANONICAL_MISSING_buyerLegalName',
      );
    }
  }

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
  }) async => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    publishCalls++;
    log?.add('provider.publish');
    return publishOutcome ?? const MeInvoicePublishUndetermined(reasonCode: 'PROVIDER_TIMEOUT');
  }
}

final class _RecordingIssuanceResultGateway implements IIssuanceResultGateway {
  _RecordingIssuanceResultGateway({this.log});

  final List<String>? log;
  PublishPreparationAction preparationAction = PublishPreparationAction.callProvider;
  int prepareCalls = 0;
  int markProviderCallStartedCalls = 0;
  int recordSuccessCalls = 0;
  int recordDefiniteFailureCalls = 0;
  int recordUndeterminedCalls = 0;
  int recordCommandIntegrityCalls = 0;
  int recordDeadLetterCalls = 0;
  bool throwOnMarkProviderCallStarted = false;
  IssuanceResultEvidenceDto? lastEvidence;
  String? lastUndeterminedReasonCode;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    prepareCalls++;
    log?.add('prepareBarrier');
    return PublishPreparationDto(action: preparationAction);
  }

  @override
  Future<void> markProviderCallStarted({
    required String tenantId,
    required String attemptId,
  }) async {
    markProviderCallStartedCalls++;
    log?.add('markProviderCallStarted');
    if (throwOnMarkProviderCallStarted) {
      throw Exception('DB error marking provider call started');
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    recordSuccessCalls++;
    lastEvidence = evidence;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.succeeded,
      electronicInvoiceId: 'ei-1',
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordDefiniteFailure({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    recordDefiniteFailureCalls++;
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
    recordUndeterminedCalls++;
    lastEvidence = evidence;
    lastUndeterminedReasonCode = switch (evidence) {
      IssuanceUndeterminedEvidenceDto(:final reasonCode) => reasonCode,
      _ => null,
    };
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
    recordCommandIntegrityCalls++;
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
    recordDeadLetterCalls++;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }
}

PublishInvoiceCommand _sampleCommand() {
  return PublishInvoiceCommand(
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    payloadHash: 'hash-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    canonicalInvoice: <String, Object?>{
      'refId': 'ref-100',
      'invSeries': '1C25TYY',
      'invDate': '2026-08-01',
      'totalAmount': 110000,
    },
  );
}

void main() {
  group('PublishInvoiceCommandHandler', () {
    test('provider call timestamp is written only immediately before HTTP', () async {
      final log = <String>[];
      final provider = _FakeMeInvoiceProviderPort(log: log)
        ..publishOutcome = MeInvoicePublishSuccess(
          providerReference: 'tx-1',
          invoiceNumber: '0000042',
          invoiceSeries: '1C25TYY',
          issuedAt: DateTime.utc(2026, 8, 1),
        );
      final gateway = _RecordingIssuanceResultGateway(log: log);

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(log, [
        'validateCanonical',
        'prepareBarrier',
        'markProviderCallStarted',
        'provider.publish',
      ]);
    });

    test('failure to mark provider-call start never calls HTTP', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway()..throwOnMarkProviderCallStarted = true;

      final handler = PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      );

      await expectLater(
        handler.handle(_sampleCommand()),
        throwsA(isA<Exception>()),
      );
      expect(provider.publishCalls, 0);
    });

    test('callProvider invokes provider once and records typed success', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = MeInvoicePublishSuccess(
          providerReference: 'tx-1',
          invoiceNumber: '0000042',
          invoiceSeries: '1C25TYY',
          issuedAt: DateTime.utc(2026, 8, 1),
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(provider.validateCalls, 1);
      expect(gateway.prepareCalls, 1);
      expect(gateway.markProviderCallStartedCalls, 1);
      expect(provider.publishCalls, 1);
      expect(gateway.recordSuccessCalls, 1);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordUndeterminedCalls, 0);
      expect(gateway.lastEvidence, isA<IssuanceSuccessEvidenceDto>());
    });

    test('reconcileOnly skips provider and records DISPATCH_STATE_UNCERTAIN', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.reconcileOnly;

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(provider.validateCalls, 1);
      expect(gateway.prepareCalls, 1);
      expect(gateway.markProviderCallStartedCalls, 0);
      expect(provider.publishCalls, 0);
      expect(gateway.recordSuccessCalls, 0);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordUndeterminedCalls, 1);
      expect(gateway.lastUndeterminedReasonCode, 'DISPATCH_STATE_UNCERTAIN');
    });

    test('skip returns without provider or result gateway mutations', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.skip;

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(provider.validateCalls, 1);
      expect(gateway.prepareCalls, 1);
      expect(gateway.markProviderCallStartedCalls, 0);
      expect(provider.publishCalls, 0);
      expect(gateway.recordSuccessCalls, 0);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordUndeterminedCalls, 0);
    });

    test(
      'invalid canonical throws CanonicalInvoiceIntegrityException before preparePublish',
      () async {
        final provider = _FakeMeInvoiceProviderPort()..throwOnValidate = true;
        final gateway = _RecordingIssuanceResultGateway();

        await expectLater(
          PublishInvoiceCommandHandler(
            providerPort: provider,
            resultGateway: gateway,
          ).handle(_sampleCommand()),
          throwsA(
            isA<CanonicalInvoiceIntegrityException>()
                .having((e) => e.attemptId, 'attemptId', 'attempt-1')
                .having((e) => e.reasonCode, 'reasonCode', 'COMMAND_INTEGRITY'),
          ),
        );

        expect(provider.validateCalls, 1);
        expect(gateway.prepareCalls, 0);
        expect(gateway.markProviderCallStartedCalls, 0);
        expect(provider.publishCalls, 0);
        expect(gateway.recordUndeterminedCalls, 0);
      },
    );

    test('timeout outcome records undetermined and completes normally', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = const MeInvoicePublishUndetermined(
          reasonCode: 'PROVIDER_TIMEOUT',
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(provider.publishCalls, 1);
      expect(gateway.recordUndeterminedCalls, 1);
      expect(gateway.lastUndeterminedReasonCode, 'PROVIDER_TIMEOUT');
      expect(gateway.recordDefiniteFailureCalls, 0);
    });

    test('duplicate RefID records undetermined, never definite failure', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = const MeInvoicePublishUndetermined(
          reasonCode: 'DUPLICATE_INVOICE_REF_ID',
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(gateway.recordUndeterminedCalls, 1);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordSuccessCalls, 0);
      expect(gateway.lastUndeterminedReasonCode, 'DUPLICATE_INVOICE_REF_ID');
    });

    test('definite failure records typed failure evidence', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = const MeInvoicePublishDefiniteFailure(
          providerCode: 'InvalidInvSeries',
          providerMessage: 'Invalid invoice series',
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(gateway.recordDefiniteFailureCalls, 1);
      expect(gateway.lastEvidence, isA<IssuanceDefiniteFailureEvidenceDto>());
    });

    test('does not dispatch RecordIssuanceResultCommand (dormant until S3b)', () {
      expect(RecordIssuanceResultCommand, isNot(equals(PublishInvoiceCommand)));
      expect(
        PublishInvoiceCommandHandler(
          providerPort: _FakeMeInvoiceProviderPort(),
          resultGateway: _RecordingIssuanceResultGateway(),
        ),
        isNot(isA<ICommandHandler<RecordIssuanceResultCommand, Object?>>()),
      );
    });
  });
}
