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
    ..registerFactory<ICommandValidator<CompleteBuyerInvoiceDataCommand>>(
      CompleteBuyerInvoiceDataCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ConnectProviderCommand>>(
      ConnectProviderCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<IssueInvoiceCommand>>(
      IssueInvoiceCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<OpenReconciliationCaseCommand>>(
      OpenReconciliationCaseCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<PollIssuanceStatusCommand>>(
      PollIssuanceStatusCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RecordDeliveryResultCommand>>(
      RecordDeliveryResultCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RecordIssuanceResultCommand>>(
      RecordIssuanceResultCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RecordProviderObservationCommand>>(
      RecordProviderObservationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RecoverInternalFinalizationCommand>>(
      RecoverInternalFinalizationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ReevaluateAutoIssuanceCommand>>(
      ReevaluateAutoIssuanceCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RequestInvoiceDocumentCommand>>(
      RequestInvoiceDocumentCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RequestInvoicePreviewCommand>>(
      RequestInvoicePreviewCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RequestOfficialInvoiceViewCommand>>(
      RequestOfficialInvoiceViewCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ResolveReconciliationCaseCommand>>(
      ResolveReconciliationCaseCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RetryIssuanceCommand>>(
      RetryIssuanceCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SendElectronicInvoiceCommand>>(
      SendElectronicInvoiceCommandValidator.new,
    )
    ..registerFactory<
      ICommandValidator<SetDefaultIssuanceConfigurationCommand>
    >(SetDefaultIssuanceConfigurationCommandValidator.new)
    ..registerFactory<ICommandValidator<StartAutoDeliveryCommand>>(
      StartAutoDeliveryCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<StartAutoIssuanceCommand>>(
      StartAutoIssuanceCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<UpdateAutomationPolicyCommand>>(
      UpdateAutomationPolicyCommandValidator.new,
    );
}

void registerGeneratedEinvoiceHandlers({
  required CommandBus bus,
  required GetIt container,
  required IEinvoiceInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedEinvoiceValidators(container);

  EinvoiceCommandRegistration.registerBusinessHandler<
    CompleteBuyerInvoiceDataCommand,
    BuyerCompletionResultDto,
    CompleteBuyerInvoiceDataCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CompleteBuyerInvoiceDataCommandHandler(
      gateway: container.get<IBuyerInvoiceDataGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    ConnectProviderCommand,
    ProviderConnectionResultDto,
    ConnectProviderCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ConnectProviderCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    DisconnectProviderCommand,
    ProviderConnectionResultDto,
    DisconnectProviderCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DisconnectProviderCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    IssueInvoiceCommand,
    IssueInvoiceResultDto,
    IssueInvoiceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => IssueInvoiceCommandHandler(
      gateway: container.get<IIssuanceCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    OpenReconciliationCaseCommand,
    ReconciliationCaseDto,
    OpenReconciliationCaseCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => OpenReconciliationCaseCommandHandler(
      gateway: container.get<IIssuanceReconciliationGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    ReconnectProviderCommand,
    ProviderConnectionResultDto,
    ReconnectProviderCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReconnectProviderCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RecordDeliveryResultCommand,
    RecordDeliveryResultDto,
    RecordDeliveryResultCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordDeliveryResultCommandHandler(
      gateway: container.get<IDeliveryCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RecordIssuanceResultCommand,
    RecordIssuanceResultDto,
    RecordIssuanceResultCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordIssuanceResultCommandHandler(
      gateway: container.get<IIssuanceResultGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RecordProviderObservationCommand,
    ProviderObservationDto,
    RecordProviderObservationCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordProviderObservationCommandHandler(
      gateway: container.get<IElectronicInvoiceCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RecoverInternalFinalizationCommand,
    RecoverInternalFinalizationResultDto,
    RecoverInternalFinalizationCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecoverInternalFinalizationCommandHandler(
      gateway: container.get<IIssuanceReconciliationGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    ReevaluateAutoIssuanceCommand,
    AutoIssuanceResultDto,
    ReevaluateAutoIssuanceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReevaluateAutoIssuanceCommandHandler(
      gateway: container.get<IAutoIssuanceGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RequestInvoiceDocumentCommand,
    InvoiceDocumentRetrievalDto,
    RequestInvoiceDocumentCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestInvoiceDocumentCommandHandler(
      gateway: container.get<IElectronicInvoiceCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RequestInvoicePreviewCommand,
    InvoicePreviewResultDto,
    RequestInvoicePreviewCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestInvoicePreviewCommandHandler(
      readinessGateway: container.get<IIssuanceReadinessReadGateway>(),
      previewGateway: container.get<IInvoicePreviewGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RequestOfficialInvoiceViewCommand,
    OfficialInvoiceViewDto,
    RequestOfficialInvoiceViewCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestOfficialInvoiceViewCommandHandler(
      gateway: container.get<IElectronicInvoiceCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    ResolveReconciliationCaseCommand,
    ReconciliationCaseDto,
    ResolveReconciliationCaseCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ResolveReconciliationCaseCommandHandler(
      gateway: container.get<IIssuanceReconciliationGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    RetryIssuanceCommand,
    IssueInvoiceResultDto,
    RetryIssuanceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RetryIssuanceCommandHandler(
      gateway: container.get<IIssuanceCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    SendElectronicInvoiceCommand,
    SendInvoiceResultDto,
    SendElectronicInvoiceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SendElectronicInvoiceCommandHandler(
      gateway: container.get<IDeliveryCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    SetDefaultIssuanceConfigurationCommand,
    IssuanceProfileDto,
    SetDefaultIssuanceConfigurationCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SetDefaultIssuanceConfigurationCommandHandler(
      profileGateway: container.get<IIssuanceProfileGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    StartAutoDeliveryCommand,
    AutoDeliveryResultDto,
    StartAutoDeliveryCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => StartAutoDeliveryCommandHandler(
      gateway: container.get<IDeliveryCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    StartAutoIssuanceCommand,
    AutoIssuanceResultDto,
    StartAutoIssuanceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => StartAutoIssuanceCommandHandler(
      gateway: container.get<IAutoIssuanceGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    UpdateAutomationPolicyCommand,
    AutomationPolicyDto,
    UpdateAutomationPolicyCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateAutomationPolicyCommandHandler(
      policyGateway: container.get<IAutomationPolicyGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerBusinessHandler<
    VerifyProviderConnectionCommand,
    ProviderConnectionCheckResultDto,
    VerifyProviderConnectionCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => VerifyProviderConnectionCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    DownloadInvoiceDocumentCommand,
    DownloadInvoiceDocumentCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DownloadInvoiceDocumentCommandHandler(
      commandGateway: container.get<IElectronicInvoiceCommandGateway>(),
      providerPort: container.get<IElectronicInvoiceProviderPort>(),
      interactionGateway: container.get<IProviderInteractionGateway>(),
      storagePort: container.get<IInvoiceDocumentStoragePort>(),
    ),
    inner: (command) =>
        container.get<DownloadInvoiceDocumentCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    FetchOfficialInvoiceViewCommand,
    FetchOfficialInvoiceViewCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => FetchOfficialInvoiceViewCommandHandler(
      commandGateway: container.get<IElectronicInvoiceCommandGateway>(),
      providerPort: container.get<IElectronicInvoiceProviderPort>(),
      interactionGateway: container.get<IProviderInteractionGateway>(),
    ),
    inner: (command) =>
        container.get<FetchOfficialInvoiceViewCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    PollIssuanceStatusCommand,
    PollIssuanceStatusCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => PollIssuanceStatusCommandHandler(
      reconciliationGateway: container.get<IIssuanceReconciliationGateway>(),
      providerPort: container.get<IMeInvoiceProviderPort>(),
      commandDispatcher: container.get<IEinvoiceCommandDispatcher>(),
    ),
    inner: (command) =>
        container.get<PollIssuanceStatusCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    PollProviderObservationCommand,
    PollProviderObservationCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => PollProviderObservationCommandHandler(
      commandGateway: container.get<IElectronicInvoiceCommandGateway>(),
      providerPort: container.get<IElectronicInvoiceProviderPort>(),
      interactionGateway: container.get<IProviderInteractionGateway>(),
      commandDispatcher: container.get<IEinvoiceCommandDispatcher>(),
    ),
    inner: (command) =>
        container.get<PollProviderObservationCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    PreviewInvoiceCommand,
    PreviewInvoiceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => PreviewInvoiceCommandHandler(
      providerPort: container.get<IMeInvoiceProviderPort>(),
      previewGateway: container.get<IInvoicePreviewGateway>(),
      interactionGateway: container.get<IProviderInteractionGateway>(),
    ),
    inner: (command) =>
        container.get<PreviewInvoiceCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    PublishInvoiceCommand,
    PublishInvoiceCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => PublishInvoiceCommandHandler(
      providerPort: container.get<IMeInvoiceProviderPort>(),
      resultGateway: container.get<IIssuanceResultGateway>(),
    ),
    inner: (command) =>
        container.get<PublishInvoiceCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    ReconcileInvoiceDeliveryCommand,
    ReconcileInvoiceDeliveryCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReconcileInvoiceDeliveryCommandHandler(
      reconciliationGateway: container.get<IDeliveryReconciliationGateway>(),
      observationPort: container.get<IInvoiceDeliveryObservationProviderPort>(),
      interactionGateway: container.get<IProviderInteractionGateway>(),
    ),
    inner: (command) =>
        container.get<ReconcileInvoiceDeliveryCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    RecordConnectionVerifiedCommand,
    RecordConnectionVerifiedCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordConnectionVerifiedCommandHandler(
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
    inner: (command) =>
        container.get<RecordConnectionVerifiedCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    SendInvoiceEmailCommand,
    SendInvoiceEmailCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SendInvoiceEmailCommandHandler(
      commandGateway: container.get<IDeliveryCommandGateway>(),
      providerPort: container.get<IInvoiceDeliveryProviderPort>(),
      interactionGateway: container.get<IProviderInteractionGateway>(),
      commandDispatcher: container.get<IEinvoiceCommandDispatcher>(),
    ),
    inner: (command) =>
        container.get<SendInvoiceEmailCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

  EinvoiceCommandRegistration.registerInternalHandler<
    SyncProviderCapabilitiesCommand,
    SyncProviderCapabilitiesCommandHandler
  >(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SyncProviderCapabilitiesCommandHandler(
      meInvoiceProviderPort: container.get<IMeInvoiceProviderPort>(),
      commandGateway: container.get<IProviderConnectionCommandGateway>(),
    ),
    inner: (command) =>
        container.get<SyncProviderCapabilitiesCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );
}

void registerGeneratedEinvoiceQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  EinvoiceCommandRegistration.registerQueryHandler<
    GetAutomationPolicyQuery,
    AutomationPolicyDto,
    GetAutomationPolicyQueryHandler
  >(
    bus: bus,
    factory: () => GetAutomationPolicyQueryHandler(
      policyGateway: container.get<IAutomationPolicyGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetConfigurationReadinessQuery,
    ConfigurationReadinessDto,
    GetConfigurationReadinessQueryHandler
  >(
    bus: bus,
    factory: () => GetConfigurationReadinessQueryHandler(
      readinessGateway: container.get<IConfigurationReadinessReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetElectronicInvoiceDetailQuery,
    ElectronicInvoiceDetailDto,
    GetElectronicInvoiceDetailQueryHandler
  >(
    bus: bus,
    factory: () => GetElectronicInvoiceDetailQueryHandler(
      gateway: container.get<IElectronicInvoiceReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetInvoiceDeliveryHistoryQuery,
    InvoiceDeliveryHistoryDto,
    GetInvoiceDeliveryHistoryQueryHandler
  >(
    bus: bus,
    factory: () => GetInvoiceDeliveryHistoryQueryHandler(
      gateway: container.get<IDeliveryReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetInvoiceDocumentsQuery,
    InvoiceDocumentsDto,
    GetInvoiceDocumentsQueryHandler
  >(
    bus: bus,
    factory: () => GetInvoiceDocumentsQueryHandler(
      gateway: container.get<IElectronicInvoiceReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetInvoicePreviewQuery,
    InvoicePreviewResultDto,
    GetInvoicePreviewQueryHandler
  >(
    bus: bus,
    factory: () => GetInvoicePreviewQueryHandler(
      previewGateway: container.get<IInvoicePreviewGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetIssuanceAttemptStatusQuery,
    IssuanceAttemptStatusDto,
    GetIssuanceAttemptStatusQueryHandler
  >(
    bus: bus,
    factory: () => GetIssuanceAttemptStatusQueryHandler(
      gateway: container.get<IIssuanceReconciliationGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetIssuanceProfileQuery,
    IssuanceProfileDto,
    GetIssuanceProfileQueryHandler
  >(
    bus: bus,
    factory: () => GetIssuanceProfileQueryHandler(
      profileGateway: container.get<IIssuanceProfileGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetIssuanceReadinessQuery,
    IssuanceReadinessDto,
    GetIssuanceReadinessQueryHandler
  >(
    bus: bus,
    factory: () => GetIssuanceReadinessQueryHandler(
      readinessGateway: container.get<IIssuanceReadinessReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetLatestProviderObservationQuery,
    ProviderObservationDto?,
    GetLatestProviderObservationQueryHandler
  >(
    bus: bus,
    factory: () => GetLatestProviderObservationQueryHandler(
      gateway: container.get<IElectronicInvoiceReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetOrderInvoiceProjectionQuery,
    OrderInvoiceProjectionDto,
    GetOrderInvoiceProjectionQueryHandler
  >(
    bus: bus,
    factory: () => GetOrderInvoiceProjectionQueryHandler(
      projectionGateway: container.get<IOrderInvoiceProjectionReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetProviderConnectionScreenQuery,
    ProviderConnectionScreenDto,
    GetProviderConnectionScreenQueryHandler
  >(
    bus: bus,
    factory: () => GetProviderConnectionScreenQueryHandler(
      readGateway: container.get<IProviderConnectionReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    GetSendInvoiceSheetContextQuery,
    SendInvoiceSheetContextDto,
    GetSendInvoiceSheetContextQueryHandler
  >(
    bus: bus,
    factory: () => GetSendInvoiceSheetContextQueryHandler(
      gateway: container.get<IDeliveryReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  EinvoiceCommandRegistration.registerQueryHandler<
    ListProviderTemplatesQuery,
    List<ProviderTemplateDto>,
    ListProviderTemplatesQueryHandler
  >(
    bus: bus,
    factory: () => ListProviderTemplatesQueryHandler(
      readGateway: container.get<IProviderConnectionReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );
}
