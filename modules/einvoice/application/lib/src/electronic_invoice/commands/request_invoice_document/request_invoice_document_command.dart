import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'request_invoice_document_result.dart';

@RequiresPermission(EInvoicePermissions.downloadDocument)
@RequiresTenant()
final class RequestInvoiceDocumentCommand extends CommandBase<InvoiceDocumentRetrievalDto>
    implements ICommand<InvoiceDocumentRetrievalDto>, ITenantScopedCommand {
  RequestInvoiceDocumentCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.documentType,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final InvoiceDocumentType documentType;
  final String idempotencyKey;
}
