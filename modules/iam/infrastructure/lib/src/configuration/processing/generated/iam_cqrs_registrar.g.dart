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
    ..registerFactory<ICommandValidator<CreateTenantOnboardingCommand>>(
      CreateTenantOnboardingCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RestorePlatformTenantCommand>>(
      RestorePlatformTenantCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SuspendPlatformTenantCommand>>(
      SuspendPlatformTenantCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SuspendPlatformUserCommand>>(
      SuspendPlatformUserCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SwitchTenantContextCommand>>(
      SwitchTenantContextCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<TransferPlatformTenantOwnershipCommand>>(
      TransferPlatformTenantOwnershipCommandValidator.new,
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

  IamCommandRegistration.registerBusinessHandler<CreateTenantOnboardingCommand, TenantOnboardingResultDto, CreateTenantOnboardingCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CreateTenantOnboardingCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RequestPlatformPasswordResetCommand, void, RequestPlatformPasswordResetCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestPlatformPasswordResetCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RestorePlatformTenantCommand, void, RestorePlatformTenantCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RestorePlatformTenantCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RestorePlatformUserCommand, void, RestorePlatformUserCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RestorePlatformUserCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<SendActivationInvitationCommand, void, SendActivationInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SendActivationInvitationCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
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

  IamCommandRegistration.registerBusinessHandler<SuspendPlatformTenantCommand, void, SuspendPlatformTenantCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SuspendPlatformTenantCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<SuspendPlatformUserCommand, void, SuspendPlatformUserCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SuspendPlatformUserCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
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

  IamCommandRegistration.registerBusinessHandler<SwitchTenantContextCommand, TenantContextDto, SwitchTenantContextCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SwitchTenantContextCommandHandler(
      accessGateway: container.get<IIamAccessGateway>(),
      preferencePort: container.get<IPlatformUserPreferencePort>(),
      sessionPort: container.get<IIamSessionPort>(),
      currentTenant: container.get<ICurrentTenant>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<TransferPlatformTenantOwnershipCommand, void, TransferPlatformTenantOwnershipCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => TransferPlatformTenantOwnershipCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
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

  IamCommandRegistration.registerQueryHandler<GetPlatformAuditLogQuery, PlatformAuditLogDetailDto, GetPlatformAuditLogQueryHandler>(
    bus: bus,
    factory: () => GetPlatformAuditLogQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetPlatformTenantQuery, PlatformTenantDetailDto, GetPlatformTenantQueryHandler>(
    bus: bus,
    factory: () => GetPlatformTenantQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetPlatformUserQuery, PlatformUserDetailDto, GetPlatformUserQueryHandler>(
    bus: bus,
    factory: () => GetPlatformUserQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetTenantContextQuery, TenantContextDto, GetTenantContextQueryHandler>(
    bus: bus,
    factory: () => GetTenantContextQueryHandler(
      accessGateway: container.get<IIamAccessGateway>(),
      preferencePort: container.get<IPlatformUserPreferencePort>(),
      sessionPort: container.get<IIamSessionPort>(),
      currentTenant: container.get<ICurrentTenant>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<ListAccessibleTenantsQuery, List<AccessibleTenantDto>, ListAccessibleTenantsQueryHandler>(
    bus: bus,
    factory: () => ListAccessibleTenantsQueryHandler(
      accessGateway: container.get<IIamAccessGateway>(),
      currentTenant: container.get<ICurrentTenant>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<ListPlatformTenantMembersQuery, List<PlatformTenantMemberDto>, ListPlatformTenantMembersQueryHandler>(
    bus: bus,
    factory: () => ListPlatformTenantMembersQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
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

  IamCommandRegistration.registerQueryHandler<SearchPlatformAuditLogsQuery, List<PlatformAuditLogSummaryDto>, SearchPlatformAuditLogsQueryHandler>(
    bus: bus,
    factory: () => SearchPlatformAuditLogsQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<SearchPlatformTenantsQuery, List<PlatformTenantSummaryDto>, SearchPlatformTenantsQueryHandler>(
    bus: bus,
    factory: () => SearchPlatformTenantsQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<SearchPlatformUsersQuery, List<PlatformUserSummaryDto>, SearchPlatformUsersQueryHandler>(
    bus: bus,
    factory: () => SearchPlatformUsersQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

