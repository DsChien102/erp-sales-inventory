import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'verify_provider_connection_result.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class VerifyProviderConnectionCommand extends CommandBase<ProviderConnectionCheckResultDto>
    implements ICommand<ProviderConnectionCheckResultDto>, ITenantScopedCommand {
  VerifyProviderConnectionCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.connectionId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String connectionId;
}
