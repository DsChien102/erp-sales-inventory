import 'package:vet45_shared_application/application.dart';

/// Durable worker command — capability-aware delivery reconciliation check.
///
/// Contains only identity fields; provider capability and delivery context
/// load from the database.
final class ReconcileInvoiceDeliveryCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  ReconcileInvoiceDeliveryCommand({
    String? id,
    required this.tenantId,
    required this.reconciliationCaseId,
    required this.checkSequence,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.reconcile_invoice_delivery';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String reconciliationCaseId;
  final int checkSequence;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId(<String, dynamic>{
    'tenant_id': tenantId,
    'reconciliation_case_id': reconciliationCaseId,
    'check_sequence': checkSequence,
  });

  factory ReconcileInvoiceDeliveryCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final n = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return ReconcileInvoiceDeliveryCommand(
      id: id,
      tenantId: n['tenant_id'] as String? ?? n['tenantId'] as String,
      reconciliationCaseId:
          n['reconciliation_case_id'] as String? ?? n['reconciliationCaseId'] as String,
      checkSequence: n['check_sequence'] as int? ?? n['checkSequence'] as int? ?? 1,
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(n),
    );
  }
}
