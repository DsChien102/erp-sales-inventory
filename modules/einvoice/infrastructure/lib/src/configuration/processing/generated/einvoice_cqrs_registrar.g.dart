// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_einvoice_internal_command_client.dart';
import 'einvoice_command_registration.g.dart';

void registerGeneratedEinvoiceValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<ConnectProviderCommand>>(
      ConnectProviderCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SetDefaultIssuanceConfigurationCommand>>(
      SetDefaultIssuanceConfigurationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<UpdateAutomationPolicyCommand>>(
      UpdateAutomationPolicyCommandValidator.new,
    )
    ;
}

void registerGeneratedEinvoiceHandlers({
  required CommandBus bus,
  required GetIt container,
  required IEinvoiceInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedEinvoiceValidators(container);

  EinvoiceCommandRegistration.registerBusinessHandler<ConnectProviderCommand, ProviderConnectionResultDto, ConnectProviderCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ConnectProviderCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<DisconnectProviderCommand, ProviderConnectionResultDto, DisconnectProviderCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DisconnectProviderCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<ReconnectProviderCommand, ProviderConnectionResultDto, ReconnectProviderCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReconnectProviderCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<SetDefaultIssuanceConfigurationCommand, IssuanceProfileDto, SetDefaultIssuanceConfigurationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SetDefaultIssuanceConfigurationCommandHandler(
      profileGateway: container.get<IIssuanceProfileGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<UpdateAutomationPolicyCommand, AutomationPolicyDto, UpdateAutomationPolicyCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateAutomationPolicyCommandHandler(
      policyGateway: container.get<IAutomationPolicyGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<VerifyProviderConnectionCommand, ProviderConnectionCheckResultDto, VerifyProviderConnectionCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => VerifyProviderConnectionCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerInternalHandler<RecordConnectionVerifiedCommand, RecordConnectionVerifiedCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordConnectionVerifiedCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
    inner: (command) => container.get<RecordConnectionVerifiedCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<SyncProviderCapabilitiesCommand, SyncProviderCapabilitiesCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SyncProviderCapabilitiesCommandHandler(
      meInvoiceProviderPort: container.get<IMeInvoiceProviderPort>(),
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
    inner: (command) => container.get<SyncProviderCapabilitiesCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

}

void registerGeneratedEinvoiceQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  EinvoiceCommandRegistration.registerQueryHandler<GetAutomationPolicyQuery, AutomationPolicyDto, GetAutomationPolicyQueryHandler>(
    bus: bus,
    factory: () => GetAutomationPolicyQueryHandler(
      policyGateway: container.get<IAutomationPolicyGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<GetConfigurationReadinessQuery, ConfigurationReadinessDto, GetConfigurationReadinessQueryHandler>(
    bus: bus,
    factory: () => GetConfigurationReadinessQueryHandler(
      readinessGateway: container.get<IConfigurationReadinessReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<GetIssuanceProfileQuery, IssuanceProfileDto, GetIssuanceProfileQueryHandler>(
    bus: bus,
    factory: () => GetIssuanceProfileQueryHandler(
      profileGateway: container.get<IIssuanceProfileGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<GetProviderConnectionScreenQuery, ProviderConnectionScreenDto, GetProviderConnectionScreenQueryHandler>(
    bus: bus,
    factory: () => GetProviderConnectionScreenQueryHandler(
      readGateway: container.get<IProviderConnectionReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<ListProviderTemplatesQuery, List<ProviderTemplateDto>, ListProviderTemplatesQueryHandler>(
    bus: bus,
    factory: () => ListProviderTemplatesQueryHandler(
      readGateway: container.get<IProviderConnectionReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

