import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'request_official_invoice_view_result.dart';

@RequiresPermission(EInvoicePermissions.view)
@RequiresTenant()
final class RequestOfficialInvoiceViewCommand extends CommandBase<OfficialInvoiceViewDto>
    implements ICommand<OfficialInvoiceViewDto>, ITenantScopedCommand {
  RequestOfficialInvoiceViewCommand({
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
