/// Preview only — does not create IssuanceAttempt or ElectronicInvoice (DR-02).
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'request_invoice_preview_result.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class RequestInvoicePreviewCommand extends CommandBase<InvoicePreviewResultDto>
    implements ICommand<InvoicePreviewResultDto>, ITenantScopedCommand {
  RequestInvoicePreviewCommand({
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
