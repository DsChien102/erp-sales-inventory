import 'package:vet45_shared_application/application.dart';

/// Interim switch — prefer [SwitchTenantContextCommand] (EP-05/US-02).
@Deprecated('Use SwitchTenantContextCommand')
@RequiresTenant()
final class SwitchActiveTenantCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  SwitchActiveTenantCommand({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
