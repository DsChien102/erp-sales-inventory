// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import '../partner_integration_event_dispatcher.dart';

PartnerIntegrationEventDispatcher createGeneratedPartnerIntegrationEventDispatcher(GetIt container) {
  final dispatcher = PartnerIntegrationEventDispatcher();
  dispatcher.register<AccountingPayableCreatedIntegrationEvent>(
    AccountingPayableCreatedIntegrationEventHandler(
      internalCommandDispatcher: container.get<IPartnerInternalCommandDispatcher>(),
    ),
  );
  dispatcher.register<AccountingReceivableCreatedIntegrationEvent>(
    AccountingReceivableCreatedIntegrationEventHandler(
      internalCommandDispatcher: container.get<IPartnerInternalCommandDispatcher>(),
    ),
  );
  dispatcher.register<InventoryInboundRecordedIntegrationEvent>(
    InventoryInboundRecordedIntegrationEventHandler(
      internalCommandDispatcher: container.get<IPartnerInternalCommandDispatcher>(),
    ),
  );
  dispatcher.register<SalesOrderCheckedOutIntegrationEvent>(
    SalesOrderCheckedOutIntegrationEventHandler(
      internalCommandDispatcher: container.get<IPartnerInternalCommandDispatcher>(),
    ),
  );
  return dispatcher;
}

