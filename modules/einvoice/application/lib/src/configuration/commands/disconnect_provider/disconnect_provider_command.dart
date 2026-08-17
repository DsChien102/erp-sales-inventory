import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../connect_provider/connect_provider_result.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class DisconnectProviderCommand extends CommandBase<ProviderConnectionResultDto>
    implements ICommand<ProviderConnectionResultDto>, ITenantScopedCommand {
  DisconnectProviderCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.connectionId,
    required this.confirm,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String connectionId;
  final bool confirm;
}
