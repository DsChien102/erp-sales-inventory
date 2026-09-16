import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/commands_executor.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_command_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_integration_event_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/i_einvoice_inbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/publish_invoice_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/in_memory_publish_series_lease_gateway.dart';

// =============================================================================
// Fake in-memory Provider Port
// =============================================================================

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  int publishCount = 0;
  int getStatusCount = 0;
  int validateCanonicalCount = 0;
  bool shouldFailValidation = false;

  MeInvoicePublishOutcome? nextPublishOutcome;
  MeInvoiceIssuanceStatusOutcome? nextStatusOutcome;

  final List<Map<String, Object?>> publishedInvoices = [];

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async => const MeInvoiceAuthOutcome.success(
    templateCount: 1,
    supportsEmailDelivery: true,
  );

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async => const MeInvoicePreviewOutcome.success(viewerRef: 'viewer-ref-1');

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {
    validateCanonicalCount++;
    if (shouldFailValidation ||
        canonicalInvoice['canonical_hash_mismatch'] == true) {
      final attemptId =
          canonicalInvoice['__attemptId']?.toString() ?? 'unknown';
      throw CanonicalInvoiceIntegrityException(
        attemptId: attemptId,
        reasonCode: 'COMMAND_INTEGRITY',
        message: 'Canonical invoice payload hash mismatch',
      );
    }
  }

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    publishCount++;
    publishedInvoices.add(canonicalInvoice);
    if (nextPublishOutcome != null) {
      return nextPublishOutcome!;
    }
    return MeInvoicePublishSuccess(
      providerReference: 'tx-$idempotencyKey',
      invoiceNumber: '0000001',
      invoiceSeries: '1C26TYY',
      issuedAt: DateTime.utc(2026, 8, 29, 12, 0, 0),
    );
  }

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup =
        IssuanceProviderStatusLookup.providerTransactionId,
  }) async {
    getStatusCount++;
    if (nextStatusOutcome != null) {
      return nextStatusOutcome!;
    }
    return MeInvoiceIssuanceStatusOutcome.success(
      IssuanceResultEvidenceDto.success(
            idempotencyKey: idempotencyKey,
            payloadHash: payloadHash,
            providerReference: statusLookupKey,
            invoiceNumber: '0000001',
            invoiceSeries: invoiceSeries,
            issuedAt: DateTime.utc(2026, 8, 29, 12, 0, 0),
          )
          as IssuanceSuccessEvidenceDto,
    );
  }
}

// =============================================================================
// Fake In-Memory Internal Command Client
// =============================================================================

final class _FakeInternalCommandStore {
  final List<_StoredCommand> commands = [];
  final List<String> callLog = [];
  final List<ReconciliationCaseDto> pendingReconciliationCases = [];
}

final class _StoredCommand {
  _StoredCommand({
    required this.id,
    required this.tenantId,
    required this.commandType,
    required this.payload,
    required this.enqueuedAt,
  });

  final String id;
  final String tenantId;
  final String commandType;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  int retryCount = 0;
  String? claimToken;
  DateTime? processedAt;
  DateTime? failedAt;
  String? lastError;
}

final class _TestInternalCommandClient
    implements IEinvoiceInternalCommandClient {
  _TestInternalCommandClient({required this.store, required this.serializer});

  final _FakeInternalCommandStore store;
  final InternalCommandSerializer serializer;

  void enqueue(ISerializableInternalCommand command) {
    if (command is! CommandBase) {
      throw ArgumentError('command must extend CommandBase');
    }
    final base = command as CommandBase<void>;
    store.commands.add(
      _StoredCommand(
        id: base.id,
        tenantId: serializer.tenantIdOf(command),
        commandType: serializer.commandTypeOf(command),
        payload: serializer.toPayload(command),
        enqueuedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async {
    store.callLog.add('seedDueReconciliationCommands:$tenantId');
    int seededCount = 0;
    final dueCases = store.pendingReconciliationCases
        .where((c) => c.status == ReconciliationCaseStatus.pending)
        .toList();

    for (final c in dueCases) {
      final exists = store.commands.any(
        (cmd) =>
            cmd.commandType == PollIssuanceStatusCommand.type &&
            cmd.payload['case_id'] == c.caseId &&
            cmd.processedAt == null &&
            cmd.failedAt == null,
      );
      if (!exists) {
        final pollCmd = PollIssuanceStatusCommand(
          tenantId: tenantId,
          caseId: c.caseId,
          attemptId: c.attemptId,
          correlationId: 'corr-${c.caseId}',
          checkOrdinal: 1,
        );
        enqueue(pollCmd);
        seededCount++;
      }
    }
    return seededCount;
  }

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = store.commands
        .where(
          (c) =>
              c.tenantId == tenantId &&
              c.processedAt == null &&
              c.failedAt == null &&
              c.claimToken == null,
        )
        .take(limit)
        .toList(growable: false);

    final claimed = <ClaimedInternalCommand>[];
    for (final command in pending) {
      final token = const Uuid().v4();
      command.claimToken = token;
      claimed.add(
        ClaimedInternalCommand(
          commandId: command.id,
          commandType: command.commandType,
          payload: Map<String, dynamic>.from(command.payload),
          enqueuedAt: command.enqueuedAt,
          claimToken: token,
          retryCount: command.retryCount,
        ),
      );
    }
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) return;
    store.callLog.add('complete:$commandId');
    command.processedAt = DateTime.now().toUtc();
    command.claimToken = null;
  }

  @override
  Future<InternalCommandDisposition> retryOrDeadLetter({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      throw StateError('Command not found');
    }
    command.retryCount++;
    command.lastError = error;
    command.claimToken = null;
    store.callLog.add('retryOrDeadLetter:$commandId:$error');
    if (command.retryCount >= 3 || error.contains('COMMAND_INTEGRITY')) {
      command.failedAt = DateTime.now().toUtc();
      return InternalCommandDisposition.deadLetter;
    }
    return InternalCommandDisposition.retry;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) return;
    store.callLog.add('fail:$commandId:$error');
    command.failedAt = DateTime.now().toUtc();
    command.lastError = error;
    command.claimToken = null;
  }

  @override
  Future<void> reschedule({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required Duration delay,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) return;
    store.callLog.add('reschedule:$commandId');
    command.claimToken = null;
  }

  _StoredCommand? _findClaimed({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) {
    for (final command in store.commands) {
      if (command.id == commandId &&
          command.tenantId == tenantId &&
          command.claimToken == claimToken) {
        return command;
      }
    }
    return null;
  }
}

// =============================================================================
// Fake In-Memory Inbox Client
// =============================================================================

final class _TestEinvoiceInboxClient implements IEinvoiceInboxClient {
  final List<ClaimedInboxMessage> messages = [];
  final List<String> completedIds = [];
  final List<(String id, String error)> failedIds = [];

  void addMessage({
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required String tenantId,
  }) {
    messages.add(
      ClaimedInboxMessage(
        messageId: messageId,
        eventType: eventType,
        payload: payload,
        occurredAt: DateTime.now().toUtc(),
        claimToken: const Uuid().v4(),
      ),
    );
  }

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    return messageId;
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final batch = List<ClaimedInboxMessage>.from(messages.take(limit));
    messages.removeRange(0, batch.length);
    return batch;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    completedIds.add(messageId);
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {
    failedIds.add((messageId, error));
  }
}

// =============================================================================
// In-Memory Stateful Gateways & Domain Records
// =============================================================================

final class _InMemoryAutoIssuanceProcess {
  _InMemoryAutoIssuanceProcess({
    required this.processId,
    required this.tenantId,
    required this.salesOrderId,
    required this.salesOrderVersion,
    required this.triggerKey,
    required this.status,
    required this.partnerId,
    this.attemptId,
  });

  final String processId;
  final String tenantId;
  final String salesOrderId;
  final String salesOrderVersion;
  final String triggerKey;
  String status;
  final String partnerId;
  String? attemptId;
  int retryCount = 0;
}

final class _InMemoryAttempt {
  _InMemoryAttempt({
    required this.attemptId,
    required this.tenantId,
    required this.salesOrderId,
    required this.salesOrderVersion,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.completionId,
    this.status = IssuanceAttemptStatus.preparing,
  });

  final String attemptId;
  final String tenantId;
  final String salesOrderId;
  final String salesOrderVersion;
  final String idempotencyKey;
  final String payloadHash;
  final String completionId;
  final String invoiceSeries = '1C25TYY';
  IssuanceAttemptStatus status;
  IssuanceResultEvidenceDto? evidence;
  String? providerReference;
  String? lastErrorCode;
}

final class _TestState {
  final List<_InMemoryAutoIssuanceProcess> processes = [];
  final List<_InMemoryAttempt> attempts = [];
  final List<ReconciliationCaseDto> reconciliationCases = [];
  final Map<String, int> caseCheckCounts = {};
  final Map<String, String> caseReasonCodes = {};
  final Map<String, dynamic> electronicInvoices = {};
  final Map<String, Map<String, dynamic>> buyerCompletions = {};
  final Map<String, Map<String, Object?>> storedProviderEvidence = {};
  int partnerResolveCount = 0;
}

final class _TestAutoIssuanceGateway implements IAutoIssuanceGateway {
  _TestAutoIssuanceGateway(this.state, this.internalClient);

  final _TestState state;
  final _TestInternalCommandClient internalClient;

  @override
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request) async {
    final existing = state.processes.where(
      (p) =>
          p.tenantId == request.tenantId &&
          p.salesOrderId == request.salesOrderId,
    );

    if (existing.isNotEmpty) {
      return const AutoIssuanceResultDto(
        started: false,
        skipped: true,
        reason: 'PROCESS_ALREADY_EXISTS',
        status: 'SKIPPED',
      );
    }

    final processId = 'proc-${request.salesOrderId}';
    final attemptId = 'att-${request.salesOrderId}-1';
    final process = _InMemoryAutoIssuanceProcess(
      processId: processId,
      tenantId: request.tenantId,
      salesOrderId: request.salesOrderId,
      salesOrderVersion: 'sales-v1',
      triggerKey: request.triggerKey,
      status: 'ATTEMPT_STARTED',
      partnerId: 'partner-default',
      attemptId: attemptId,
    );
    state.processes.add(process);

    final attempt = _InMemoryAttempt(
      attemptId: attemptId,
      tenantId: request.tenantId,
      salesOrderId: request.salesOrderId,
      salesOrderVersion: process.salesOrderVersion,
      idempotencyKey: request.idempotencyKey,
      payloadHash: 'hash-auto-1',
      completionId: 'comp-${request.salesOrderId}',
      status: IssuanceAttemptStatus.preparing,
    );
    state.attempts.add(attempt);

    // Enqueue publish command
    final publishCmd = PublishInvoiceCommand(
      tenantId: request.tenantId,
      attemptId: attemptId,
      idempotencyKey: request.idempotencyKey,
      payloadHash: 'hash-auto-1',
      canonicalInvoice: {
        '__attemptId': attemptId,
        'order_id': request.salesOrderId,
      },
    );
    internalClient.enqueue(publishCmd);

    return AutoIssuanceResultDto(
      started: true,
      skipped: false,
      processId: processId,
      attemptId: attemptId,
      status: 'ATTEMPT_STARTED',
    );
  }

  @override
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  ) async {
    final process = state.processes.firstWhere(
      (p) => p.processId == request.processId,
      orElse: () => throw StateError('Process not found: ${request.processId}'),
    );

    if (process.status != 'PENDING_REEVALUATION') {
      return const AutoIssuanceResultDto(
        started: false,
        skipped: true,
        reason: 'NOT_PENDING_REEVALUATION',
        status: 'SKIPPED',
      );
    }

    // Reuse process row, create first attempt
    final attemptId = 'att-${process.salesOrderId}-reeval-1';
    process.status = 'ATTEMPT_STARTED';
    process.attemptId = attemptId;

    final attempt = _InMemoryAttempt(
      attemptId: attemptId,
      tenantId: request.tenantId,
      salesOrderId: process.salesOrderId,
      salesOrderVersion: process.salesOrderVersion,
      idempotencyKey: process.triggerKey,
      payloadHash: 'hash-reeval-1',
      completionId: 'comp-${process.salesOrderId}',
      status: IssuanceAttemptStatus.preparing,
    );
    state.attempts.add(attempt);

    final publishCmd = PublishInvoiceCommand(
      tenantId: request.tenantId,
      attemptId: attemptId,
      idempotencyKey: process.triggerKey,
      payloadHash: 'hash-reeval-1',
      canonicalInvoice: {
        '__attemptId': attemptId,
        'order_id': process.salesOrderId,
      },
    );
    internalClient.enqueue(publishCmd);

    return AutoIssuanceResultDto(
      started: true,
      skipped: false,
      processId: process.processId,
      attemptId: attemptId,
      status: 'ATTEMPT_STARTED',
    );
  }

  @override
  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  }) async {
    return state.processes
        .where(
          (p) =>
              p.tenantId == tenantId &&
              p.partnerId == partnerId &&
              p.status == 'PENDING_REEVALUATION',
        )
        .map(
          (p) => OpenAutoIssuanceProcessDto(
            processId: p.processId,
            salesOrderId: p.salesOrderId,
            partnerId: p.partnerId,
            status: p.status,
          ),
        )
        .toList();
  }
}

final class _TestIssuanceResultGateway implements IIssuanceResultGateway {
  _TestIssuanceResultGateway(this.state, this.internalStore);

  final _TestState state;
  final _FakeInternalCommandStore internalStore;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    final attempt = state.attempts.firstWhere(
      (a) => a.attemptId == attemptId,
      orElse: () => throw StateError('Attempt not found: $attemptId'),
    );

    if (attempt.status == IssuanceAttemptStatus.succeeded ||
        attempt.status == IssuanceAttemptStatus.failed) {
      return const PublishPreparationDto(action: PublishPreparationAction.skip);
    }
    if (attempt.status == IssuanceAttemptStatus.submitted) {
      return const PublishPreparationDto(
        action: PublishPreparationAction.reconcileOnly,
      );
    }
    return const PublishPreparationDto(
      action: PublishPreparationAction.callProvider,
    );
  }

  @override
  Future<void> markProviderCallStarted({
    required String tenantId,
    required String attemptId,
  }) async {
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.submitted;
    attempt.providerReference ??= 'tx-inflight-$attemptId';
  }

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.succeeded;
    attempt.evidence = evidence;

    String? invNum;
    String? invSer;
    DateTime? issAt;

    if (evidence is IssuanceSuccessEvidenceDto) {
      attempt.providerReference = evidence.providerReference;
      invNum = evidence.invoiceNumber;
      invSer = evidence.invoiceSeries;
      issAt = evidence.issuedAt;
    }

    state.electronicInvoices[attempt.salesOrderId] = {
      'id': 'ei-$attemptId',
      'tenant_id': tenantId,
      'attempt_id': attemptId,
      'sales_order_id': attempt.salesOrderId,
      'invoice_number': invNum ?? '0000001',
      'invoice_series': invSer ?? '1C26TYY',
      'issued_at': issAt ?? DateTime.now().toUtc(),
    };

    // Resolve any open reconciliation case
    final rCaseIndex = state.reconciliationCases.indexWhere(
      (c) => c.attemptId == attemptId,
    );
    if (rCaseIndex != -1) {
      final existing = state.reconciliationCases[rCaseIndex];
      state.reconciliationCases[rCaseIndex] = ReconciliationCaseDto(
        caseId: existing.caseId,
        attemptId: existing.attemptId,
        status: ReconciliationCaseStatus.resolved,
      );
    }

    return RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.succeeded,
      electronicInvoiceId: 'ei-$attemptId',
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordDefiniteFailure({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.failed;
    attempt.evidence = evidence;
    if (evidence is IssuanceDefiniteFailureEvidenceDto) {
      attempt.lastErrorCode = evidence.providerCode;
    }

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
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.reconciling;
    attempt.evidence = evidence;

    final caseId = 'case-$attemptId';
    final existingIndex = state.reconciliationCases.indexWhere(
      (c) => c.caseId == caseId,
    );
    final caseDto = ReconciliationCaseDto(
      caseId: caseId,
      attemptId: attemptId,
      status: ReconciliationCaseStatus.pending,
    );

    if (existingIndex == -1) {
      state.reconciliationCases.add(caseDto);
      internalStore.pendingReconciliationCases.add(caseDto);
    }
    if (evidence is IssuanceUndeterminedEvidenceDto) {
      state.caseReasonCodes[caseId] = evidence.reasonCode;
    }

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
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.preparing;
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
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.failed;
    attempt.lastErrorCode = reasonCode;

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
    return recordCommandIntegrityFailure(
      tenantId: tenantId,
      attemptId: attemptId,
      reasonCode: reasonCode,
    );
  }
}

final class _TestIssuanceReconciliationGateway
    implements IIssuanceReconciliationGateway {
  _TestIssuanceReconciliationGateway(this.state, this.resultGateway);

  final _TestState state;
  final IIssuanceResultGateway resultGateway;

  @override
  Future<ReconciliationCaseDto> openReconciliationCase({
    required String tenantId,
    required String attemptId,
    required String reason,
  }) async {
    final caseId = 'case-$attemptId';
    final caseDto = ReconciliationCaseDto(
      caseId: caseId,
      attemptId: attemptId,
      status: ReconciliationCaseStatus.pending,
    );
    state.reconciliationCases.add(caseDto);
    return caseDto;
  }

  @override
  Future<ReconciliationPollContextDto?> claimReconciliationCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  }) async {
    final c = state.reconciliationCases.firstWhere(
      (caseItem) => caseItem.caseId == caseId,
      orElse: () => throw StateError('Case not found: $caseId'),
    );
    final attempt = state.attempts.firstWhere(
      (a) => a.attemptId == c.attemptId,
    );

    return ReconciliationPollContextDto(
      caseId: c.caseId,
      attemptId: c.attemptId,
      claimToken: 'tok-$caseId',
      idempotencyKey: attempt.idempotencyKey,
      payloadHash: attempt.payloadHash,
      invoiceSeries: attempt.invoiceSeries,
      providerReference: attempt.providerReference,
      reconciliationReasonCode: state.caseReasonCodes[caseId],
      checkSequence: state.caseCheckCounts[caseId] ?? 1,
      maxChecks: 5,
    );
  }

  @override
  Future<void> recordPendingCheck({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required Duration nextDelay,
    required int checkSequence,
  }) async {}

  @override
  Future<ReconciliationCaseDto> resolveReconciliationCase({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  }) async {
    final index = state.reconciliationCases.indexWhere(
      (c) => c.caseId == caseId,
    );
    final c = state.reconciliationCases[index];
    final updated = ReconciliationCaseDto(
      caseId: c.caseId,
      attemptId: c.attemptId,
      status: outcome == 'UNRESOLVED'
          ? ReconciliationCaseStatus.unresolved
          : ReconciliationCaseStatus.resolved,
    );
    state.reconciliationCases[index] = updated;
    return updated;
  }

  @override
  Future<void> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  }) async {
    final index = state.reconciliationCases.indexWhere(
      (c) => c.caseId == caseId,
    );
    if (index != -1) {
      final c = state.reconciliationCases[index];
      state.reconciliationCases[index] = ReconciliationCaseDto(
        caseId: c.caseId,
        attemptId: c.attemptId,
        status: ReconciliationCaseStatus.unresolved,
      );
    }
  }

  @override
  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  }) async {
    final attempt = state.attempts.firstWhere((a) => a.attemptId == attemptId);
    attempt.status = IssuanceAttemptStatus.succeeded;

    final providerSuccessEvidence =
        state.storedProviderEvidence[attemptId] ??
        {
          'invoice_number': '0000123',
          'invoice_series': '1C26TYY',
          'issued_at': '2026-08-29T12:00:00.000Z',
        };

    final electronicInvoiceId = 'ei-recovered-$attemptId';
    state.electronicInvoices[attempt.salesOrderId] = {
      'id': electronicInvoiceId,
      'tenant_id': tenantId,
      'attempt_id': attemptId,
      'sales_order_id': attempt.salesOrderId,
      'invoice_number': providerSuccessEvidence['invoice_number'],
      'invoice_series': providerSuccessEvidence['invoice_series'],
      'issued_at': providerSuccessEvidence['issued_at'],
    };

    final index = state.reconciliationCases.indexWhere(
      (c) => c.attemptId == attemptId,
    );
    if (index != -1) {
      final c = state.reconciliationCases[index];
      state.reconciliationCases[index] = ReconciliationCaseDto(
        caseId: c.caseId,
        attemptId: c.attemptId,
        status: ReconciliationCaseStatus.resolved,
      );
    }

    return RecoverInternalFinalizationResultDto(
      invoice: ElectronicInvoiceDto(
        electronicInvoiceId: electronicInvoiceId,
        salesOrderId: attempt.salesOrderId,
        invoiceNumber: providerSuccessEvidence['invoice_number']?.toString(),
      ),
    );
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    final attempt = state.attempts.firstWhere(
      (a) => a.salesOrderId == salesOrderId,
    );
    return IssuanceAttemptStatusDto(
      attemptId: attempt.attemptId,
      status: attempt.status,
      internalFinalizationStatus:
          attempt.status == IssuanceAttemptStatus.succeeded
          ? InternalFinalizationStatus.completed
          : InternalFinalizationStatus.pending,
      hasElectronicInvoice: state.electronicInvoices.containsKey(salesOrderId),
      hasActiveOperation:
          attempt.status == IssuanceAttemptStatus.preparing ||
          attempt.status == IssuanceAttemptStatus.submitted ||
          attempt.status == IssuanceAttemptStatus.waitingResult ||
          attempt.status == IssuanceAttemptStatus.reconciling,
      failureCode: attempt.lastErrorCode,
    );
  }
}

final class _TestIssuanceCommandGateway implements IIssuanceCommandGateway {
  _TestIssuanceCommandGateway(this.state, this.internalClient);

  final _TestState state;
  final _TestInternalCommandClient internalClient;

  @override
  Future<IssueInvoiceResultDto> issueInvoice(
    IssueInvoiceStartRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<IssueInvoiceResultDto> retryIssuance(
    RetryIssuanceStartRequest request,
  ) async {
    final previousAttempt = state.attempts.lastWhere(
      (a) => a.salesOrderId == request.salesOrderId,
      orElse: () => throw StateError(
        'Previous attempt not found for order: ${request.salesOrderId}',
      ),
    );

    if (previousAttempt.status != IssuanceAttemptStatus.failed) {
      throw StateError('Can only retry failed attempts');
    }

    // Check version lineage & completion
    final existingCompletion =
        state.buyerCompletions[previousAttempt.salesOrderId];
    String completionIdToUse;

    final targetVersion = 'sales-v${request.expectedOrderVersion}';
    if (targetVersion == previousAttempt.salesOrderVersion) {
      // Reuse locked completion, do not resolve from Theme 03
      if (existingCompletion == null || existingCompletion['locked'] != true) {
        throw StateError('Locked completion not found for same version');
      }
      completionIdToUse = existingCompletion['id'] as String;
    } else {
      // New version: do not reuse old completion
      if (request.expectedOrderVersion == 999) {
        throw StateError('New version not ready / not completed');
      }
      completionIdToUse = 'comp-new-$targetVersion';
      state.partnerResolveCount++;
      state.buyerCompletions[previousAttempt.salesOrderId] = {
        'id': completionIdToUse,
        'version': targetVersion,
        'locked': true,
      };
    }

    final newAttemptId =
        'att-${previousAttempt.salesOrderId}-retry-${request.idempotencyKey.substring(0, 8)}';
    final newAttempt = _InMemoryAttempt(
      attemptId: newAttemptId,
      tenantId: request.tenantId,
      salesOrderId: previousAttempt.salesOrderId,
      salesOrderVersion: targetVersion,
      idempotencyKey: request.idempotencyKey,
      payloadHash: 'hash-retry-$targetVersion',
      completionId: completionIdToUse,
      status: IssuanceAttemptStatus.preparing,
    );
    state.attempts.add(newAttempt);

    final publishCmd = PublishInvoiceCommand(
      tenantId: request.tenantId,
      attemptId: newAttemptId,
      idempotencyKey: request.idempotencyKey,
      payloadHash: newAttempt.payloadHash,
      canonicalInvoice: {
        '__attemptId': newAttemptId,
        'order_id': previousAttempt.salesOrderId,
        'sales_order_version': targetVersion,
      },
    );
    internalClient.enqueue(publishCmd);

    return IssueInvoiceResultDto(
      issuanceId: 'iss-${previousAttempt.salesOrderId}',
      attemptId: newAttemptId,
      status: IssuanceAttemptStatus.preparing,
    );
  }
}

// =============================================================================
// Test Suite Setup Helper
// =============================================================================

final class _Slice3TestHarness {
  late final GetIt container;
  late final _TestState state;
  late final _FakeInternalCommandStore internalStore;
  late final _TestInternalCommandClient internalClient;
  late final _TestEinvoiceInboxClient inboxClient;
  late final _FakeMeInvoiceProviderPort providerPort;
  late final CommandBus commandBus;
  late final EinvoiceIntegrationEventDispatcher integrationEventDispatcher;
  late final ProcessInboxCommandHandler processInboxHandler;
  late final ProcessInternalCommandsCommandHandler processInternalHandler;

  void setUp() {
    container = GetIt.asNewInstance();
    state = _TestState();
    internalStore = _FakeInternalCommandStore();
    final serializer = createGeneratedEinvoiceInternalCommandSerializer();
    internalClient = _TestInternalCommandClient(
      store: internalStore,
      serializer: serializer,
    );
    inboxClient = _TestEinvoiceInboxClient();
    providerPort = _FakeMeInvoiceProviderPort();

    final commandLogger = const NullLoggerFactory().named('einvoice.commands');
    commandBus = CommandBus(logger: commandLogger, container: container);
    container.registerSingleton<CommandBus>(commandBus);
    EinvoiceCommandsExecutor.bind(commandBus);

    final autoIssuanceGateway = _TestAutoIssuanceGateway(state, internalClient);
    final resultGateway = _TestIssuanceResultGateway(state, internalStore);
    final reconciliationGateway = _TestIssuanceReconciliationGateway(
      state,
      resultGateway,
    );
    final commandGateway = _TestIssuanceCommandGateway(state, internalClient);

    container
      ..registerSingleton<IAutoIssuanceGateway>(autoIssuanceGateway)
      ..registerSingleton<IIssuanceResultGateway>(resultGateway)
      ..registerSingleton<IIssuanceReconciliationGateway>(reconciliationGateway)
      ..registerSingleton<IIssuanceCommandGateway>(commandGateway)
      ..registerSingleton<IMeInvoiceProviderPort>(providerPort)
      ..registerSingleton<IPublishSeriesLeaseGateway>(
        InMemoryPublishSeriesLeaseGateway(
          attemptSeriesResolver: (attemptId) {
            for (final attempt in state.attempts) {
              if (attempt.attemptId == attemptId) {
                return attempt.invoiceSeries;
              }
            }
            return null;
          },
        ),
      )
      ..registerSingleton<InternalCommandSerializer>(serializer)
      ..registerSingleton<IEinvoiceInternalCommandClient>(internalClient)
      ..registerSingleton<IEinvoiceInboxClient>(inboxClient);

    final commandDispatcher = EinvoiceCommandDispatcher(commandBus: commandBus);
    container.registerSingleton<IEinvoiceCommandDispatcher>(commandDispatcher);

    // Register application command handlers
    final startAutoHandler = StartAutoIssuanceCommandHandler(
      gateway: autoIssuanceGateway,
    );
    final reevaluateHandler = ReevaluateAutoIssuanceCommandHandler(
      gateway: autoIssuanceGateway,
    );
    final publishHandler = PublishInvoiceCommandHandler(
      providerPort: providerPort,
      resultGateway: resultGateway,
      leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
    );
    final pollHandler = PollIssuanceStatusCommandHandler(
      reconciliationGateway: reconciliationGateway,
      providerPort: providerPort,
      commandDispatcher: commandDispatcher,
      resultGateway: resultGateway,
    );
    final recordResultHandler = RecordIssuanceResultCommandHandler(
      gateway: resultGateway,
    );
    final retryHandler = RetryIssuanceCommandHandler(gateway: commandGateway);
    final recoverHandler = RecoverInternalFinalizationCommandHandler(
      gateway: reconciliationGateway,
    );
    final resolveCaseHandler = ResolveReconciliationCaseCommandHandler(
      gateway: reconciliationGateway,
    );

    commandBus.register<StartAutoIssuanceCommand, AutoIssuanceResultDto>(
      (cmd) => startAutoHandler.handle(cmd),
    );
    commandBus.register<ReevaluateAutoIssuanceCommand, AutoIssuanceResultDto>(
      (cmd) => reevaluateHandler.handle(cmd),
    );
    commandBus.register<PublishInvoiceCommand, void>(
      (cmd) => publishHandler.handle(cmd),
    );
    commandBus.register<PollIssuanceStatusCommand, void>(
      (cmd) => pollHandler.handle(cmd),
    );
    commandBus.register<RecordIssuanceResultCommand, RecordIssuanceResultDto>(
      (cmd) => recordResultHandler.handle(cmd),
    );
    commandBus.register<RetryIssuanceCommand, IssueInvoiceResultDto>(
      (cmd) => retryHandler.handle(cmd),
    );
    commandBus.register<
      RecoverInternalFinalizationCommand,
      RecoverInternalFinalizationResultDto
    >((cmd) => recoverHandler.handle(cmd));
    commandBus
        .register<ResolveReconciliationCaseCommand, ReconciliationCaseDto>(
          (cmd) => resolveCaseHandler.handle(cmd),
        );

    // Register integration event dispatcher and handlers
    integrationEventDispatcher = EinvoiceIntegrationEventDispatcher();
    final salesOrderCompletedHandler =
        SalesOrderFinalizedIntegrationEventHandler(commands: commandDispatcher);
    final partnerProfileUpdatedHandler =
        PartnerProfileUpdatedIntegrationEventHandler(
          gateway: autoIssuanceGateway,
          commands: commandDispatcher,
        );
    final providerResultHandler =
        ProviderIssuanceResultReceivedIntegrationEventHandler(
          commands: commandDispatcher,
        );

    integrationEventDispatcher
      ..register<SalesOrderFinalizedIntegrationEvent>(
        salesOrderCompletedHandler,
      )
      ..register<PartnerProfileUpdatedIntegrationEvent>(
        partnerProfileUpdatedHandler,
      )
      ..register<ProviderIssuanceResultReceivedIntegrationEvent>(
        providerResultHandler,
      );

    processInboxHandler = ProcessInboxCommandHandler(
      inboxClient: inboxClient,
      integrationEventDispatcher: integrationEventDispatcher,
    );
    final deadLetterHandlers =
        <String, IEinvoiceInternalCommandDeadLetterHandler>{
          PublishInvoiceCommand.type: PublishInvoiceCommandDeadLetterHandler(
            resultGateway: resultGateway,
          ),
        };
    processInternalHandler = ProcessInternalCommandsCommandHandler(
      commandClient: internalClient,
      serializer: serializer,
      deadLetterHandlers: deadLetterHandlers,
    );

    commandBus.register<ProcessInboxCommand, bool>(
      (cmd) => processInboxHandler.handle(cmd),
    );
    commandBus.register<ProcessInternalCommandsCommand, bool>(
      (cmd) => processInternalHandler.handle(cmd),
    );
  }
}

// =============================================================================
// Integration Tests Suite
// =============================================================================

void main() {
  late _Slice3TestHarness harness;
  const tenantId = 'tenant-slice3-1';

  setUp(() {
    harness = _Slice3TestHarness()..setUp();
  });

  group('TH-08 Slice 3 End-to-End & Boundary Verification', () {
    test(
      'e2e_e02_u03_sc01_01: sales_order_finalized.v1 -> inbox -> StartAutoIssuance -> attempt -> publish command',
      () async {
        // Given a sales_order_finalized.v1 event arrives in inbox
        harness.inboxClient.addMessage(
          messageId: 'msg-sales-001',
          eventType: SalesOrderFinalizedIntegrationEvent.type,
          tenantId: tenantId,
          payload: {
            'id': 'msg-sales-001',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': tenantId,
            'sales_order_id': 'order-e2e-1',
            'source_version': 'sales-v1',
          },
        );

        // When inbox message is processed
        final inboxProcessed = await harness.commandBus.execute(
          ProcessInboxCommand(tenantId: tenantId),
        );
        expect(inboxProcessed, isTrue);
        expect(harness.inboxClient.completedIds, contains('msg-sales-001'));

        // Assert process & attempt created in store
        expect(harness.state.processes, hasLength(1));
        final proc = harness.state.processes.first;
        expect(proc.salesOrderId, 'order-e2e-1');
        expect(proc.status, 'ATTEMPT_STARTED');
        expect(harness.state.attempts, hasLength(1));

        // When internal worker processes internal commands
        final workerProcessed = await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );
        expect(workerProcessed, isTrue);

        // Assert publish occurred and invoice was recorded
        expect(harness.providerPort.publishCount, 1);
        expect(harness.state.electronicInvoices, contains('order-e2e-1'));
        final ei =
            harness.state.electronicInvoices['order-e2e-1']
                as Map<String, dynamic>;
        expect(ei['invoice_number'], '0000001');
        expect(ei['invoice_series'], '1C26TYY');
      },
    );

    test(
      'scn_e02_u03_fr09_01: partner update -> existing PENDING_REEVALUATION process -> first attempt; process row count unchanged',
      () async {
        // Given an existing process in PENDING_REEVALUATION status
        final existingProcess = _InMemoryAutoIssuanceProcess(
          processId: 'proc-pending-1',
          tenantId: tenantId,
          salesOrderId: 'order-reeval-1',
          salesOrderVersion: 'sales-v1',
          triggerKey:
              'sales_order_finalized.v1:orig-trigger:order-reeval-1:sales-v1',
          status: 'PENDING_REEVALUATION',
          partnerId: 'partner-100',
        );
        harness.state.processes.add(existingProcess);
        final initialProcessCount = harness.state.processes.length;

        // When partner update event arrives in inbox
        harness.inboxClient.addMessage(
          messageId: 'msg-partner-001',
          eventType: PartnerProfileUpdatedIntegrationEvent.type,
          tenantId: tenantId,
          payload: {
            'id': 'msg-partner-001',
            'occurred_on': '2026-08-29T10:05:00.000Z',
            'tenant_id': tenantId,
            'partner_id': 'partner-100',
            'partner_version': 'part-v2',
          },
        );

        final inboxProcessed = await harness.commandBus.execute(
          ProcessInboxCommand(tenantId: tenantId),
        );
        expect(inboxProcessed, isTrue);

        // Assert process row count unchanged, original trigger key preserved, first attempt created
        expect(harness.state.processes.length, initialProcessCount);
        expect(existingProcess.status, 'ATTEMPT_STARTED');
        expect(
          existingProcess.triggerKey,
          'sales_order_finalized.v1:orig-trigger:order-reeval-1:sales-v1',
        );
        expect(harness.state.attempts, hasLength(1));
        expect(harness.state.attempts.first.salesOrderId, 'order-reeval-1');

        // When worker executes publish
        await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );
        expect(harness.providerPort.publishCount, 1);
      },
    );

    test(
      'e2e_e02_u04_sc01_01: publish unknown -> due poll -> getStatus success -> ElectronicInvoice recorded',
      () async {
        // Given an attempt where publish encounters undetermined result (e.g. timeout)
        const attemptId = 'att-unknown-1';
        final attempt = _InMemoryAttempt(
          attemptId: attemptId,
          tenantId: tenantId,
          salesOrderId: 'order-unknown-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-unknown-1',
          payloadHash: 'hash-u1',
          completionId: 'comp-1',
          status: IssuanceAttemptStatus.preparing,
        );
        harness.state.attempts.add(attempt);

        harness.providerPort.nextPublishOutcome =
            const MeInvoicePublishUndetermined(reasonCode: 'NETWORK_TIMEOUT');

        // Execute publish command -> results in reconciling state + pending reconciliation case
        harness.internalClient.enqueue(
          PublishInvoiceCommand(
            tenantId: tenantId,
            attemptId: attemptId,
            idempotencyKey: 'idem-unknown-1',
            payloadHash: 'hash-u1',
            canonicalInvoice: {'__attemptId': attemptId},
          ),
        );

        await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );
        expect(harness.providerPort.publishCount, 1);
        expect(attempt.status, IssuanceAttemptStatus.reconciling);
        expect(harness.state.reconciliationCases, hasLength(1));
        final rCase = harness.state.reconciliationCases.first;
        expect(rCase.status, ReconciliationCaseStatus.pending);

        // When worker seeds due reconciliation commands and polls status
        harness.providerPort.nextStatusOutcome =
            MeInvoiceIssuanceStatusOutcome.success(
              IssuanceResultEvidenceDto.success(
                    idempotencyKey: 'idem-unknown-1',
                    payloadHash: 'hash-u1',
                    providerReference: 'tx-resolved-1',
                    invoiceNumber: '0000088',
                    invoiceSeries: '1C26TYY',
                    issuedAt: DateTime.utc(2026, 8, 29, 12, 30, 0),
                  )
                  as IssuanceSuccessEvidenceDto,
            );

        // Seed poll command
        await harness.internalClient.seedDueReconciliationCommands(
          tenantId: tenantId,
        );

        // Execute poll command via worker
        await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );

        // Assert status query succeeded, invoice recorded, case resolved, publishCount still 1 (no republish)
        expect(harness.providerPort.getStatusCount, 1);
        expect(harness.providerPort.publishCount, 1);
        expect(attempt.status, IssuanceAttemptStatus.succeeded);
        expect(
          harness.state.reconciliationCases.first.status,
          ReconciliationCaseStatus.resolved,
        );
        expect(harness.state.electronicInvoices, contains('order-unknown-1'));
        final ei =
            harness.state.electronicInvoices['order-unknown-1']
                as Map<String, dynamic>;
        expect(ei['invoice_number'], '0000088');
      },
    );

    test(
      'pending_handoff_existing_case_01: pending case existing/no queue row -> worker seed -> poll, no publish',
      () async {
        // Given a pending case created before S3 queue row existed
        const attemptId = 'att-preexisting-1';
        final attempt = _InMemoryAttempt(
          attemptId: attemptId,
          tenantId: tenantId,
          salesOrderId: 'order-preexisting-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-preexisting-1',
          payloadHash: 'hash-pre',
          completionId: 'comp-pre',
          status: IssuanceAttemptStatus.submitted,
        )..providerReference = 'tx-pre-1';
        harness.state.attempts.add(attempt);

        final preexistingCase = ReconciliationCaseDto(
          caseId: 'case-preexisting-1',
          attemptId: attemptId,
          status: ReconciliationCaseStatus.pending,
        );
        harness.state.reconciliationCases.add(preexistingCase);
        harness.internalStore.pendingReconciliationCases.add(preexistingCase);

        // When worker seeds due reconciliation commands
        final seeded = await harness.internalClient
            .seedDueReconciliationCommands(tenantId: tenantId);
        expect(seeded, 1);

        // When worker executes poll command
        harness.providerPort.nextStatusOutcome =
            MeInvoiceIssuanceStatusOutcome.success(
              IssuanceResultEvidenceDto.success(
                    idempotencyKey: 'idem-preexisting-1',
                    payloadHash: 'hash-pre',
                    providerReference: 'tx-pre-1',
                    invoiceNumber: '0000099',
                    invoiceSeries: '1C26TYY',
                    issuedAt: DateTime.utc(2026, 8, 29, 12, 0, 0),
                  )
                  as IssuanceSuccessEvidenceDto,
            );

        await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );

        // Assert only status queried, no publish called (publishCount == 0)
        expect(harness.providerPort.publishCount, 0);
        expect(harness.providerPort.getStatusCount, 1);
        expect(attempt.status, IssuanceAttemptStatus.succeeded);
      },
    );

    test(
      'scn_e02_u04_fr08_02: 5 checks undetermined -> UNRESOLVED, no republish',
      () async {
        // Given an attempt and a case that is on its 5th check
        const attemptId = 'att-undetermined-5';
        final attempt = _InMemoryAttempt(
          attemptId: attemptId,
          tenantId: tenantId,
          salesOrderId: 'order-undetermined-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-undetermined-1',
          payloadHash: 'hash-u5',
          completionId: 'comp-u5',
          status: IssuanceAttemptStatus.submitted,
        )..providerReference = 'tx-u5-1';
        harness.state.attempts.add(attempt);

        final caseDto = ReconciliationCaseDto(
          caseId: 'case-u5',
          attemptId: attemptId,
          status: ReconciliationCaseStatus.pending,
        );
        harness.state.reconciliationCases.add(caseDto);
        harness.state.caseCheckCounts['case-u5'] = 5;

        // Provider returns undetermined on 5th check
        harness.providerPort.nextStatusOutcome =
            const MeInvoiceIssuanceStatusOutcome.undetermined(
              'PROVIDER_TIMEOUT',
            );

        // When 5th poll check runs
        final pollCmd = PollIssuanceStatusCommand(
          tenantId: tenantId,
          caseId: 'case-u5',
          attemptId: attemptId,
          correlationId: 'corr-u5',
          checkOrdinal: 5,
        );
        await harness.commandBus.execute(pollCmd);

        // Assert case transitions to UNRESOLVED, publish count remains 0 (no republish), lock preserved
        expect(harness.providerPort.publishCount, 0);
        expect(harness.providerPort.getStatusCount, 1);
        expect(
          harness.state.reconciliationCases.first.status,
          ReconciliationCaseStatus.unresolved,
        );
      },
    );

    test(
      'scn_e02_u04_fr08_03: stored provider success -> recovery -> local finalization completed, no MISA call',
      () async {
        // Given an attempt that succeeded at provider but local finalization was interrupted
        const attemptId = 'att-recover-1';
        final attempt = _InMemoryAttempt(
          attemptId: attemptId,
          tenantId: tenantId,
          salesOrderId: 'order-recover-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-rec-1',
          payloadHash: 'hash-rec-1',
          completionId: 'comp-rec-1',
          status: IssuanceAttemptStatus.submitted,
        );
        harness.state.attempts.add(attempt);

        final caseDto = ReconciliationCaseDto(
          caseId: 'case-rec-1',
          attemptId: attemptId,
          status: ReconciliationCaseStatus.pending,
        );
        harness.state.reconciliationCases.add(caseDto);

        harness.state.storedProviderEvidence[attemptId] = {
          'invoice_number': '0000123',
          'invoice_series': '1C26TYY',
          'issued_at': '2026-08-29T12:00:00.000Z',
          'provider_reference': 'tx-rec-1',
        };

        // When RecoverInternalFinalizationCommand runs
        final result = await harness.commandBus.execute(
          RecoverInternalFinalizationCommand(
            tenantId: tenantId,
            attemptId: attemptId,
          ),
        );

        // Assert local finalization completed without calling MISA
        expect(result.invoice.electronicInvoiceId, isNotNull);
        expect(result.invoice.invoiceNumber, '0000123');
        expect(harness.providerPort.publishCount, 0);
        expect(harness.providerPort.getStatusCount, 0);
        expect(harness.state.electronicInvoices, contains('order-recover-1'));
        expect(attempt.status, IssuanceAttemptStatus.succeeded);
        expect(
          harness.state.reconciliationCases.first.status,
          ReconciliationCaseStatus.resolved,
        );
      },
    );

    test(
      'scn_e02_u04_fr01_02: valid terminal callback after UNRESOLVED -> attempt/case terminal, no republish',
      () async {
        // Given a case in UNRESOLVED state
        const attemptId = 'att-late-callback-1';
        final attempt = _InMemoryAttempt(
          attemptId: attemptId,
          tenantId: tenantId,
          salesOrderId: 'order-late-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-late-1',
          payloadHash: 'hash-late-1',
          completionId: 'comp-late-1',
          status: IssuanceAttemptStatus.submitted,
        );
        harness.state.attempts.add(attempt);

        final caseDto = ReconciliationCaseDto(
          caseId: 'case-late-1',
          attemptId: attemptId,
          status: ReconciliationCaseStatus.unresolved,
        );
        harness.state.reconciliationCases.add(caseDto);

        // When a valid terminal callback arrives via integration event
        harness.inboxClient.addMessage(
          messageId: 'msg-cb-001',
          eventType: ProviderIssuanceResultReceivedIntegrationEvent.type,
          tenantId: tenantId,
          payload: {
            'id': 'msg-cb-001',
            'occurred_on': '2026-08-29T14:00:00.000Z',
            'tenant_id': tenantId,
            'correlation_id': 'corr-cb-001',
            'attempt_id': attemptId,
            'outcome': 'success',
            'idempotency_key': 'idem-late-1',
            'payload_hash': 'hash-late-1',
            'provider_reference': 'tx-late-1',
            'invoice_number': '0000777',
            'invoice_series': '1C26TYY',
            'issued_at': '2026-08-29T14:00:00.000Z',
          },
        );

        final inboxProcessed = await harness.commandBus.execute(
          ProcessInboxCommand(tenantId: tenantId),
        );
        expect(inboxProcessed, isTrue);

        // Assert attempt and case are terminal with success evidence, no republish
        expect(attempt.status, IssuanceAttemptStatus.succeeded);
        expect(
          harness.state.reconciliationCases.first.status,
          ReconciliationCaseStatus.resolved,
        );
        expect(harness.providerPort.publishCount, 0);
        expect(harness.state.electronicInvoices, contains('order-late-1'));
      },
    );

    test(
      'e2e_e02_u05_sc01_01: definite failure -> RetryIssuance -> new attempt; old attempt & failure evidence immutable',
      () async {
        // Given an attempt that definitely failed
        const oldAttemptId = 'att-fail-1';
        final oldAttempt = _InMemoryAttempt(
          attemptId: oldAttemptId,
          tenantId: tenantId,
          salesOrderId: 'order-retry-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-orig-1',
          payloadHash: 'hash-orig-1',
          completionId: 'comp-retry-1',
          status: IssuanceAttemptStatus.failed,
        );
        oldAttempt.evidence = IssuanceResultEvidenceDto.definiteFailure(
          idempotencyKey: 'idem-orig-1',
          payloadHash: 'hash-orig-1',
          providerCode: 'INVALID_TAX_CODE',
          providerMessage: 'Buyer tax code is invalid',
        );
        oldAttempt.lastErrorCode = 'INVALID_TAX_CODE';
        harness.state.attempts.add(oldAttempt);

        // Buyer completion is locked
        harness.state.buyerCompletions['order-retry-1'] = {
          'id': 'comp-retry-1',
          'version': 'sales-v1',
          'locked': true,
        };

        // When RetryIssuanceCommand is executed with new idempotency key
        const retryKey = '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
        final retryResult = await harness.commandBus.execute(
          RetryIssuanceCommand(
            tenantId: tenantId,
            actorId: 'user-actor-1',
            salesOrderId: 'order-retry-1',
            expectedOrderVersion: 1,
            idempotencyKey: retryKey,
          ),
        );

        // Assert new attempt created with distinct attemptId
        expect(retryResult.attemptId, isNot(equals(oldAttemptId)));
        expect(harness.state.attempts, hasLength(2));

        // Assert old attempt and failure evidence remain unchanged
        expect(oldAttempt.status, IssuanceAttemptStatus.failed);
        expect(oldAttempt.lastErrorCode, 'INVALID_TAX_CODE');
        expect(
          (oldAttempt.evidence as IssuanceDefiniteFailureEvidenceDto)
              .providerCode,
          'INVALID_TAX_CODE',
        );

        // When worker executes retry publish
        await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );
        expect(harness.providerPort.publishCount, 1);
        expect(harness.state.electronicInvoices, contains('order-retry-1'));
      },
    );

    test(
      'scn_e02_u05_sc11_01: retry same SalesOrder version -> reuse LOCKED completion, no Theme 03 resolve',
      () async {
        // Given a failed attempt for sales-v1 with locked completion
        const oldAttemptId = 'att-same-ver-1';
        final oldAttempt = _InMemoryAttempt(
          attemptId: oldAttemptId,
          tenantId: tenantId,
          salesOrderId: 'order-same-ver-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-same-1',
          payloadHash: 'hash-same-1',
          completionId: 'comp-locked-v1',
          status: IssuanceAttemptStatus.failed,
        );
        harness.state.attempts.add(oldAttempt);

        harness.state.buyerCompletions['order-same-ver-1'] = {
          'id': 'comp-locked-v1',
          'version': 'sales-v1',
          'locked': true,
        };

        // When retry is executed for the same sales-v1 version
        const retryKey = '8a1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6e';
        final retryResult = await harness.commandBus.execute(
          RetryIssuanceCommand(
            tenantId: tenantId,
            actorId: 'user-actor-1',
            salesOrderId: 'order-same-ver-1',
            expectedOrderVersion: 1,
            idempotencyKey: retryKey,
          ),
        );

        // Assert completion ID was reused, no partner resolve called
        final newAttempt = harness.state.attempts.firstWhere(
          (a) => a.attemptId == retryResult.attemptId,
        );
        expect(newAttempt.completionId, 'comp-locked-v1');
        expect(harness.state.partnerResolveCount, 0);
      },
    );

    test(
      'scn_e02_u05_sc12_01: retry after new SalesOrder version -> do not reuse old completion; wait for new version readiness/completion',
      () async {
        // Given a failed attempt for sales-v1
        const oldAttemptId = 'att-diff-ver-1';
        final oldAttempt = _InMemoryAttempt(
          attemptId: oldAttemptId,
          tenantId: tenantId,
          salesOrderId: 'order-diff-ver-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-diff-1',
          payloadHash: 'hash-diff-1',
          completionId: 'comp-locked-v1',
          status: IssuanceAttemptStatus.failed,
        );
        harness.state.attempts.add(oldAttempt);

        harness.state.buyerCompletions['order-diff-ver-1'] = {
          'id': 'comp-locked-v1',
          'version': 'sales-v1',
          'locked': true,
        };

        // When retry is executed with new version that is NOT ready (version 999)
        const retryKey = '7a1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6f';
        expect(
          () => harness.commandBus.execute(
            RetryIssuanceCommand(
              tenantId: tenantId,
              actorId: 'user-actor-1',
              salesOrderId: 'order-diff-ver-1',
              expectedOrderVersion: 999,
              idempotencyKey: retryKey,
            ),
          ),
          throwsA(isA<StateError>()),
        );

        // When retry is executed with new version that IS ready (sales-v2)
        final retryResult = await harness.commandBus.execute(
          RetryIssuanceCommand(
            tenantId: tenantId,
            actorId: 'user-actor-1',
            salesOrderId: 'order-diff-ver-1',
            expectedOrderVersion: 2,
            idempotencyKey: retryKey,
          ),
        );

        final newAttempt = harness.state.attempts.firstWhere(
          (a) => a.attemptId == retryResult.attemptId,
        );
        // Assert old completion was NOT reused, fresh completion created
        expect(newAttempt.completionId, isNot(equals('comp-locked-v1')));
        expect(newAttempt.completionId, 'comp-new-sales-v2');
        expect(harness.state.partnerResolveCount, 1);
      },
    );

    test(
      's2b_command_integrity_dead_letter_01: canonical mismatch -> bounded dead-letter -> failed/no action/no provider call',
      () async {
        // Given an attempt with mismatched canonical payload
        const attemptId = 'att-corrupt-1';
        final attempt = _InMemoryAttempt(
          attemptId: attemptId,
          tenantId: tenantId,
          salesOrderId: 'order-corrupt-1',
          salesOrderVersion: 'sales-v1',
          idempotencyKey: 'idem-corrupt-1',
          payloadHash: 'hash-expected-1',
          completionId: 'comp-corrupt-1',
          status: IssuanceAttemptStatus.preparing,
        );
        harness.state.attempts.add(attempt);

        // Enqueue corrupted command
        harness.internalClient.enqueue(
          PublishInvoiceCommand(
            tenantId: tenantId,
            attemptId: attemptId,
            idempotencyKey: 'idem-corrupt-1',
            payloadHash: 'hash-corrupted-2',
            canonicalInvoice: {
              '__attemptId': attemptId,
              'canonical_hash_mismatch': true,
            },
          ),
        );

        // When worker processes internal commands
        await harness.commandBus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId),
        );

        // Assert dead letter marked attempt as FAILED with COMMAND_INTEGRITY, no provider call made
        expect(harness.providerPort.publishCount, 0);
        expect(attempt.status, IssuanceAttemptStatus.failed);
        expect(attempt.lastErrorCode, 'COMMAND_INTEGRITY');
      },
    );
  });
}
