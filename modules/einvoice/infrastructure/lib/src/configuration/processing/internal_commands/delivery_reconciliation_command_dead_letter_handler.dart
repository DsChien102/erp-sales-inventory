import 'package:vet45_einvoice_application/application.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

/// Dead-letters exhausted `einvoice.reconcile_invoice_delivery` commands.
///
/// When the case is still PENDING (`loadContext` non-null), records an
/// unsupported check that yields UNRESOLVED + attention. Never calls
/// observation / sendEmail.
final class DeliveryReconciliationCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  const DeliveryReconciliationCommandDeadLetterHandler({
    required IDeliveryReconciliationGateway reconciliationGateway,
  }) : _reconciliationGateway = reconciliationGateway;

  static const safeCode = 'DELIVERY_RECONCILIATION_WORKER_EXHAUSTED';

  final IDeliveryReconciliationGateway _reconciliationGateway;

  @override
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  }) async {
    final reconciliationCaseId = command.payload['reconciliation_case_id']
        ?.toString();
    if (reconciliationCaseId == null || reconciliationCaseId.isEmpty) {
      return;
    }

    final checkSequence = switch (command.payload['check_sequence']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 1,
      _ => 1,
    };

    final context = await _reconciliationGateway.loadContext(
      tenantId: tenantId,
      reconciliationCaseId: reconciliationCaseId,
      checkSequence: checkSequence,
    );
    if (context == null) {
      // Not PENDING (or stale sequence) — nothing to amend.
      return;
    }

    await _reconciliationGateway.recordCheck(
      DeliveryReconciliationCheckRecord(
        tenantId: tenantId,
        reconciliationCaseId: reconciliationCaseId,
        expectedCaseVersion: context.caseVersion,
        checkSequence: checkSequence,
        kind: DeliveryObservationKind.unsupported,
        safeCode: safeCode,
      ),
    );
  }
}
