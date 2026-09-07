import '../electronic_invoice/queries/get_electronic_invoice_detail/electronic_invoice_detail_dto.dart';
import '../electronic_invoice/queries/get_invoice_documents/invoice_documents_dto.dart';
import '../electronic_invoice/shared/provider_observation_dto.dart';

abstract interface class IElectronicInvoiceReadGateway {
  Future<ElectronicInvoiceDetailDto> getDetail({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<InvoiceDocumentsDto> getDocuments({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<ProviderObservationDto?> getLatestObservation({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}
