import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'send_invoice_sheet_context_dto.dart';

@RequiresPermission(EInvoicePermissions.send)
@RequiresTenant()
final class GetSendInvoiceSheetContextQuery extends QueryBase<SendInvoiceSheetContextDto>
    implements IQuery<SendInvoiceSheetContextDto>, ITenantScopedCommand {
  GetSendInvoiceSheetContextQuery({
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
