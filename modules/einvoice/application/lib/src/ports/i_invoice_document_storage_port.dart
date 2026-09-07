import 'package:vet45_einvoice_domain/domain.dart';

import '../electronic_invoice/shared/stored_invoice_document_dto.dart';

abstract interface class IInvoiceDocumentStoragePort {
  Future<StoredInvoiceDocumentDto> store({
    required String tenantId,
    required String electronicInvoiceId,
    required InvoiceDocumentType documentType,
    required int documentVersion,
    required List<int> bytes,
  });
}
