// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_partner_internal_command_client.dart';
import 'partner_command_registration.g.dart';

void registerGeneratedPartnerValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<CreatePartnerCommand>>(
      CreatePartnerCommandValidator.new,
    )
    ;
}

void registerGeneratedPartnerHandlers({
  required CommandBus bus,
  required GetIt container,
  required IPartnerInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedPartnerValidators(container);

  PartnerCommandRegistration.registerBusinessHandler<AddOrganizationContactCommand, AddOrganizationContactResult, AddOrganizationContactCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => AddOrganizationContactCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<CreatePartnerCommand, CreatePartnerResult, CreatePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CreatePartnerCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<DeactivatePartnerCommand, DeactivatePartnerResult, DeactivatePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeactivatePartnerCommandHandler(
      repository: container.get<IPartnerRepository>(),
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<ReactivatePartnerCommand, ReactivatePartnerResult, ReactivatePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReactivatePartnerCommandHandler(
      repository: container.get<IPartnerRepository>(),
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<RemoveOrganizationContactCommand, void, RemoveOrganizationContactCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RemoveOrganizationContactCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<SoftDeletePartnerCommand, SoftDeletePartnerResult, SoftDeletePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SoftDeletePartnerCommandHandler(
      repository: container.get<IPartnerRepository>(),
      readGateway: container.get<IPartnerReadGateway>(),
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<TransformPersonToOrganizationCommand, TransformPartnerResult, TransformPersonToOrganizationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => TransformPersonToOrganizationCommandHandler(
      repository: container.get<IPartnerRepository>(),
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<UpdateOrganizationContactCommand, void, UpdateOrganizationContactCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateOrganizationContactCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<UpdatePartnerProfileCommand, UpdatePartnerProfileResult, UpdatePartnerProfileCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdatePartnerProfileCommandHandler(
      repository: container.get<IPartnerRepository>(),
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerInternalHandler<RecordPartnerHistoryCommand, RecordPartnerHistoryCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RecordPartnerHistoryCommandHandler(
      historyWriteGateway: container.get<IPartnerHistoryWriteGateway>(),
    ),
    inner: (command) => container.get<RecordPartnerHistoryCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

}

void registerGeneratedPartnerQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  PartnerCommandRegistration.registerQueryHandler<CheckDeleteEligibilityQuery, DeleteEligibilityDto, CheckDeleteEligibilityQueryHandler>(
    bus: bus,
    factory: () => CheckDeleteEligibilityQueryHandler(
      readGateway: container.get<IPartnerReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PartnerCommandRegistration.registerQueryHandler<CheckDuplicatePartnersQuery, List<PartnerDuplicateMatchDto>, CheckDuplicatePartnersQueryHandler>(
    bus: bus,
    factory: () => CheckDuplicatePartnersQueryHandler(
      duplicateChecker: container.get<IPartnerDuplicateChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PartnerCommandRegistration.registerQueryHandler<GetPartnerActionLogsQuery, PartnerActionLogResultDto, GetPartnerActionLogsQueryHandler>(
    bus: bus,
    factory: () => GetPartnerActionLogsQueryHandler(
      readGateway: container.get<IPartnerReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PartnerCommandRegistration.registerQueryHandler<GetPartnerDetailQuery, PartnerDetailDto, GetPartnerDetailQueryHandler>(
    bus: bus,
    factory: () => GetPartnerDetailQueryHandler(
      readGateway: container.get<IPartnerReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PartnerCommandRegistration.registerQueryHandler<GetPartnerHistoryQuery, PartnerHistoryResultDto, GetPartnerHistoryQueryHandler>(
    bus: bus,
    factory: () => GetPartnerHistoryQueryHandler(
      readGateway: container.get<IPartnerReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  PartnerCommandRegistration.registerQueryHandler<SearchPartnersQuery, PartnerSearchResultDto, SearchPartnersQueryHandler>(
    bus: bus,
    factory: () => SearchPartnersQueryHandler(
      readGateway: container.get<IPartnerReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

