import 'package:vet45_shared_application/application.dart';

import 'start_auto_delivery_result.dart';

/// Internal — trigger on einvoice.electronic_invoice.registered.
@RequiresTenant()
final class StartAutoDeliveryCommand extends CommandBase<AutoDeliveryResultDto>
    implements ICommand<AutoDeliveryResultDto>, ITenantScopedCommand {
  StartAutoDeliveryCommand({
    String? id,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.triggerId,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String electronicInvoiceId;
  final String triggerId;
  final String idempotencyKey;
}
