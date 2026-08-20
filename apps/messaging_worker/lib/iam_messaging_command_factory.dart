import 'package:vet45_iam_infrastructure/infrastructure.dart' as iam;
import 'package:vet45_shared_application/application.dart';

import 'messaging_module_binding.dart';

/// IAM queue → Process* command mapping for the messaging worker.
final class IamMessagingCommandFactory implements IMessagingCommandFactory {
  const IamMessagingCommandFactory();

  @override
  ICommand<bool>? commandFor({
    required String queueType,
    required String tenantId,
    required int batchSize,
  }) {
    switch (queueType) {
      case 'outbox':
        return iam.ProcessOutboxCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
      case 'inbox':
        return iam.ProcessInboxCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
      case 'internal_commands':
        return iam.ProcessInternalCommandsCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
    }
    return null;
  }
}
