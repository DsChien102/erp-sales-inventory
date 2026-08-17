import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import '../../../shared/order_invoice_projection_dto.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class GetOrderInvoiceProjectionQuery extends QueryBase<OrderInvoiceProjectionDto>
    implements IQuery<OrderInvoiceProjectionDto>, ITenantScopedCommand {
  GetOrderInvoiceProjectionQuery({
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
