import 'dart:async';

import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakePublishSeriesLeaseGateway implements IPublishSeriesLeaseGateway {
  _FakePublishSeriesLeaseGateway({
    this.log,
    this.busy = false,
    this.renewLost = false,
    this.renewDelay = Duration.zero,
  });

  final List<String>? log;
  final bool busy;
  final bool renewLost;
  final Duration renewDelay;
  int acquireCalls = 0;
  int renewCalls = 0;
  int releaseCalls = 0;
  int activeRenewals = 0;
  int maxActiveRenewals = 0;

  @override
  Future<PublishSeriesLeaseAcquireOutcome> tryAcquire({
    required String tenantId,
    required String attemptId,
    required String ownerToken,
  }) async {
    acquireCalls++;
    log?.add('acquireLease');
    if (busy) {
      return const PublishSeriesLeaseBusy(retryAfter: Duration(seconds: 5));
    }
    return PublishSeriesLeaseAcquired(
      providerConnectionId: 'conn-1',
      invoiceSeries: '1C25TYY',
      leaseVersion: 1,
      leasedUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<PublishSeriesLeaseRenewOutcome> renew({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) async {
    renewCalls++;
    activeRenewals++;
    if (activeRenewals > maxActiveRenewals) {
      maxActiveRenewals = activeRenewals;
    }
    log?.add('renewLease');
    try {
      if (renewDelay > Duration.zero) {
        await Future<void>.delayed(renewDelay);
      }
      if (renewLost) {
        return const PublishSeriesLeaseLost();
      }
      return PublishSeriesLeaseRenewed(
        leasedUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );
    } finally {
      activeRenewals--;
    }
  }

  @override
  Future<void> release({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) async {
    releaseCalls++;
    log?.add('releaseLease');
  }
}

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort({this.log});

  final List<String>? log;
  MeInvoicePublishOutcome? publishOutcome;
  int publishCalls = 0;
  int validateCalls = 0;
  bool throwOnValidate = false;
  Completer<void>? publishStarted;
  Completer<void>? publishGate;

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
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup = IssuanceProviderStatusLookup.providerTransactionId,
  }) async => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    publishCalls++;
    log?.add('provider.publish');
    publishStarted?.complete();
    await publishGate?.future;
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
  int recordRetryableProviderRejectionCalls = 0;
  Duration? lastRetryAfter;
  String? lastRetrySourceCommandId;
  int recordCommandIntegrityCalls = 0;
  int recordDeadLetterCalls = 0;
  bool throwOnMarkProviderCallStarted = false;
  Duration prepareDelay = Duration.zero;
  IssuanceResultEvidenceDto? lastEvidence;
  String? lastUndeterminedReasonCode;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup = IssuanceProviderStatusLookup.providerTransactionId,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    prepareCalls++;
    log?.add('prepareBarrier');
    if (prepareDelay > Duration.zero) {
      await Future<void>.delayed(prepareDelay);
    }
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
  Future<RecordIssuanceResultDto> recordRetryableProviderRejection({
    required String tenantId,
    required String attemptId,
    required String sourceCommandId,
    required IssuanceResultEvidenceDto evidence,
    required Duration retryAfter,
  }) async {
    recordRetryableProviderRejectionCalls++;
    lastRetrySourceCommandId = sourceCommandId;
    lastEvidence = evidence;
    lastRetryAfter = retryAfter;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.preparing,
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

PublishInvoiceCommandHandler _handler({
  required IMeInvoiceProviderPort providerPort,
  required IIssuanceResultGateway resultGateway,
  IPublishSeriesLeaseGateway? leaseGateway,
}) {
  return PublishInvoiceCommandHandler(
    providerPort: providerPort,
    resultGateway: resultGateway,
    leaseGateway: leaseGateway ?? _FakePublishSeriesLeaseGateway(),
  );
}

PublishInvoiceCommand _sampleCommand() {
  return PublishInvoiceCommand(
    id: 'cmd-attempt-1',
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    payloadHash: 'hash-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    canonicalInvoice: <String, Object?>{
      'refId': 'ref-100',
      'invSeries': '1C25TYY',
      'signType': 2,
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

      final lease = _FakePublishSeriesLeaseGateway(log: log);
      await _handler(
        providerPort: provider,
        resultGateway: gateway,
        leaseGateway: lease,
      ).handle(_sampleCommand());

      expect(log, [
        'validateCanonical',
        'acquireLease',
        'prepareBarrier',
        'markProviderCallStarted',
        'provider.publish',
        'releaseLease',
      ]);
    });

    test('failure to mark provider-call start never calls HTTP', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway()..throwOnMarkProviderCallStarted = true;

      final lease = _FakePublishSeriesLeaseGateway();
      final handler = _handler(
        providerPort: provider,
        resultGateway: gateway,
        leaseGateway: lease,
      );

      await expectLater(
        handler.handle(_sampleCommand()),
        throwsA(isA<Exception>()),
      );
      expect(provider.publishCalls, 0);
      expect(lease.releaseCalls, 1);
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

      final lease = _FakePublishSeriesLeaseGateway();
      await _handler(
        providerPort: provider,
        resultGateway: gateway,
        leaseGateway: lease,
      ).handle(_sampleCommand());

      expect(provider.validateCalls, 1);
      expect(lease.acquireCalls, 1);
      expect(lease.releaseCalls, 1);
      expect(gateway.prepareCalls, 1);
      expect(gateway.markProviderCallStartedCalls, 1);
      expect(provider.publishCalls, 1);
      expect(gateway.recordSuccessCalls, 1);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordUndeterminedCalls, 0);
      expect(gateway.lastEvidence, isA<IssuanceSuccessEvidenceDto>());
    });

    test('renews sequentially while provider call is still running', () async {
      final started = Completer<void>();
      final gate = Completer<void>();
      final provider = _FakeMeInvoiceProviderPort()
        ..publishStarted = started
        ..publishGate = gate
        ..publishOutcome = MeInvoicePublishSuccess(
          providerReference: 'tx-1',
          invoiceNumber: '0000042',
          invoiceSeries: '1C25TYY',
          issuedAt: DateTime.utc(2026, 8, 1),
        );
      final lease = _FakePublishSeriesLeaseGateway(
        renewDelay: const Duration(milliseconds: 3),
      );

      final dispatch = PublishInvoiceCommandHandler(
        providerPort: provider,
        resultGateway: _RecordingIssuanceResultGateway(),
        leaseGateway: lease,
        leaseRenewInterval: const Duration(milliseconds: 1),
      ).handle(_sampleCommand());

      await started.future;
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(lease.renewCalls, greaterThanOrEqualTo(1));
      expect(lease.maxActiveRenewals, 1);
      expect(lease.releaseCalls, 0);

      gate.complete();
      await dispatch;
      expect(lease.releaseCalls, 1);
    });

    test('lost lease before provider call prevents MISA dispatch', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway()
        ..prepareDelay = const Duration(milliseconds: 15);
      final lease = _FakePublishSeriesLeaseGateway(renewLost: true);

      await expectLater(
        PublishInvoiceCommandHandler(
          providerPort: provider,
          resultGateway: gateway,
          leaseGateway: lease,
          leaseRenewInterval: const Duration(milliseconds: 1),
        ).handle(_sampleCommand()),
        throwsA(isA<PublishSeriesLeaseBusyException>()),
      );

      expect(lease.renewCalls, 1);
      expect(provider.publishCalls, 0);
      expect(lease.releaseCalls, 1);
    });

    test('reconcileOnly skips provider and records DISPATCH_STATE_UNCERTAIN', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.reconcileOnly;

      final lease = _FakePublishSeriesLeaseGateway();
      await _handler(
        providerPort: provider,
        resultGateway: gateway,
        leaseGateway: lease,
      ).handle(_sampleCommand());

      expect(provider.validateCalls, 1);
      expect(lease.releaseCalls, 1);
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

      final lease = _FakePublishSeriesLeaseGateway();
      await _handler(
        providerPort: provider,
        resultGateway: gateway,
        leaseGateway: lease,
      ).handle(_sampleCommand());

      expect(provider.validateCalls, 1);
      expect(lease.releaseCalls, 1);
      expect(gateway.prepareCalls, 1);
      expect(gateway.markProviderCallStartedCalls, 0);
      expect(provider.publishCalls, 0);
      expect(gateway.recordSuccessCalls, 0);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordUndeterminedCalls, 0);
    });

    test('busy lease throws before preparePublish and does not release acquired lease', () async {
      final provider = _FakeMeInvoiceProviderPort();
      final gateway = _RecordingIssuanceResultGateway();
      final lease = _FakePublishSeriesLeaseGateway(busy: true);

      await expectLater(
        _handler(
          providerPort: provider,
          resultGateway: gateway,
          leaseGateway: lease,
        ).handle(_sampleCommand()),
        throwsA(isA<PublishSeriesLeaseBusyException>()),
      );

      expect(lease.acquireCalls, 1);
      expect(lease.releaseCalls, 0);
      expect(gateway.prepareCalls, 0);
      expect(provider.publishCalls, 0);
    });

    test(
      'invalid canonical throws CanonicalInvoiceIntegrityException before preparePublish',
      () async {
        final provider = _FakeMeInvoiceProviderPort()..throwOnValidate = true;
        final gateway = _RecordingIssuanceResultGateway();

        await expectLater(
          _handler(
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

      await _handler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(provider.publishCalls, 1);
      expect(gateway.recordUndeterminedCalls, 1);
      expect(gateway.lastUndeterminedReasonCode, 'PROVIDER_TIMEOUT');
      expect(gateway.recordDefiniteFailureCalls, 0);
    });

    test('InvoiceNumberNotCotinuous records retryable provider rejection', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = const MeInvoicePublishRetryableRejection(
          providerCode: 'InvoiceNumberNotCotinuous',
          providerMessage: 'series gap',
          retryAfter: Duration(seconds: 5),
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await _handler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(gateway.recordRetryableProviderRejectionCalls, 1);
      expect(gateway.recordUndeterminedCalls, 0);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.lastRetryAfter, const Duration(seconds: 5));
      expect(gateway.lastRetrySourceCommandId, 'cmd-attempt-1');
    });

    test('duplicate RefID records undetermined, never definite failure', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = const MeInvoicePublishUndetermined(
          reasonCode: PublishUndeterminedReasonCodes.duplicateInvoiceRefId,
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await _handler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(gateway.recordUndeterminedCalls, 1);
      expect(gateway.recordDefiniteFailureCalls, 0);
      expect(gateway.recordSuccessCalls, 0);
      expect(
        gateway.lastUndeterminedReasonCode,
        PublishUndeterminedReasonCodes.duplicateInvoiceRefId,
      );
    });

    test('definite failure records typed failure evidence', () async {
      final provider = _FakeMeInvoiceProviderPort()
        ..publishOutcome = const MeInvoicePublishDefiniteFailure(
          providerCode: 'InvalidInvSeries',
          providerMessage: 'Invalid invoice series',
        );
      final gateway = _RecordingIssuanceResultGateway()
        ..preparationAction = PublishPreparationAction.callProvider;

      await _handler(
        providerPort: provider,
        resultGateway: gateway,
      ).handle(_sampleCommand());

      expect(gateway.recordDefiniteFailureCalls, 1);
      expect(gateway.lastEvidence, isA<IssuanceDefiniteFailureEvidenceDto>());
    });

    test('does not dispatch RecordIssuanceResultCommand (dormant until S3b)', () {
      expect(RecordIssuanceResultCommand, isNot(equals(PublishInvoiceCommand)));
      expect(
        _handler(
          providerPort: _FakeMeInvoiceProviderPort(),
          resultGateway: _RecordingIssuanceResultGateway(),
        ),
        isNot(isA<ICommandHandler<RecordIssuanceResultCommand, Object?>>()),
      );
    });
  });
}
