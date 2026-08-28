import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'issue_invoice_result.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class IssueInvoiceCommand extends CommandBase<IssueInvoiceResultDto>
    implements ICommand<IssueInvoiceResultDto>, ITenantScopedCommand {
  IssueInvoiceCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.sourceVersion,
    required this.idempotencyKey,
    this.acknowledgeWarnings,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final String sourceVersion;
  final String idempotencyKey;
  final bool? acknowledgeWarnings;
}
