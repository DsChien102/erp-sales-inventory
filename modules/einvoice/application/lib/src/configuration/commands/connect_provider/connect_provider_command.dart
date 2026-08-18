import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'connect_provider_result.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class ConnectProviderCommand extends CommandBase<ProviderConnectionResultDto>
    implements ICommand<ProviderConnectionResultDto>, ITenantScopedCommand {
  ConnectProviderCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.username,
    required this.password,
    this.expectedConnectionVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String username;
  final String password;
  final int? expectedConnectionVersion;
}
