import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class DownloadInvoiceDocumentCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  DownloadInvoiceDocumentCommand({
    String? id,
    required this.tenantId,
    required this.operationId,
    required this.electronicInvoiceId,
    required this.documentType,
    required this.operationGeneration,
    required this.attemptOrdinal,
    required this.correlationId,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.download_invoice_document';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String operationId;
  final String electronicInvoiceId;
  final InvoiceDocumentType documentType;
  final int operationGeneration;
  final int attemptOrdinal;
  final String correlationId;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId({
    'tenant_id': tenantId,
    'operation_id': operationId,
    'electronic_invoice_id': electronicInvoiceId,
    'document_type': _documentTypeToWire(documentType),
    'operation_generation': operationGeneration,
    'attempt_ordinal': attemptOrdinal,
    'correlation_id': correlationId,
  });

  factory DownloadInvoiceDocumentCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final normalized = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return DownloadInvoiceDocumentCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      operationId: normalized['operation_id'] as String,
      electronicInvoiceId: normalized['electronic_invoice_id'] as String,
      documentType: _documentTypeFromWire(normalized['document_type'] as String),
      operationGeneration:
          (normalized['operation_generation'] as num?)?.toInt() ?? 1,
      attemptOrdinal: (normalized['attempt_ordinal'] as num?)?.toInt() ?? 1,
      correlationId: normalized['correlation_id'] as String,
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(normalized),
    );
  }

  static String _documentTypeToWire(InvoiceDocumentType type) {
    return switch (type) {
      InvoiceDocumentType.pdf => 'PDF',
      InvoiceDocumentType.xml => 'XML',
    };
  }

  static InvoiceDocumentType _documentTypeFromWire(String raw) {
    switch (raw.toUpperCase()) {
      case 'PDF':
        return InvoiceDocumentType.pdf;
      case 'XML':
        return InvoiceDocumentType.xml;
      default:
        throw FormatException('Unknown document type: $raw');
    }
  }
}
