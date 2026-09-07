import 'package:vet45_shared_application/application.dart';

final class FetchOfficialInvoiceViewCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  FetchOfficialInvoiceViewCommand({
    String? id,
    required this.tenantId,
    required this.operationId,
    required this.electronicInvoiceId,
    required this.attemptOrdinal,
    required this.correlationId,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.fetch_official_view';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String operationId;
  final String electronicInvoiceId;
  final int attemptOrdinal;
  final String correlationId;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId({
    'tenant_id': tenantId,
    'operation_id': operationId,
    'electronic_invoice_id': electronicInvoiceId,
    'attempt_ordinal': attemptOrdinal,
    'correlation_id': correlationId,
  });

  factory FetchOfficialInvoiceViewCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final normalized = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return FetchOfficialInvoiceViewCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      operationId: normalized['operation_id'] as String,
      electronicInvoiceId: normalized['electronic_invoice_id'] as String,
      attemptOrdinal: (normalized['attempt_ordinal'] as num).toInt(),
      correlationId: normalized['correlation_id'] as String,
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(normalized),
    );
  }
}
