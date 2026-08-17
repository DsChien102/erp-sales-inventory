import 'package:vet45_shared_application/application.dart';

import 'sync_provider_capabilities_result.dart';

/// Internal — worker post-auth capability sync.
@RequiresTenant()
final class SyncProviderCapabilitiesCommand extends CommandBase<ProviderCapabilitiesDto>
    implements ICommand<ProviderCapabilitiesDto>, ITenantScopedCommand {
  SyncProviderCapabilitiesCommand({
    String? id,
    required this.tenantId,
    required this.connectionId,
  }) : super(id);

  @override
  final String tenantId;
  final String connectionId;
}
