import 'package:vet45_sales_infrastructure/infrastructure.dart' as sales;
import 'package:vet45_shared_application/application.dart';

import 'messaging_module_binding.dart';

/// Sales queue → Process* command mapping for the messaging worker.
///
/// Only `outbox` is supported today; inbox/internal_commands return null until
/// Sales provides those processors.
final class SalesMessagingCommandFactory implements IMessagingCommandFactory {
  const SalesMessagingCommandFactory();

  @override
  ICommand<bool>? commandFor({
    required String queueType,
    required String tenantId,
    required int batchSize,
  }) {
    switch (queueType) {
      case 'outbox':
        return sales.ProcessOutboxCommand(
          tenantId: tenantId,
          batchSize: batchSize,
        );
      case 'inbox':
      case 'internal_commands':
        return null;
    }
    return null;
  }
}
