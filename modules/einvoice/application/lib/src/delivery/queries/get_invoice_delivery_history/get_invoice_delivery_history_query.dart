import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'invoice_delivery_history_dto.dart';

@RequiresPermission(EInvoicePermissions.send)
@RequiresTenant()
final class GetInvoiceDeliveryHistoryQuery extends QueryBase<InvoiceDeliveryHistoryDto>
    implements IQuery<InvoiceDeliveryHistoryDto>, ITenantScopedCommand {
  GetInvoiceDeliveryHistoryQuery({
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
