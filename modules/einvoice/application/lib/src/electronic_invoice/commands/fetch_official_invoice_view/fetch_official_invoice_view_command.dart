import 'package:vet45_shared_application/application.dart';

final class FetchOfficialInvoiceViewCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  FetchOfficialInvoiceViewCommand({
    String? id,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.requestId,
    required this.correlationId,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.fetch_official_view';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String electronicInvoiceId;
  final String requestId;
  final String correlationId;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId({
    'tenant_id': tenantId,
    'electronic_invoice_id': electronicInvoiceId,
    'request_id': requestId,
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
      electronicInvoiceId: normalized['electronic_invoice_id'] as String,
      requestId: normalized['request_id'] as String,
      correlationId: normalized['correlation_id'] as String,
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(normalized),
    );
  }
}
