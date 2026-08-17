import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import '../../commands/request_invoice_preview/request_invoice_preview_result.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class GetInvoicePreviewQuery extends QueryBase<InvoicePreviewResultDto>
    implements IQuery<InvoicePreviewResultDto>, ITenantScopedCommand {
  GetInvoicePreviewQuery({
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
