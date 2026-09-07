import '../enums/invoice_document_status.dart';

enum OfficialViewOperationDecision {
  reuse,
  rearmSameOperation,
  createNextGeneration,
}

/// Pure replay/refresh decisions for official-view technical operations.
abstract final class OfficialViewOperationPolicy {
  const OfficialViewOperationPolicy._();

  static OfficialViewOperationDecision decide({
    required InvoiceDocumentStatus status,
    required DateTime? expiresAt,
    required DateTime now,
  }) {
    switch (status) {
      case InvoiceDocumentStatus.pending:
        return OfficialViewOperationDecision.reuse;
      case InvoiceDocumentStatus.available:
        if (expiresAt != null && !expiresAt.isAfter(now)) {
          return OfficialViewOperationDecision.createNextGeneration;
        }
        return OfficialViewOperationDecision.reuse;
      case InvoiceDocumentStatus.checkRequired:
        return OfficialViewOperationDecision.rearmSameOperation;
      case InvoiceDocumentStatus.failed:
        return OfficialViewOperationDecision.createNextGeneration;
    }
  }
}
