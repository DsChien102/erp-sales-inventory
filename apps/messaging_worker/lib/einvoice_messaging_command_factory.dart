import 'package:vet45_einvoice_infrastructure/infrastructure.dart' as einvoice;
import 'package:vet45_shared_application/application.dart';

import 'messaging_module_binding.dart';

/// E-invoice queue → Process* command mapping for the messaging worker.
final class EinvoiceMessagingCommandFactory implements IMessagingCommandFactory {
  const EinvoiceMessagingCommandFactory();

  @override
  ICommand<bool>? commandFor({
    required String queueType,
    required String tenantId,
    required int batchSize,
  }) {
    switch (queueType) {
      case 'outbox':
        return einvoice.ProcessOutboxCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
      case 'inbox':
        return einvoice.ProcessInboxCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
      case 'internal_commands':
        return einvoice.ProcessInternalCommandsCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
    }
    return null;
  }
}
