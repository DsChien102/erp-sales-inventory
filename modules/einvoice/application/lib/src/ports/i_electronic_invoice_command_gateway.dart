import 'package:vet45_einvoice_domain/domain.dart';

import '../electronic_invoice/commands/request_official_invoice_view/request_official_invoice_view_result.dart';
import '../electronic_invoice/commands/request_invoice_document/request_invoice_document_result.dart';
import '../electronic_invoice/shared/invoice_document_result_record.dart';
import '../electronic_invoice/shared/official_view_operation_context_dto.dart';
import '../electronic_invoice/shared/invoice_document_operation_context_dto.dart';
import '../electronic_invoice/shared/provider_observation_operation_context_dto.dart';
import '../electronic_invoice/shared/official_view_result_record.dart';
import '../electronic_invoice/shared/provider_observation_dto.dart';
import '../electronic_invoice/shared/provider_observation_record.dart';

abstract interface class IElectronicInvoiceCommandGateway {
  Future<OfficialInvoiceViewDto> requestOfficialView({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });

  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required InvoiceDocumentType documentType,
    required String idempotencyKey,
  });

  Future<OfficialViewOperationContextDto?> loadOfficialViewContext({
    required String tenantId,
    required String operationId,
  });

  Future<InvoiceDocumentOperationContextDto?> loadDocumentContext({
    required String tenantId,
    required String operationId,
  });

  Future<ProviderObservationOperationContextDto?> loadObservationContext({
    required String tenantId,
    required String commandId,
  });

  Future<void> recordOfficialViewResult(OfficialViewResultRecord record);

  Future<void> recordDocumentResult(InvoiceDocumentResultRecord record);

  Future<ProviderObservationDto> recordProviderObservation(
    ProviderObservationRecord record,
  );
}
