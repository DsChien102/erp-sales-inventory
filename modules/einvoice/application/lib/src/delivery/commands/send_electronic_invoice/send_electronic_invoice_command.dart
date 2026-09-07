import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'send_electronic_invoice_result.dart';

/// Manual send/resend intent.
///
/// Initial versus resend is server-derived from the invoice's delivery
/// history; the client never chooses it.
@RequiresPermission(EInvoicePermissions.send)
@RequiresTenant()
final class SendElectronicInvoiceCommand extends CommandBase<SendInvoiceResultDto>
    implements ICommand<SendInvoiceResultDto>, ITenantScopedCommand {
  SendElectronicInvoiceCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
    required this.recipientEmail,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final String recipientEmail;
  final String idempotencyKey;
}
