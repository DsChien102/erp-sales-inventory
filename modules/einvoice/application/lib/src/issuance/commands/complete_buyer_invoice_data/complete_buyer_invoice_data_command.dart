import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'complete_buyer_invoice_data_result.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class CompleteBuyerInvoiceDataCommand extends CommandBase<BuyerCompletionResultDto>
    implements ICommand<BuyerCompletionResultDto>, ITenantScopedCommand {
  CompleteBuyerInvoiceDataCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.expectedOrderVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final int expectedOrderVersion;
}
