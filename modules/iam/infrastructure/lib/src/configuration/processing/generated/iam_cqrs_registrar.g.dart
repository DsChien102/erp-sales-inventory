// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_iam_internal_command_client.dart';
import 'iam_command_registration.g.dart';

void registerGeneratedIamValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<AssignMemberRoleCommand>>(
      AssignMemberRoleCommandValidator.new,
    )
    ;
}

void registerGeneratedIamHandlers({
  required CommandBus bus,
  required GetIt container,
  required IIamInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedIamValidators(container);

  IamCommandRegistration.registerBusinessHandler<AssignMemberRoleCommand, void, AssignMemberRoleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => AssignMemberRoleCommandHandler(
      accessGateway: container.get<IIamAccessGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<SignInCommand, void, SignInCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SignInCommandHandler(
      authenticator: container.get<IAuthenticator>(),
      sessionPort: container.get<IIamSessionPort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<SignOutCommand, void, SignOutCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SignOutCommandHandler(
      authenticator: container.get<IAuthenticator>(),
      sessionPort: container.get<IIamSessionPort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<SwitchActiveTenantCommand, void, SwitchActiveTenantCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SwitchActiveTenantCommandHandler(
      sessionPort: container.get<IIamSessionPort>(),
    ),
  );

  IamCommandRegistration.registerInternalHandler<SendEmailDeliveryCommand, SendEmailDeliveryCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SendEmailDeliveryCommandHandler(
      emailSender: container.get<IEmailSenderGateway>(),
      outcomes: container.get<IEmailDeliveryOutcomeStore>(),
    ),
    inner: (command) => container.get<SendEmailDeliveryCommandHandler>().handle(command),
    commandClient: internalCommandClient,
  );

}

void registerGeneratedIamQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  IamCommandRegistration.registerQueryHandler<GetCurrentSessionQuery, SessionDto, GetCurrentSessionQueryHandler>(
    bus: bus,
    factory: () => GetCurrentSessionQueryHandler(
      sessionPort: container.get<IIamSessionPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<ListTenantMembersQuery, List<TenantMemberDto>, ListTenantMembersQueryHandler>(
    bus: bus,
    factory: () => ListTenantMembersQueryHandler(
      accessGateway: container.get<IIamAccessGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

