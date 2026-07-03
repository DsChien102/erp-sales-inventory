import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../partner_composition_root.dart';

/// Meetings-aligned command entry point: dedicated GetIt lifetime scope per command.
abstract final class CommandsExecutor {
  static Future<TResult> execute<TResult>(ICommand<TResult> command) {
    return PartnerCompositionRoot.beginLifetimeScope(
      (container) => container.get<CommandBus>().execute(command),
      scopeName: 'partner-command-${command.id}',
    );
  }
}
