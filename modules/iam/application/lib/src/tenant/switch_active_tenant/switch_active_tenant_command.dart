import 'package:vet45_shared_application/application.dart';

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
