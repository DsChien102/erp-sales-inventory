import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/einvoice_integration_event_registry.g.dart';
import '../processing/inbox/i_einvoice_inbox_client.dart';

/// Subscribes E-invoice self-consume handlers on the shared [IEventsBus].
abstract final class EventsBusStartup {
  static void initialize(GetIt container, ILogger logger) {
    registerGeneratedEinvoiceIntegrationEventSubscriptions(
      eventBus: container.get<IEventsBus>(),
      inboxClient: container.get<IEinvoiceInboxClient>(),
      logger: logger,
    );
  }
}
