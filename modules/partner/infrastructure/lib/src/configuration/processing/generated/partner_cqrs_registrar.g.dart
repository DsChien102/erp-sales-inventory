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
    ..registerFactory<ICommandValidator<DeactivatePartnerCommand>>(
      DeactivatePartnerCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<DeletePartnerCommand>>(
      DeletePartnerCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ReactivatePartnerCommand>>(
      ReactivatePartnerCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RegisterPartnerCommand>>(
      RegisterPartnerCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<UpdatePartnerProfileCommand>>(
      UpdatePartnerProfileCommandValidator.new,
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

  PartnerCommandRegistration.registerBusinessHandler<DeactivatePartnerCommand, DeactivatePartnerResult, DeactivatePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeactivatePartnerCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<DeletePartnerCommand, DeletePartnerResult, DeletePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeletePartnerCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<ReactivatePartnerCommand, ReactivatePartnerResult, ReactivatePartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReactivatePartnerCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<RegisterPartnerCommand, RegisterPartnerResult, RegisterPartnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RegisterPartnerCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

  PartnerCommandRegistration.registerBusinessHandler<UpdatePartnerProfileCommand, UpdatePartnerProfileResult, UpdatePartnerProfileCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdatePartnerProfileCommandHandler(
      commandGateway: container.get<IPartnerCommandGateway>(),
    ),
  );

}

void registerGeneratedPartnerQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  PartnerCommandRegistration.registerQueryHandler<CheckDuplicatePartnersForUpdateQuery, List<PartnerDuplicateMatchDto>, CheckDuplicatePartnersForUpdateQueryHandler>(
    bus: bus,
    factory: () => CheckDuplicatePartnersForUpdateQueryHandler(
      duplicateChecker: container.get<IPartnerDuplicateChecker>(),
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

  PartnerCommandRegistration.registerQueryHandler<GetPartnerDetailQuery, PartnerDetailDto?, GetPartnerDetailQueryHandler>(
    bus: bus,
    factory: () => GetPartnerDetailQueryHandler(
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

