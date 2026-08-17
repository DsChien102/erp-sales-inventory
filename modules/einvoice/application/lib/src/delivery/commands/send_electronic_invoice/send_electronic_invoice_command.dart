import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'send_electronic_invoice_result.dart';

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
    this.deliveryKind,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
  final String recipientEmail;
  final String idempotencyKey;
  final DeliveryKind? deliveryKind;
}
