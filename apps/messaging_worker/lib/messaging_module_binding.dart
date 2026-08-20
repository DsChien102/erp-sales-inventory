import 'package:vet45_shared_application/application.dart';

/// Builds queue-specific recurring commands for a bound module.
abstract interface class IMessagingCommandFactory {
  ICommand<bool>? commandFor({
    required String queueType,
    required String tenantId,
    required int batchSize,
  });
}

/// One module registered in the messaging worker host.
final class MessagingModuleBinding {
  const MessagingModuleBinding({
    required this.moduleSchema,
    required this.mediator,
    required this.commands,
  });

  final String moduleSchema;
  final IModuleMediator mediator;
  final IMessagingCommandFactory commands;
}

Map<String, MessagingModuleBinding> indexMessagingModuleBindings(
  List<MessagingModuleBinding> modules,
) {
  return {for (final binding in modules) binding.moduleSchema: binding};
}
