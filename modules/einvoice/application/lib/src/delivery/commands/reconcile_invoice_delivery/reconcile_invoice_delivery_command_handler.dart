import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_delivery_reconciliation_gateway.dart';
import '../../../ports/i_invoice_delivery_observation_provider_port.dart';
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
  }) : _reconciliationGateway = reconciliationGateway,
       _observationPort = observationPort;

  final IDeliveryReconciliationGateway _reconciliationGateway;
  final IInvoiceDeliveryObservationProviderPort _observationPort;

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

    final outcome = await _observationPort.observe(
      DeliveryObservationContextDto(
        tenantId: context.tenantId,
        reconciliationCaseId: context.reconciliationCaseId,
        deliveryId: context.deliveryId,
        providerConnectionId: context.providerConnectionId,
        providerDeliveryReference: context.providerDeliveryReference,
      ),
    );

    final (kind, providerReference, safeCode) = switch (outcome) {
      DeliveryObservedSucceeded(:final providerReference) => (
        DeliveryObservationKind.succeeded,
        providerReference,
        null,
      ),
      DeliveryObservedDefiniteFailure(:final safeCode) => (
        DeliveryObservationKind.definiteFailure,
        null,
        safeCode,
      ),
      DeliveryObservationUndetermined(:final safeCode) => (
        DeliveryObservationKind.undetermined,
        null,
        safeCode,
      ),
      DeliveryObservationUnsupported() => (
        DeliveryObservationKind.unsupported,
        null,
        'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      ),
    };

    await _reconciliationGateway.recordCheck(
      DeliveryReconciliationCheckRecord(
        tenantId: command.tenantId,
        reconciliationCaseId: command.reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence: command.checkSequence,
        kind: kind,
        providerReference: providerReference,
        safeCode: safeCode,
      ),
    );
  }
}
