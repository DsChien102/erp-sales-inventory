import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_integration_event_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/publish_invoice_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';

final class _TrackingAutoIssuanceGateway implements IAutoIssuanceGateway {
  final List<AutoIssuanceStartRequest> startRequests = [];
  final List<AutoIssuanceReevaluationRequest> reevaluationRequests = [];
  final List<OpenAutoIssuanceProcessDto> openProcesses = [];

  @override
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request) async {
    startRequests.add(request);
    return const AutoIssuanceResultDto(
      started: true,
      processId: 'proc-1',
      status: 'INELIGIBLE',
      reason: 'ORDER_NOT_READY',
    );
  }

  @override
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  ) async {
    reevaluationRequests.add(request);
    return AutoIssuanceResultDto(
      started: true,
      processId: request.processId,
      status: 'REVAL_COMPLETED',
      reason: 'AUTO_ISSUED',
    );
  }

  @override
  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  }) async {
    return openProcesses;
  }
}

final class _TrackingIssuanceReconciliationGateway
    implements IIssuanceReconciliationGateway {
  final List<String> openCaseCalls = [];
  final List<String> resolveCaseCalls = [];
  final List<String> recoverCalls = [];
  final List<String> attemptStatusQueries = [];

  @override
  Future<ReconciliationCaseDto> openReconciliationCase({
    required String tenantId,
    required String attemptId,
    required String reason,
  }) async {
    openCaseCalls.add('$tenantId:$attemptId:$reason');
    return const ReconciliationCaseDto(
      caseId: 'case-1',
      attemptId: 'att-1',
      status: ReconciliationCaseStatus.pending,
    );
  }

  @override
  Future<ReconciliationCaseDto> resolveReconciliationCase({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  }) async {
    resolveCaseCalls.add('$tenantId:$caseId:$outcome');
    return ReconciliationCaseDto(
      caseId: caseId,
      attemptId: 'att-1',
      status: ReconciliationCaseStatus.resolved,
    );
  }

  @override
  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  }) async {
    recoverCalls.add('$tenantId:$attemptId');
    return const RecoverInternalFinalizationResultDto(
      invoice: ElectronicInvoiceDto(
        electronicInvoiceId: 'ei-1',
        salesOrderId: 'order-1',
        invoiceNumber: '0000001',
      ),
    );
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    attemptStatusQueries.add('$tenantId:$actorId:$salesOrderId');
    return const IssuanceAttemptStatusDto(
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.reconciling,
      internalFinalizationStatus: InternalFinalizationStatus.pending,
      hasActiveOperation: true,
      hasElectronicInvoice: false,
    );
  }

  @override
  Future<ReconciliationPollContextDto?> claimReconciliationCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  }) async => throw UnimplementedError();

  @override
  Future<void> recordPendingCheck({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required Duration nextDelay,
    required int checkSequence,
  }) async => throw UnimplementedError();

  @override
  Future<void> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  }) async => throw UnimplementedError();
}

final class _TrackingIssuanceCommandGateway implements IIssuanceCommandGateway {
  final List<RetryIssuanceStartRequest> retryRequests = [];

  @override
  Future<IssueInvoiceResultDto> issueInvoice(
    IssueInvoiceStartRequest request,
  ) async => throw UnimplementedError();

  @override
  Future<IssueInvoiceResultDto> retryIssuance(
    RetryIssuanceStartRequest request,
  ) async {
    retryRequests.add(request);
    return const IssueInvoiceResultDto(
      issuanceId: 'iss-1',
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.succeeded,
    );
  }
}

final class _TrackingIssuanceResultGateway implements IIssuanceResultGateway {
  final List<String> resultCalls = [];
  final List<String> deadLetterCalls = [];

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    resultCalls.add('success:$tenantId:$attemptId');
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
    resultCalls.add('failure:$tenantId:$attemptId');
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
    resultCalls.add('undetermined:$tenantId:$attemptId');
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
    resultCalls.add('retryable:$tenantId:$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.preparing,
    );
  }

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
  }) async {
    deadLetterCalls.add('$tenantId:$attemptId:$reasonCode');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }
}

void main() {
  group('Einvoice S3 Registration & Wiring Tests', () {
    late GetIt container;
    late _TrackingAutoIssuanceGateway autoIssuanceGateway;
    late _TrackingIssuanceReconciliationGateway reconciliationGateway;
    late _TrackingIssuanceCommandGateway issuanceCommandGateway;
    late _TrackingIssuanceResultGateway issuanceResultGateway;
    late EinvoiceRuntime runtime;

    setUp(() {
      container = GetIt.asNewInstance();
      autoIssuanceGateway = _TrackingAutoIssuanceGateway();
      reconciliationGateway = _TrackingIssuanceReconciliationGateway();
      issuanceCommandGateway = _TrackingIssuanceCommandGateway();
      issuanceResultGateway = _TrackingIssuanceResultGateway();

      // Pre-register gateways into container before initializeForTesting
      container
        ..registerSingleton<IAutoIssuanceGateway>(autoIssuanceGateway)
        ..registerSingleton<IIssuanceReconciliationGateway>(
          reconciliationGateway,
        )
        ..registerSingleton<IIssuanceCommandGateway>(issuanceCommandGateway)
        ..registerSingleton<IIssuanceResultGateway>(issuanceResultGateway);

      runtime = EinvoiceStartup.initializeForTesting(
        supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
        container: container,
      );
    });

    test(
      'Mediator executes StartAutoIssuanceCommand and reaches IAutoIssuanceGateway',
      () async {
        final mediator = runtime.module;
        final result = await mediator.executeCommandAsync(
          StartAutoIssuanceCommand(
            tenantId: 'tenant-1',
            salesOrderId: 'order-100',
            triggerKey: 'trig-100',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          ),
        );

        expect(result.processId, 'proc-1');
        expect(autoIssuanceGateway.startRequests, hasLength(1));
        expect(
          autoIssuanceGateway.startRequests.single.salesOrderId,
          'order-100',
        );
      },
    );

    test(
      'Mediator executes ReevaluateAutoIssuanceCommand and reaches IAutoIssuanceGateway',
      () async {
        final mediator = runtime.module;
        final result = await mediator.executeCommandAsync(
          ReevaluateAutoIssuanceCommand(
            tenantId: 'tenant-1',
            processId: 'proc-1',
            sourceEventId: 'evt-200',
          ),
        );

        expect(result.processId, 'proc-1');
        expect(autoIssuanceGateway.reevaluationRequests, hasLength(1));
        expect(
          autoIssuanceGateway.reevaluationRequests.single.processId,
          'proc-1',
        );
      },
    );

    test(
      'Mediator executes S3b/S3c reconciliation commands and queries',
      () async {
        final mediator = runtime.module;

        // OpenReconciliationCaseCommand
        final openRes = await mediator.executeCommandAsync(
          OpenReconciliationCaseCommand(
            tenantId: 'tenant-1',
            attemptId: 'att-1',
            reason: 'MANUAL_AUDIT',
          ),
        );
        expect(openRes.caseId, 'case-1');
        expect(
          reconciliationGateway.openCaseCalls,
          contains('tenant-1:att-1:MANUAL_AUDIT'),
        );

        // ResolveReconciliationCaseCommand
        final resolveRes = await mediator.executeCommandAsync(
          ResolveReconciliationCaseCommand(
            tenantId: 'tenant-1',
            caseId: 'case-1',
            outcome: 'SUCCESS',
            evidence: const {
              'provider_reference': 'tx-1',
              'invoice_number': '000001',
              'invoice_series': '1C26TYY',
              'issued_at': '2026-08-31T00:00:00.000Z',
            },
          ),
        );
        expect(resolveRes.caseId, 'case-1');
        expect(
          reconciliationGateway.resolveCaseCalls,
          contains('tenant-1:case-1:SUCCESS'),
        );

        // RecoverInternalFinalizationCommand
        final recoverRes = await mediator.executeCommandAsync(
          RecoverInternalFinalizationCommand(
            tenantId: 'tenant-1',
            attemptId: 'att-1',
          ),
        );
        expect(recoverRes.invoice.electronicInvoiceId, 'ei-1');
        expect(reconciliationGateway.recoverCalls, contains('tenant-1:att-1'));

        // RetryIssuanceCommand
        final retryRes = await mediator.executeCommandAsync(
          RetryIssuanceCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            salesOrderId: 'order-100',
            expectedOrderVersion: 2,
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          ),
        );
        expect(retryRes.issuanceId, 'iss-1');
        expect(issuanceCommandGateway.retryRequests, hasLength(1));
        expect(
          issuanceCommandGateway.retryRequests.single.salesOrderId,
          'order-100',
        );

        // RecordIssuanceResultCommand
        final recordRes = await mediator.executeCommandAsync(
          RecordIssuanceResultCommand(
            tenantId: 'tenant-1',
            attemptId: 'att-1',
            correlationId: 'corr-1',
            evidence: IssuanceSuccessEvidenceDto(
              idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
              payloadHash: 'hash-1',
              providerReference: 'ref-1',
              invoiceNumber: '001',
              invoiceSeries: '1C25TYY',
              issuedAt: DateTime.utc(2026, 8, 29),
            ),
          ),
        );
        expect(recordRes.attemptStatus, IssuanceAttemptStatus.succeeded);
        expect(
          issuanceResultGateway.resultCalls,
          contains('success:tenant-1:att-1'),
        );

        // GetIssuanceAttemptStatusQuery
        final statusRes = await mediator.executeQueryAsync(
          GetIssuanceAttemptStatusQuery(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            salesOrderId: 'order-100',
          ),
        );
        expect(statusRes.attemptId, 'att-1');
        expect(statusRes.status, IssuanceAttemptStatus.reconciling);
        expect(
          reconciliationGateway.attemptStatusQueries,
          contains('tenant-1:user-1:order-100'),
        );
      },
    );

    test('InternalCommandSerializer round-trips PollIssuanceStatusCommand', () {
      final serializer = createGeneratedEinvoiceInternalCommandSerializer();
      final cmd = PollIssuanceStatusCommand(
        id: 'cmd-poll-1',
        tenantId: 'tenant-1',
        caseId: 'case-100',
        attemptId: 'att-100',
        correlationId: 'corr-100',
        checkOrdinal: 2,
      );

      final row = <String, dynamic>{
        'command_id': cmd.id,
        'command_type': serializer.commandTypeOf(cmd),
        'payload': serializer.toPayload(cmd),
        'enqueued_at': DateTime.utc(2026, 8, 29).toIso8601String(),
        'claim_token': 'tok-1',
      };

      final deserialized = serializer.deserializeRow(row);
      expect(deserialized, isA<PollIssuanceStatusCommand>());
      final pollCmd = deserialized as PollIssuanceStatusCommand;
      expect(pollCmd.id, 'cmd-poll-1');
      expect(pollCmd.tenantId, 'tenant-1');
      expect(pollCmd.caseId, 'case-100');
      expect(pollCmd.attemptId, 'att-100');
      expect(pollCmd.correlationId, 'corr-100');
      expect(pollCmd.checkOrdinal, 2);
    });

    test(
      'Dead-letter handler for PublishInvoiceCommand is wired and delegable',
      () async {
        final deadLetterHandler = PublishInvoiceCommandDeadLetterHandler(
          resultGateway: issuanceResultGateway,
        );

        final claimedCmd = ClaimedInternalCommand(
          commandId: 'cmd-dead-1',
          commandType: 'einvoice.publish_invoice',
          payload: {
            'attempt_id': 'att-dead-1',
            'idempotency_key': '88d18970-380a-4138-bbce-e25049ca9e3c',
          },
          enqueuedAt: DateTime.utc(2026, 8, 29),
          claimToken: 'tok-dead-1',
          retryCount: 3,
        );

        await deadLetterHandler.handleDeadLetter(
          tenantId: 'tenant-1',
          command: claimedCmd,
          error: Exception('Provider timeout permanently'),
        );

        expect(
          issuanceResultGateway.deadLetterCalls,
          contains(
            predicate((String s) => s.startsWith('tenant-1:att-dead-1:')),
          ),
        );
      },
    );

    test(
      'Inbox dispatcher recognizes all 3 Slice 3 integration event types',
      () {
        expect(
          EinvoiceIntegrationEventRegistry
              .eventTypes[SalesOrderFinalizedIntegrationEvent],
          SalesOrderFinalizedIntegrationEvent.type,
        );
        expect(
          EinvoiceIntegrationEventRegistry
              .eventTypes[PartnerProfileUpdatedIntegrationEvent],
          PartnerProfileUpdatedIntegrationEvent.type,
        );
        expect(
          EinvoiceIntegrationEventRegistry
              .eventTypes[ProviderIssuanceResultReceivedIntegrationEvent],
          ProviderIssuanceResultReceivedIntegrationEvent.type,
        );

        final salesEvt = EinvoiceIntegrationEventRegistry.fromJson(
          eventType: SalesOrderFinalizedIntegrationEvent.type,
          payload: {
            'id': 'evt-s-1',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': 'tenant-1',
            'sales_order_id': 'order-1',
            'source_version': 'sales-v1',
          },
        );
        expect(salesEvt, isA<SalesOrderFinalizedIntegrationEvent>());

        expect(
          EinvoiceIntegrationEventRegistry.fromJson(
            eventType: 'sales.order.completed',
            payload: {
              'id': 'evt-legacy-1',
              'occurred_on': '2026-08-29T10:00:00.000Z',
              'tenant_id': 'tenant-1',
              'sales_order_id': 'order-1',
              'source_version': 'sales-v1',
            },
          ),
          isNull,
        );

        final partnerEvt = EinvoiceIntegrationEventRegistry.fromJson(
          eventType: PartnerProfileUpdatedIntegrationEvent.type,
          payload: {
            'id': 'evt-p-1',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': 'tenant-1',
            'partner_id': 'partner-1',
          },
        );
        expect(partnerEvt, isA<PartnerProfileUpdatedIntegrationEvent>());

        final resultEvt = EinvoiceIntegrationEventRegistry.fromJson(
          eventType: ProviderIssuanceResultReceivedIntegrationEvent.type,
          payload: {
            'id': 'evt-r-1',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': 'tenant-1',
            'attempt_id': 'att-1',
            'correlation_id': 'corr-1',
            'idempotency_key': 'idemp-1',
            'payload_hash': 'hash-1',
            'outcome': 'success',
            'invoice_number': '001',
            'invoice_series': '1C25TYY',
            'issued_at': '2026-08-29T10:00:00.000Z',
          },
        );
        expect(
          resultEvt,
          isA<ProviderIssuanceResultReceivedIntegrationEvent>(),
        );
      },
    );

    test(
      'PartnerProfileUpdated handler queries open processes and only dispatches ReevaluateAutoIssuanceCommand',
      () async {
        autoIssuanceGateway.openProcesses.add(
          const OpenAutoIssuanceProcessDto(
            processId: 'proc-open-1',
            salesOrderId: 'order-1',
          ),
        );

        final dispatcher = createGeneratedEinvoiceIntegrationEventDispatcher(
          container,
        );
        final partnerEvt = PartnerProfileUpdatedIntegrationEvent(
          id: 'evt-partner-update-1',
          occurredOn: DateTime.utc(2026, 8, 29),
          tenantId: 'tenant-1',
          partnerId: 'partner-1',
        );

        await dispatcher.publish(partnerEvt);

        expect(autoIssuanceGateway.reevaluationRequests, hasLength(1));
        expect(
          autoIssuanceGateway.reevaluationRequests.single.processId,
          'proc-open-1',
        );
        expect(
          autoIssuanceGateway.reevaluationRequests.single.sourceEventId,
          'evt-partner-update-1',
        );
        // Proves no direct issue or start commands were run
        expect(autoIssuanceGateway.startRequests, isEmpty);
        expect(issuanceCommandGateway.retryRequests, isEmpty);
      },
    );

    test(
      'SalesOrderFinalized handler only dispatches StartAutoIssuanceCommand',
      () async {
        final dispatcher = createGeneratedEinvoiceIntegrationEventDispatcher(
          container,
        );
        final salesEvt = SalesOrderFinalizedIntegrationEvent(
          id: 'evt-sales-order-1',
          occurredOn: DateTime.utc(2026, 8, 29),
          tenantId: 'tenant-1',
          salesOrderId: 'order-100',
          sourceVersion: 'v1.0',
        );

        await dispatcher.publish(salesEvt);

        expect(autoIssuanceGateway.startRequests, hasLength(1));
        expect(
          autoIssuanceGateway.startRequests.single.salesOrderId,
          'order-100',
        );
        expect(autoIssuanceGateway.reevaluationRequests, isEmpty);
      },
    );

    test(
      'ProviderIssuanceResultReceived handler dispatches RecordIssuanceResultCommand',
      () async {
        final dispatcher = createGeneratedEinvoiceIntegrationEventDispatcher(
          container,
        );
        final resultEvt =
            ProviderIssuanceResultReceivedIntegrationEvent.success(
              id: 'evt-res-1',
              occurredOn: DateTime.utc(2026, 8, 29),
              tenantId: 'tenant-1',
              attemptId: 'att-1',
              correlationId: 'corr-1',
              idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
              payloadHash: 'hash-1',
              invoiceNumber: '001',
              invoiceSeries: '1C25TYY',
              issuedAt: DateTime.utc(2026, 8, 29),
            );

        await dispatcher.publish(resultEvt);

        expect(
          issuanceResultGateway.resultCalls,
          contains('success:tenant-1:att-1'),
        );
      },
    );
  });
}
