import 'package:own_integration_events/integration_events.dart';

import 'integration_event.dart';

final class OwnIntegrationEventHandler
    implements IIntegrationEventNotificationHandler<OwnIntegrationEvent> {
  OwnIntegrationEventHandler({required this.ownGateway});

  final OwnGateway ownGateway;

  @override
  Future<void> handle(OwnIntegrationEvent event) async {}
}

abstract interface class OwnGateway {}
