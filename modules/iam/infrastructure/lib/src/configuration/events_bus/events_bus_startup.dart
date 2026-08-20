import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/iam_integration_event_registry.g.dart';
import '../processing/inbox/i_iam_inbox_client.dart';

/// Subscribes IAM self-consume handlers on the shared [IEventsBus].
abstract final class EventsBusStartup {
  static void initialize(GetIt container, ILogger logger) {
    registerGeneratedIamIntegrationEventSubscriptions(
      eventBus: container.get<IEventsBus>(),
      inboxClient: container.get<IIamInboxClient>(),
      logger: logger,
    );
  }
}
