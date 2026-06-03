import 'package:other_integration_events/integration_events.dart';

import 'integration_event.dart';

final class OtherIntegrationEventHandler
    implements IIntegrationEventNotificationHandler<OtherIntegrationEvent> {
  const OtherIntegrationEventHandler();

  @override
  Future<void> handle(OtherIntegrationEvent event) async {}
}
