// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_pricing_internal_command_client.dart';
import 'pricing_command_registration.g.dart';

void registerGeneratedPricingValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<CancelCustomerPriceRuleImportCommand>>(
      CancelCustomerPriceRuleImportCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ConfirmCustomerPriceRuleImportCommand>>(
      ConfirmCustomerPriceRuleImportCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CreateCustomerPriceRuleCommand>>(
      CreateCustomerPriceRuleCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<DeleteCustomerPriceRuleCommand>>(
      DeleteCustomerPriceRuleCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<DisableCustomerPriceRuleCommand>>(
      DisableCustomerPriceRuleCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ReenableCustomerPriceRuleCommand>>(
      ReenableCustomerPriceRuleCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SaveRememberedPriceFromOrderCommand>>(
      SaveRememberedPriceFromOrderCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<StartCustomerPriceRuleImportCommand>>(
      StartCustomerPriceRuleImportCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<UpdateCustomerPriceRuleCommand>>(
      UpdateCustomerPriceRuleCommandValidator.new,
    )
    ;
}

void registerGeneratedPricingHandlers({
  required CommandBus bus,
  required GetIt container,
  required IPricingInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedPricingValidators(container);

  PricingCommandRegistration.registerBusinessHandler<CancelCustomerPriceRuleImportCommand, CustomerPriceRuleImportDto, CancelCustomerPriceRuleImportCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CancelCustomerPriceRuleImportCommandHandler(
      importGateway: container.get<ICustomerPriceRuleImportGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<ConfirmCustomerPriceRuleImportCommand, CustomerPriceRuleImportResultDto, ConfirmCustomerPriceRuleImportCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ConfirmCustomerPriceRuleImportCommandHandler(
      importGateway: container.get<ICustomerPriceRuleImportGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<CreateCustomerPriceRuleCommand, CreateCustomerPriceRuleResult, CreateCustomerPriceRuleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CreateCustomerPriceRuleCommandHandler(
      createContextPort: container.get<ICustomerPriceRuleCreateContextPort>(),
      commandGateway: container.get<ICustomerPriceRuleCommandGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<DeleteCustomerPriceRuleCommand, CustomerPriceRuleDetailDto, DeleteCustomerPriceRuleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeleteCustomerPriceRuleCommandHandler(
      commandGateway: container.get<ICustomerPriceRuleCommandGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<DisableCustomerPriceRuleCommand, CustomerPriceRuleDetailDto, DisableCustomerPriceRuleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DisableCustomerPriceRuleCommandHandler(
      commandGateway: container.get<ICustomerPriceRuleCommandGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<ReenableCustomerPriceRuleCommand, CustomerPriceRuleDetailDto, ReenableCustomerPriceRuleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReenableCustomerPriceRuleCommandHandler(
      commandGateway: container.get<ICustomerPriceRuleCommandGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<SaveRememberedPriceFromOrderCommand, RememberedPriceOutcomeDto, SaveRememberedPriceFromOrderCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SaveRememberedPriceFromOrderCommandHandler(
      gateway: container.get<IRememberedPriceGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<StartCustomerPriceRuleImportCommand, CustomerPriceRuleImportDetailDto, StartCustomerPriceRuleImportCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => StartCustomerPriceRuleImportCommandHandler(
      filePort: container.get<ICustomerPriceRuleImportFilePort>(),
      importGateway: container.get<ICustomerPriceRuleImportGateway>(),
    ),
  );

  PricingCommandRegistration.registerBusinessHandler<UpdateCustomerPriceRuleCommand, CustomerPriceRuleDetailDto, UpdateCustomerPriceRuleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateCustomerPriceRuleCommandHandler(
      updateContextPort: container.get<ICustomerPriceRuleUpdateContextPort>(),
      commandGateway: container.get<ICustomerPriceRuleCommandGateway>(),
    ),
  );

}

void registerGeneratedPricingQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  PricingCommandRegistration.registerQueryHandler<EvaluateSalesManualPriceQuery, SalesManualPriceEvaluationDto, EvaluateSalesManualPriceQueryHandler>(
    bus: bus,
    factory: () => EvaluateSalesManualPriceQueryHandler(
      readGateway: container.get<ISalesPricingReadGateway>(),
      validator: container.get<EvaluateSalesManualPriceQueryValidator>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<GetCustomerPriceRuleDetailQuery, CustomerPriceRuleDetailDto, GetCustomerPriceRuleDetailQueryHandler>(
    bus: bus,
    factory: () => GetCustomerPriceRuleDetailQueryHandler(
      readGateway: container.get<IPricingReadGateway>(),
      validator: container.get<GetCustomerPriceRuleDetailQueryValidator>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<GetCustomerPriceRuleHistoryQuery, CursorPageDto<CustomerPriceRuleActivityDto>, GetCustomerPriceRuleHistoryQueryHandler>(
    bus: bus,
    factory: () => GetCustomerPriceRuleHistoryQueryHandler(
      readGateway: container.get<IPricingReadGateway>(),
      validator: container.get<GetCustomerPriceRuleHistoryQueryValidator>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<GetCustomerPriceRuleImportQuery, CustomerPriceRuleImportDetailDto, GetCustomerPriceRuleImportQueryHandler>(
    bus: bus,
    factory: () => GetCustomerPriceRuleImportQueryHandler(
      importGateway: container.get<ICustomerPriceRuleImportGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<GetCustomerPriceRuleImportTemplateQuery, CustomerPriceRuleImportTemplateDto, GetCustomerPriceRuleImportTemplateQueryHandler>(
    bus: bus,
    factory: () => GetCustomerPriceRuleImportTemplateQueryHandler(
      filePort: container.get<ICustomerPriceRuleImportFilePort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<PrecheckCustomerPriceRuleReenableQuery, CustomerPriceRuleReenablePrecheckDto, PrecheckCustomerPriceRuleReenableQueryHandler>(
    bus: bus,
    factory: () => PrecheckCustomerPriceRuleReenableQueryHandler(
      precheckPort: container.get<ICustomerPriceRuleReenablePrecheckPort>(),
      validator: container.get<PrecheckCustomerPriceRuleReenableQueryValidator>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<PreviewSalesWorkingStatePricingQuery, SalesWorkingStatePricingPreviewDto, PreviewSalesWorkingStatePricingQueryHandler>(
    bus: bus,
    factory: () => PreviewSalesWorkingStatePricingQueryHandler(
      readGateway: container.get<ISalesPricingReadGateway>(),
      validator: container.get<PreviewSalesWorkingStatePricingQueryValidator>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<ResolveApplicableCustomerPriceRuleQuery, ResolveApplicableCustomerPriceRuleResultDto, ResolveApplicableCustomerPriceRuleQueryHandler>(
    bus: bus,
    factory: () => ResolveApplicableCustomerPriceRuleQueryHandler(
      readGateway: container.get<IPricingReadGateway>(),
      validator: container.get<ResolveApplicableCustomerPriceRuleQueryValidator>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PricingCommandRegistration.registerQueryHandler<SearchCustomerPriceRulesQuery, CustomerPriceRuleSearchResultDto, SearchCustomerPriceRulesQueryHandler>(
    bus: bus,
    factory: () => SearchCustomerPriceRulesQueryHandler(
      readGateway: container.get<IPricingReadGateway>(),
      validator: container.get<SearchCustomerPriceRulesQueryValidator>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

