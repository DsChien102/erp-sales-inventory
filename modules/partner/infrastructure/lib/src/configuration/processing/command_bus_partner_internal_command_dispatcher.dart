import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Executes partner internal commands through the module `CommandBus` pipeline.
///
/// Backs [IPartnerInternalCommandDispatcher] so application consumer handlers
/// never touch a command handler directly — every write goes through the
/// registered internal-command pipeline (validate → log → handler).
final class CommandBusPartnerInternalCommandDispatcher
    implements IPartnerInternalCommandDispatcher {
  CommandBusPartnerInternalCommandDispatcher(this._commandBus);

  final CommandBus _commandBus;

  @override
  Future<void> dispatch(InternalCommandBase<void> command) {
    return _commandBus.execute<void>(command);
  }
}
