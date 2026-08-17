import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'invoice_documents_dto.dart';

@RequiresPermission(EInvoicePermissions.downloadDocument)
@RequiresTenant()
final class GetInvoiceDocumentsQuery extends QueryBase<InvoiceDocumentsDto>
    implements IQuery<InvoiceDocumentsDto>, ITenantScopedCommand {
  GetInvoiceDocumentsQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
}
