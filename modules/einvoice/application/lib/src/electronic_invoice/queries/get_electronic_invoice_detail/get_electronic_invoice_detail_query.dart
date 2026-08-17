import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'electronic_invoice_detail_dto.dart';

@RequiresPermission(EInvoicePermissions.view)
@RequiresTenant()
final class GetElectronicInvoiceDetailQuery extends QueryBase<ElectronicInvoiceDetailDto>
    implements IQuery<ElectronicInvoiceDetailDto>, ITenantScopedCommand {
  GetElectronicInvoiceDetailQuery({
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
