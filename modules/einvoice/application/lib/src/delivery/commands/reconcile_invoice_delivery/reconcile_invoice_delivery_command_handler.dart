import 'package:vet45_shared_application/application.dart';

import '../../../electronic_invoice/shared/provider_call_correlation_id.dart';
import '../../../electronic_invoice/shared/provider_interaction_direction.dart';
import '../../../electronic_invoice/shared/provider_interaction_outcome.dart';
import '../../../electronic_invoice/shared/provider_interaction_status.dart';
import '../../../ports/i_delivery_reconciliation_gateway.dart';
import '../../../ports/i_invoice_delivery_observation_provider_port.dart';
import '../../../ports/i_provider_interaction_gateway.dart';
import '../../shared/delivery_observation_context_dto.dart';
import '../../shared/delivery_observation_kind.dart';
import '../../shared/delivery_observation_outcome.dart';
import '../../shared/delivery_reconciliation_check_record.dart';
import 'reconcile_invoice_delivery_command.dart';

@CommandHandlerFor(ReconcileInvoiceDeliveryCommand)
final class ReconcileInvoiceDeliveryCommandHandler
    implements ICommandHandler<ReconcileInvoiceDeliveryCommand, void> {
  ReconcileInvoiceDeliveryCommandHandler({
    required IDeliveryReconciliationGateway reconciliationGateway,
    required IInvoiceDeliveryObservationProviderPort observationPort,
    required IProviderInteractionGateway interactionGateway,
  }) : _reconciliationGateway = reconciliationGateway,
       _observationPort = observationPort,
       _interactionGateway = interactionGateway;

  final IDeliveryReconciliationGateway _reconciliationGateway;
  final IInvoiceDeliveryObservationProviderPort _observationPort;
  final IProviderInteractionGateway _interactionGateway;

  @override
  Future<void> handle(ReconcileInvoiceDeliveryCommand command) async {
    final context = await _reconciliationGateway.loadContext(
      tenantId: command.tenantId,
      reconciliationCaseId: command.reconciliationCaseId,
      checkSequence: command.checkSequence,
    );
    if (context == null) {
      return;
    }

    if (!context.supportsDeliveryResultObservation) {
      await _reconciliationGateway.recordCheck(
        DeliveryReconciliationCheckRecord(
          tenantId: command.tenantId,
          reconciliationCaseId: command.reconciliationCaseId,
          expectedCaseVersion: context.caseVersion,
          checkSequence: command.checkSequence,
          kind: DeliveryObservationKind.unsupported,
          safeCode: 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
        ),
      );
      return;
    }

    final requestReference = ProviderCallCorrelationId.forWorkerAttempt(
      commandId: command.id,
      workerAttemptNumber: command.workerAttemptNumber,
    );

    final interaction = await _interactionGateway.start(
      tenantId: command.tenantId,
      providerConnectionId: context.providerConnectionId,
      direction: ProviderInteractionDirection.outbound,
      operationType: ReconcileInvoiceDeliveryCommand.type,
      targetType: 'DELIVERY_ATTEMPT',
      targetId: context.attemptId,
      correlationId: requestReference,
      requestReference: requestReference,
    );

    if (interaction.status == ProviderInteractionStatus.completed) {
      return;
    }

    final outcome = await _observationPort.observe(
      DeliveryObservationContextDto(
        tenantId: context.tenantId,
        reconciliationCaseId: context.reconciliationCaseId,
        deliveryId: context.deliveryId,
        attemptId: context.attemptId,
        providerConnectionId: context.providerConnectionId,
        providerDeliveryReference: context.providerDeliveryReference,
      ),
    );

    final (kind, providerReference, safeCode, interactionOutcome) = switch (outcome) {
      DeliveryObservedSucceeded(:final providerReference) => (
        DeliveryObservationKind.succeeded,
        providerReference,
        null,
        ProviderInteractionOutcome.succeeded,
      ),
      DeliveryObservedDefiniteFailure(:final safeCode) => (
        DeliveryObservationKind.definiteFailure,
        null,
        safeCode,
        ProviderInteractionOutcome.definiteFailure,
      ),
      DeliveryObservationUndetermined(:final safeCode) => (
        DeliveryObservationKind.undetermined,
        null,
        safeCode,
        ProviderInteractionOutcome.unavailable,
      ),
      DeliveryObservationUnsupported() => (
        DeliveryObservationKind.unsupported,
        null,
        'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
        ProviderInteractionOutcome.definiteFailure,
      ),
    };

    final finalized = await _interactionGateway.finalize(
      tenantId: command.tenantId,
      interactionReference: interaction.interactionReference,
      expectedVersion: interaction.version,
      outcome: interactionOutcome,
      providerReference: providerReference,
      safeErrorCode: safeCode,
    );

    await _reconciliationGateway.recordCheck(
      DeliveryReconciliationCheckRecord(
        tenantId: command.tenantId,
        reconciliationCaseId: command.reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence: command.checkSequence,
        interactionReference: finalized.interactionReference,
        kind: kind,
        providerReference: providerReference,
        safeCode: safeCode,
      ),
    );
  }
}
