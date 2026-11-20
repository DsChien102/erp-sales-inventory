import 'models.dart';

/// Contract for exporting or downloading electronic invoice documents.
abstract interface class IInvoiceDocumentExporter {
  Future<bool> exportDocument({
    required String filename,
    required InvoiceDocumentType type,
    String? url,
    List<int>? bytes,
    String? expectedSha256,
  });
}
