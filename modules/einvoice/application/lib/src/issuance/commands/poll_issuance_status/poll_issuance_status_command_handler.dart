import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_einvoice_command_dispatcher.dart';
import '../../../ports/i_issuance_reconciliation_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import '../../../ports/me_invoice_issuance_status_outcome.dart';
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
  }) : _reconciliationGateway = reconciliationGateway,
       _providerPort = providerPort,
       _commandDispatcher = commandDispatcher;

  final IIssuanceReconciliationGateway _reconciliationGateway;
  final IMeInvoiceProviderPort _providerPort;
  final IEinvoiceCommandDispatcher _commandDispatcher;

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

    final outcome = await _providerPort.getStatus(
      tenantId: command.tenantId,
      idempotencyKey: context.idempotencyKey,
      payloadHash: context.payloadHash,
      providerReference: context.providerReference,
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
      case MeInvoiceIssuanceStatusUndetermined():
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
