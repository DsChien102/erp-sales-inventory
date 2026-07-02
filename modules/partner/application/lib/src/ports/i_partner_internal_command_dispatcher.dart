import 'package:vet45_shared_application/application.dart';

/// Executes partner internal commands through the module command pipeline.
///
/// Consumer integration-event handlers depend on this port so event → command
/// mapping stays in the application layer while execution goes through the
/// `CommandBus` + `DefaultCommandPipeline` (never calling handlers directly).
abstract interface class IPartnerInternalCommandDispatcher {
  Future<void> dispatch(InternalCommandBase<void> command);
}
