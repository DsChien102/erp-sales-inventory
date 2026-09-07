import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

/// Client-host guard preventing ERP from performing slice-4 MISA HTTP calls.
final class WorkerOnlyElectronicInvoiceProviderPort
    implements IElectronicInvoiceProviderPort {
  Never _reject() {
    throw StateError('MISA electronic-invoice HTTP operations are worker-only');
  }

  @override
  Future<OfficialViewProviderOutcome> fetchOfficialView(
    ElectronicInvoiceProviderContextDto context,
  ) async => _reject();

  @override
  Future<InvoiceDocumentProviderOutcome> downloadDocument(
    ElectronicInvoiceProviderContextDto context,
    InvoiceDocumentType documentType,
  ) async => _reject();

  @override
  Future<ProviderObservationOutcome> observe(
    ElectronicInvoiceProviderContextDto context,
  ) async => _reject();
}
