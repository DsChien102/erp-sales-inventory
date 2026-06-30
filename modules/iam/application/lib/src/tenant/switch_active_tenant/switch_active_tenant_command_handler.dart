import 'package:vet45_shared_application/application.dart';

import '../../ports/i_iam_session_port.dart';
import 'switch_active_tenant_command.dart';

@CommandHandlerFor(SwitchActiveTenantCommand)
final class SwitchActiveTenantCommandHandler
    implements ICommandHandler<SwitchActiveTenantCommand, void> {
  SwitchActiveTenantCommandHandler({required IIamSessionPort sessionPort})
    : _sessionPort = sessionPort;

  final IIamSessionPort _sessionPort;

  @override
  Future<void> handle(SwitchActiveTenantCommand command) {
    return _sessionPort.establishAfterSignIn(tenantId: command.tenantId);
  }
}
