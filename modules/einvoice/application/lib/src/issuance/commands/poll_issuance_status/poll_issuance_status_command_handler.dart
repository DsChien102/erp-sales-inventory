import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_einvoice_command_dispatcher.dart';
import '../../../ports/i_issuance_reconciliation_gateway.dart';
import '../../../ports/i_issuance_result_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import '../../../ports/me_invoice_issuance_status_outcome.dart';
import '../../shared/issuance_provider_status_lookup.dart';
import '../../shared/issuance_result_evidence_dto.dart';
import '../../shared/misa_publish_provider_codes.dart';
import '../../shared/publish_provider_retry_policy.dart';
import '../../shared/publish_undetermined_reason_codes.dart';
import '../record_issuance_result/record_issuance_result_command.dart';
import 'poll_issuance_status_command.dart';

/// Handler for [PollIssuanceStatusCommand].
///
/// Claims a reconciliation case, queries MISA status, and:
/// - On success/definite-failure: dispatches [RecordIssuanceResultCommand] with typed evidence
/// - On pending/undetermined: either schedules next check via [IIssuanceReconciliationGateway.recordPendingCheck]
///   or marks unresolved via [IIssuanceReconciliationGateway.markUnresolved] after 5 checks.
///
/// Invariant: NEVER calls or contains `publish`.
@CommandHandlerFor(PollIssuanceStatusCommand)
final class PollIssuanceStatusCommandHandler
    implements ICommandHandler<PollIssuanceStatusCommand, void> {
  PollIssuanceStatusCommandHandler({
    required IIssuanceReconciliationGateway reconciliationGateway,
    required IMeInvoiceProviderPort providerPort,
    required IEinvoiceCommandDispatcher commandDispatcher,
    required IIssuanceResultGateway resultGateway,
  }) : _reconciliationGateway = reconciliationGateway,
       _providerPort = providerPort,
       _commandDispatcher = commandDispatcher,
       _resultGateway = resultGateway;

  final IIssuanceReconciliationGateway _reconciliationGateway;
  final IMeInvoiceProviderPort _providerPort;
  final IEinvoiceCommandDispatcher _commandDispatcher;
  final IIssuanceResultGateway _resultGateway;

  @override
  Future<void> handle(PollIssuanceStatusCommand command) async {
    final context = await _reconciliationGateway.claimReconciliationCase(
      tenantId: command.tenantId,
      caseId: command.caseId,
      workerId: command.correlationId,
    );

    if (context == null) {
      return;
    }

    final reconcileDuplicate =
        context.reconciliationReasonCode ==
        PublishUndeterminedReasonCodes.invoiceDuplicatedReconcileFirst;
    final providerReference = context.providerReference?.trim();
    if (!reconcileDuplicate && (providerReference == null || providerReference.isEmpty)) {
      await _reconciliationGateway.markUnresolved(
        tenantId: command.tenantId,
        caseId: command.caseId,
        claimToken: context.claimToken,
        reasonCode: 'MISSING_PROVIDER_TRANSACTION_ID',
      );
      return;
    }

    final statusLookup = reconcileDuplicate
        ? IssuanceProviderStatusLookup.refId
        : IssuanceProviderStatusLookup.providerTransactionId;
    final statusLookupKey = statusLookup == IssuanceProviderStatusLookup.refId
        ? context.idempotencyKey
        : providerReference!;

    final outcome = await _providerPort.getStatus(
      tenantId: command.tenantId,
      statusLookupKey: statusLookupKey,
      invoiceSeries: context.invoiceSeries,
      idempotencyKey: context.idempotencyKey,
      payloadHash: context.payloadHash,
      statusLookup: statusLookup,
    );

    switch (outcome) {
      case MeInvoiceIssuanceStatusSuccess(:final evidence):
        await _commandDispatcher.execute(
          RecordIssuanceResultCommand(
            tenantId: command.tenantId,
            attemptId: command.attemptId,
            correlationId: command.correlationId,
            evidence: evidence,
          ),
        );
        await _reconciliationGateway.resolveReconciliationCase(
          tenantId: command.tenantId,
          caseId: command.caseId,
          outcome: 'SUCCESS',
          evidence: {
            'provider_reference': evidence.providerReference,
            'invoice_number': evidence.invoiceNumber,
            'invoice_series': evidence.invoiceSeries,
            'issued_at': evidence.issuedAt.toUtc().toIso8601String(),
          },
        );
      case MeInvoiceIssuanceStatusDefiniteFailure(:final evidence):
        await _commandDispatcher.execute(
          RecordIssuanceResultCommand(
            tenantId: command.tenantId,
            attemptId: command.attemptId,
            correlationId: command.correlationId,
            evidence: evidence,
          ),
        );
        await _reconciliationGateway.resolveReconciliationCase(
          tenantId: command.tenantId,
          caseId: command.caseId,
          outcome: 'FAILURE',
          evidence: {
            'provider_code': evidence.providerCode,
            'provider_message': evidence.providerMessage,
          },
        );
      case MeInvoiceIssuanceStatusPending():
        final completedChecks = context.checkSequence;
        if (ReconciliationSchedule.shouldMarkUnresolved(completedChecks)) {
          await _reconciliationGateway.markUnresolved(
            tenantId: command.tenantId,
            caseId: command.caseId,
            claimToken: context.claimToken,
            reasonCode: 'POLL_MAX_CHECKS_EXCEEDED',
          );
        } else {
          final nextSequence = completedChecks + 1;
          final delay = ReconciliationSchedule.delayBeforeCheck(nextSequence);
          await _reconciliationGateway.recordPendingCheck(
            tenantId: command.tenantId,
            caseId: command.caseId,
            claimToken: context.claimToken,
            nextDelay: delay,
            checkSequence: nextSequence,
          );
        }
      case MeInvoiceIssuanceStatusUndetermined(:final reasonCode):
        if (reconcileDuplicate &&
            reasonCode == 'STATUS_EMPTY_DATA' &&
            ReconciliationSchedule.shouldMarkUnresolved(context.checkSequence)) {
          await _resultGateway.recordRetryableProviderRejection(
            tenantId: command.tenantId,
            attemptId: command.attemptId,
            sourceCommandId: command.id,
            evidence: IssuanceResultEvidenceDto.retryableProviderRejection(
              idempotencyKey: context.idempotencyKey,
              payloadHash: context.payloadHash,
              providerCode: MisaPublishProviderCodes.invoiceDuplicated,
              providerMessage: 'definitive-not-found after reconcile-first polls',
            ),
            retryAfter: PublishProviderRetryPolicy.minInvoiceNumberNotContinuousBackoff,
          );
          await _reconciliationGateway.resolveReconciliationCase(
            tenantId: command.tenantId,
            caseId: command.caseId,
            outcome: 'PUBLISH_RETRY_SCHEDULED',
            evidence: {'provider_code': MisaPublishProviderCodes.invoiceDuplicated},
          );
          return;
        }

        final completedChecks = context.checkSequence;
        if (ReconciliationSchedule.shouldMarkUnresolved(completedChecks)) {
          await _reconciliationGateway.markUnresolved(
            tenantId: command.tenantId,
            caseId: command.caseId,
            claimToken: context.claimToken,
            reasonCode: 'POLL_MAX_CHECKS_EXCEEDED',
          );
        } else {
          final nextSequence = completedChecks + 1;
          final delay = ReconciliationSchedule.delayBeforeCheck(nextSequence);
          await _reconciliationGateway.recordPendingCheck(
            tenantId: command.tenantId,
            caseId: command.caseId,
            claimToken: context.claimToken,
            nextDelay: delay,
            checkSequence: nextSequence,
          );
        }
    }
  }
}
