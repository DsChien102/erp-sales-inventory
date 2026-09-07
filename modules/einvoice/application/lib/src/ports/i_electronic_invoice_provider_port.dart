import 'package:vet45_einvoice_domain/domain.dart';

import '../electronic_invoice/shared/electronic_invoice_provider_context_dto.dart';
import '../electronic_invoice/shared/invoice_document_provider_outcome.dart';
import '../electronic_invoice/shared/official_view_provider_outcome.dart';
import '../electronic_invoice/shared/provider_observation_outcome.dart';

abstract interface class IElectronicInvoiceProviderPort {
  Future<OfficialViewProviderOutcome> fetchOfficialView(
    ElectronicInvoiceProviderContextDto context,
  );

  Future<InvoiceDocumentProviderOutcome> downloadDocument(
    ElectronicInvoiceProviderContextDto context,
    InvoiceDocumentType documentType,
  );

  Future<ProviderObservationOutcome> observe(
    ElectronicInvoiceProviderContextDto context,
  );
}
