import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeIssuanceReconciliationGateway implements IIssuanceReconciliationGateway {
  ReconciliationPollContextDto? claimedContext;
  int claimCalls = 0;
  int recordPendingCalls = 0;
  int markUnresolvedCalls = 0;
  int resolveCalls = 0;
  Duration? lastPendingDelay;
  String? lastUnresolvedReason;
  String? lastResolveOutcome;
  Map<String, Object?>? lastResolveEvidence;

  @override
  Future<ReconciliationPollContextDto?> claimReconciliationCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  }) async {
    claimCalls++;
    return claimedContext;
  }

  @override
  Future<void> recordPendingCheck({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required Duration nextDelay,
    required int checkSequence,
  }) async {
    recordPendingCalls++;
    lastPendingDelay = nextDelay;
  }

  @override
  Future<void> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  }) async {
    markUnresolvedCalls++;
    lastUnresolvedReason = reasonCode;
  }

  @override
  Future<ReconciliationCaseDto> openReconciliationCase({
    required String tenantId,
    required String attemptId,
    required String reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReconciliationCaseDto> resolveReconciliationCase({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  }) async {
    resolveCalls++;
    lastResolveOutcome = outcome;
    lastResolveEvidence = evidence;
    return const ReconciliationCaseDto(
      caseId: 'case-1',
      attemptId: 'attempt-1',
      status: ReconciliationCaseStatus.resolved,
    );
  }

  @override
  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    throw UnimplementedError();
  }
}

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  MeInvoiceIssuanceStatusOutcome outcome = const MeInvoiceIssuanceStatusPending();
  int getStatusCalls = 0;
  int publishCalls = 0;
  String? lastProviderTransactionId;
  String? lastInvoiceSeries;

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup = IssuanceProviderStatusLookup.providerTransactionId,
  }) async {
    getStatusCalls++;
    lastProviderTransactionId = statusLookupKey;
    lastInvoiceSeries = invoiceSeries;
    return outcome;
  }

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) => throw UnimplementedError();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) => throw UnimplementedError();

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {}

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    publishCalls++;
    throw UnimplementedError('publish MUST NEVER be called from poll handler!');
  }
}

final class _FakeIssuanceResultGateway implements IIssuanceResultGateway {
  int recordRetryableCalls = 0;
  String? lastRetrySourceCommandId;

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
  }) async {}

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async => throw UnimplementedError();

  @override
  Future<RecordIssuanceResultDto> recordDefiniteFailure({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async => throw UnimplementedError();

  @override
  Future<RecordIssuanceResultDto> recordUndetermined({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async => throw UnimplementedError();

  @override
  Future<RecordIssuanceResultDto> recordRetryableProviderRejection({
    required String tenantId,
    required String attemptId,
    required String sourceCommandId,
    required IssuanceResultEvidenceDto evidence,
    required Duration retryAfter,
  }) async {
    recordRetryableCalls++;
    lastRetrySourceCommandId = sourceCommandId;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.preparing,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordCommandIntegrityFailure({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async => throw UnimplementedError();

  @override
  Future<RecordIssuanceResultDto> recordPublishCommandDeadLetter({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async => throw UnimplementedError();
}

final class _FakeEinvoiceCommandDispatcher implements IEinvoiceCommandDispatcher {
  final List<ICommand<dynamic>> executedCommands = [];

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    executedCommands.add(command);
    if (command is RecordIssuanceResultCommand) {
      return const RecordIssuanceResultDto(
            attemptStatus: IssuanceAttemptStatus.succeeded,
          )
          as TResult;
    }
    throw UnimplementedError('Unsupported command: $command');
  }
}

void main() {
  group('PollIssuanceStatusCommandHandler', () {
    late _FakeIssuanceReconciliationGateway gateway;
    late _FakeMeInvoiceProviderPort providerPort;
    late _FakeEinvoiceCommandDispatcher commandDispatcher;
    late _FakeIssuanceResultGateway resultGateway;
    late PollIssuanceStatusCommandHandler handler;

    setUp(() {
      gateway = _FakeIssuanceReconciliationGateway();
      providerPort = _FakeMeInvoiceProviderPort();
      commandDispatcher = _FakeEinvoiceCommandDispatcher();
      resultGateway = _FakeIssuanceResultGateway();
      handler = PollIssuanceStatusCommandHandler(
        reconciliationGateway: gateway,
        providerPort: providerPort,
        commandDispatcher: commandDispatcher,
        resultGateway: resultGateway,
      );
    });

    final command = PollIssuanceStatusCommand(
      tenantId: 'tenant-1',
      caseId: 'case-1',
      attemptId: 'attempt-1',
      correlationId: 'corr-1',
      checkOrdinal: 1,
    );

    test('lost claim safely returns without polling or executing commands', () async {
      gateway.claimedContext = null;

      await handler.handle(command);

      expect(gateway.claimCalls, 1);
      expect(providerPort.getStatusCalls, 0);
      expect(commandDispatcher.executedCommands, isEmpty);
      expect(providerPort.publishCalls, 0);
    });

    test(
      'success outcome dispatches RecordIssuanceResultCommand with success evidence and NEVER calls publish',
      () async {
        gateway.claimedContext = const ReconciliationPollContextDto(
          caseId: 'case-1',
          attemptId: 'attempt-1',
          claimToken: 'token-1',
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          invoiceSeries: '1C26TYY',
          providerReference: 'tx-1',
          checkSequence: 1,
          maxChecks: 5,
        );

        final successEvidence = IssuanceSuccessEvidenceDto(
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          providerReference: 'tx-1',
          invoiceNumber: '00000123',
          invoiceSeries: '1C26TVE',
          issuedAt: DateTime.utc(2026, 8, 28),
        );
        providerPort.outcome = MeInvoiceIssuanceStatusOutcome.success(successEvidence);

        await handler.handle(command);

        expect(providerPort.getStatusCalls, 1);
        expect(providerPort.lastProviderTransactionId, 'tx-1');
        expect(providerPort.lastInvoiceSeries, '1C26TYY');
        expect(providerPort.publishCalls, 0);
        expect(commandDispatcher.executedCommands, hasLength(1));
        final recordCommand =
            commandDispatcher.executedCommands.first as RecordIssuanceResultCommand;
        expect(recordCommand.tenantId, 'tenant-1');
        expect(recordCommand.attemptId, 'attempt-1');
        expect(recordCommand.evidence, isA<IssuanceSuccessEvidenceDto>());
        expect(gateway.resolveCalls, 1);
        expect(gateway.lastResolveOutcome, 'SUCCESS');
        expect(gateway.lastResolveEvidence, {
          'provider_reference': 'tx-1',
          'invoice_number': '00000123',
          'invoice_series': '1C26TVE',
          'issued_at': '2026-08-28T00:00:00.000Z',
        });
      },
    );

    test(
      'definite failure outcome dispatches RecordIssuanceResultCommand with failure evidence and NEVER calls publish',
      () async {
        gateway.claimedContext = const ReconciliationPollContextDto(
          caseId: 'case-1',
          attemptId: 'attempt-1',
          claimToken: 'token-1',
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          invoiceSeries: '1C26TYY',
          providerReference: 'tx-1',
          checkSequence: 1,
          maxChecks: 5,
        );

        final failureEvidence = IssuanceDefiniteFailureEvidenceDto(
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          providerCode: 'InvalidInvSeries',
          providerMessage: 'Series invalid',
        );
        providerPort.outcome = MeInvoiceIssuanceStatusOutcome.definiteFailure(failureEvidence);

        await handler.handle(command);

        expect(providerPort.getStatusCalls, 1);
        expect(providerPort.lastProviderTransactionId, 'tx-1');
        expect(providerPort.lastInvoiceSeries, '1C26TYY');
        expect(providerPort.publishCalls, 0);
        expect(commandDispatcher.executedCommands, hasLength(1));
        final recordCommand =
            commandDispatcher.executedCommands.first as RecordIssuanceResultCommand;
        expect(recordCommand.evidence, isA<IssuanceDefiniteFailureEvidenceDto>());
        expect(gateway.resolveCalls, 1);
        expect(gateway.lastResolveOutcome, 'FAILURE');
        expect(gateway.lastResolveEvidence, {
          'provider_code': 'InvalidInvSeries',
          'provider_message': 'Series invalid',
        });
      },
    );

    test(
      'pending outcome at check 1 records pending check with delay of check 2 (2 minutes)',
      () async {
        gateway.claimedContext = const ReconciliationPollContextDto(
          caseId: 'case-1',
          attemptId: 'attempt-1',
          claimToken: 'token-1',
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          invoiceSeries: '1K26TYY',
          providerReference: 'tx-1',
          checkSequence: 1,
          maxChecks: 5,
        );
        providerPort.outcome = const MeInvoiceIssuanceStatusOutcome.pending();

        await handler.handle(command);

        expect(providerPort.getStatusCalls, 1);
        expect(providerPort.publishCalls, 0);
        expect(commandDispatcher.executedCommands, isEmpty);
        expect(gateway.recordPendingCalls, 1);
        expect(gateway.lastPendingDelay, ReconciliationSchedule.delayBeforeCheck(2));
        expect(gateway.markUnresolvedCalls, 0);
      },
    );

    test('pending outcome at check 5 marks unresolved and stops polling', () async {
      gateway.claimedContext = const ReconciliationPollContextDto(
        caseId: 'case-1',
        attemptId: 'attempt-1',
        claimToken: 'token-1',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        invoiceSeries: '1K26TYY',
        providerReference: 'tx-1',
        checkSequence: 5,
        maxChecks: 5,
      );
      providerPort.outcome = const MeInvoiceIssuanceStatusOutcome.pending();

      await handler.handle(command);

      expect(providerPort.getStatusCalls, 1);
      expect(providerPort.publishCalls, 0);
      expect(commandDispatcher.executedCommands, isEmpty);
      expect(gateway.recordPendingCalls, 0);
      expect(gateway.markUnresolvedCalls, 1);
      expect(gateway.lastUnresolvedReason, 'POLL_MAX_CHECKS_EXCEEDED');
    });

    test('undetermined outcome at check 5 marks unresolved and stops polling', () async {
      gateway.claimedContext = const ReconciliationPollContextDto(
        caseId: 'case-1',
        attemptId: 'attempt-1',
        claimToken: 'token-1',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        invoiceSeries: '1K26TYY',
        providerReference: 'tx-1',
        checkSequence: 5,
        maxChecks: 5,
      );
      providerPort.outcome = const MeInvoiceIssuanceStatusOutcome.undetermined('PROVIDER_TIMEOUT');

      await handler.handle(command);

      expect(providerPort.getStatusCalls, 1);
      expect(providerPort.publishCalls, 0);
      expect(commandDispatcher.executedCommands, isEmpty);
      expect(gateway.recordPendingCalls, 0);
      expect(gateway.markUnresolvedCalls, 1);
      expect(gateway.lastUnresolvedReason, 'POLL_MAX_CHECKS_EXCEEDED');
    });

    test(
      'InvoiceDuplicated reconcile-first polls status by RefID without provider transaction id',
      () async {
        gateway.claimedContext = const ReconciliationPollContextDto(
          caseId: 'case-1',
          attemptId: 'attempt-1',
          claimToken: 'token-1',
          idempotencyKey: 'idem-ref-1',
          payloadHash: 'hash-1',
          invoiceSeries: '1C26TYY',
          providerReference: null,
          reconciliationReasonCode: PublishUndeterminedReasonCodes.invoiceDuplicatedReconcileFirst,
          checkSequence: 1,
          maxChecks: 5,
        );

        final successEvidence = IssuanceSuccessEvidenceDto(
          idempotencyKey: 'idem-ref-1',
          payloadHash: 'hash-1',
          providerReference: 'tx-from-ref',
          invoiceNumber: '00000123',
          invoiceSeries: '1C26TVE',
          issuedAt: DateTime.utc(2026, 8, 28),
        );
        providerPort.outcome = MeInvoiceIssuanceStatusOutcome.success(successEvidence);

        await handler.handle(command);

        expect(providerPort.getStatusCalls, 1);
        expect(providerPort.lastProviderTransactionId, 'idem-ref-1');
        expect(providerPort.publishCalls, 0);
        expect(commandDispatcher.executedCommands, hasLength(1));
        expect(gateway.resolveCalls, 1);
        expect(gateway.lastResolveOutcome, 'SUCCESS');
      },
    );

    test(
      'InvoiceDuplicated definitive-not-found after max checks schedules durable publish retry',
      () async {
        gateway.claimedContext = const ReconciliationPollContextDto(
          caseId: 'case-1',
          attemptId: 'attempt-1',
          claimToken: 'token-1',
          idempotencyKey: 'idem-ref-1',
          payloadHash: 'hash-1',
          invoiceSeries: '1C26TYY',
          providerReference: null,
          reconciliationReasonCode: PublishUndeterminedReasonCodes.invoiceDuplicatedReconcileFirst,
          checkSequence: 5,
          maxChecks: 5,
        );
        providerPort.outcome = const MeInvoiceIssuanceStatusOutcome.undetermined(
          'STATUS_EMPTY_DATA',
        );

        await handler.handle(command);

        expect(providerPort.getStatusCalls, 1);
        expect(providerPort.publishCalls, 0);
        expect(commandDispatcher.executedCommands, isEmpty);
        expect(resultGateway.recordRetryableCalls, 1);
        expect(resultGateway.lastRetrySourceCommandId, command.id);
        expect(gateway.resolveCalls, 1);
        expect(gateway.lastResolveOutcome, 'PUBLISH_RETRY_SCHEDULED');
        expect(gateway.markUnresolvedCalls, 0);
      },
    );

    test('missing provider transaction id marks unresolved without status polling', () async {
      gateway.claimedContext = const ReconciliationPollContextDto(
        caseId: 'case-1',
        attemptId: 'attempt-1',
        claimToken: 'token-1',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        invoiceSeries: '1C26TYY',
        providerReference: null,
        checkSequence: 1,
        maxChecks: 5,
      );

      await handler.handle(command);

      expect(providerPort.getStatusCalls, 0);
      expect(gateway.markUnresolvedCalls, 1);
      expect(gateway.lastUnresolvedReason, 'MISSING_PROVIDER_TRANSACTION_ID');
    });
  });
}
