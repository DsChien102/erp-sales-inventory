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
    ..registerFactory<ICommandValidator<ActivateTenantCommand>>(
      ActivateTenantCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<AssignMemberRoleCommand>>(
      AssignMemberRoleCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CompleteMyPasswordResetCommand>>(
      CompleteMyPasswordResetCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CompletePasswordResetByEmailCommand>>(
      CompletePasswordResetByEmailCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CreateInvitationCommand>>(
      CreateInvitationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CreateTenantOnboardingCommand>>(
      CreateTenantOnboardingCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ReinviteProvisioningOwnerCommand>>(
      ReinviteProvisioningOwnerCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RequestPasswordResetByEmailCommand>>(
      RequestPasswordResetByEmailCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ResendInvitationCommand>>(
      ResendInvitationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ResendMyPasswordResetCommand>>(
      ResendMyPasswordResetCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ResendPasswordResetByEmailCommand>>(
      ResendPasswordResetByEmailCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RestorePlatformTenantCommand>>(
      RestorePlatformTenantCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RetryTenantOnboardingOperationCommand>>(
      RetryTenantOnboardingOperationCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RevokeInvitationCommand>>(
      RevokeInvitationCommandValidator.new,
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
    ..registerFactory<ICommandValidator<UpdateMyIdentityProfileCommand>>(
      UpdateMyIdentityProfileCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<VerifyMyPasswordResetCommand>>(
      VerifyMyPasswordResetCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<VerifyPasswordResetByEmailCommand>>(
      VerifyPasswordResetByEmailCommandValidator.new,
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

  IamCommandRegistration.registerBusinessHandler<AcceptInvitationCommand, TenantMemberDetailDto, AcceptInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => AcceptInvitationCommandHandler(
      acceptancePort: container.get<ITenantInvitationAcceptancePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<ActivateTenantCommand, TenantActivationResultDto, ActivateTenantCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ActivateTenantCommandHandler(
      commandGateway: container.get<ITenantActivationCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<AssignMemberRoleCommand, void, AssignMemberRoleCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => AssignMemberRoleCommandHandler(
      accessGateway: container.get<IIamAccessGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<CompleteMyPasswordResetCommand, PasswordResetCompletionResultDto, CompleteMyPasswordResetCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CompleteMyPasswordResetCommandHandler(
      identityPort: container.get<IPlatformIdentitySelfServicePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<CompletePasswordResetByEmailCommand, PasswordResetCompletionResultDto, CompletePasswordResetByEmailCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CompletePasswordResetByEmailCommandHandler(
      publicResetPort: container.get<IPasswordResetPublicPort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<CreateInvitationCommand, InvitationDetailDto, CreateInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CreateInvitationCommandHandler(
      commandGateway: container.get<ITenantInvitationCommandGateway>(),
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

  IamCommandRegistration.registerBusinessHandler<DeactivateMembershipCommand, TenantMemberDetailDto, DeactivateMembershipCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeactivateMembershipCommandHandler(
      commandGateway: container.get<ITenantMembershipCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<DeclineInvitationCommand, InvitationDetailDto, DeclineInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeclineInvitationCommandHandler(
      acceptancePort: container.get<ITenantInvitationAcceptancePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<ReactivateMembershipCommand, TenantMemberDetailDto, ReactivateMembershipCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReactivateMembershipCommandHandler(
      commandGateway: container.get<ITenantMembershipCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RegisterFromInvitationCommand, InvitationRegistrationResultDto, RegisterFromInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RegisterFromInvitationCommandHandler(
      acceptancePort: container.get<ITenantInvitationAcceptancePort>(),
      identityPort: container.get<IInvitationIdentityPort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<ReinviteProvisioningOwnerCommand, TenantOnboardingResultDto, ReinviteProvisioningOwnerCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReinviteProvisioningOwnerCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RemoveMembershipCommand, TenantMemberDetailDto, RemoveMembershipCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RemoveMembershipCommandHandler(
      commandGateway: container.get<ITenantMembershipCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RequestMyPasswordResetCommand, PasswordResetRequestResultDto, RequestMyPasswordResetCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestMyPasswordResetCommandHandler(
      identityPort: container.get<IPlatformIdentitySelfServicePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RequestPasswordResetByEmailCommand, PasswordResetRequestResultDto, RequestPasswordResetByEmailCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestPasswordResetByEmailCommandHandler(
      publicResetPort: container.get<IPasswordResetPublicPort>(),
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

  IamCommandRegistration.registerBusinessHandler<ResendInvitationCommand, InvitationDetailDto, ResendInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ResendInvitationCommandHandler(
      commandGateway: container.get<ITenantInvitationCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<ResendMyPasswordResetCommand, PasswordResetRequestResultDto, ResendMyPasswordResetCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ResendMyPasswordResetCommandHandler(
      identityPort: container.get<IPlatformIdentitySelfServicePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<ResendPasswordResetByEmailCommand, PasswordResetRequestResultDto, ResendPasswordResetByEmailCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ResendPasswordResetByEmailCommandHandler(
      publicResetPort: container.get<IPasswordResetPublicPort>(),
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

  IamCommandRegistration.registerBusinessHandler<RetryTenantOnboardingOperationCommand, TenantOnboardingOperationDto, RetryTenantOnboardingOperationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RetryTenantOnboardingOperationCommandHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<RevokeInvitationCommand, InvitationDetailDto, RevokeInvitationCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RevokeInvitationCommandHandler(
      commandGateway: container.get<ITenantInvitationCommandGateway>(),
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

  IamCommandRegistration.registerBusinessHandler<SignOutCommand, SignOutResultDto, SignOutCommandHandler>(
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

  IamCommandRegistration.registerBusinessHandler<UpdateMyIdentityProfileCommand, MyIdentityProfileDto, UpdateMyIdentityProfileCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateMyIdentityProfileCommandHandler(
      identityPort: container.get<IPlatformIdentitySelfServicePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<UpdateTenantProfileCommand, TenantDto, UpdateTenantProfileCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpdateTenantProfileCommandHandler(
      commandGateway: container.get<ITenantProfileCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<UpsertLegalProfileCommand, UpsertLegalProfileResultDto, UpsertLegalProfileCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => UpsertLegalProfileCommandHandler(
      commandGateway: container.get<ITenantProfileCommandGateway>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<VerifyMyPasswordResetCommand, PasswordResetVerifyResultDto, VerifyMyPasswordResetCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => VerifyMyPasswordResetCommandHandler(
      identityPort: container.get<IPlatformIdentitySelfServicePort>(),
    ),
  );

  IamCommandRegistration.registerBusinessHandler<VerifyPasswordResetByEmailCommand, PasswordResetVerifyResultDto, VerifyPasswordResetByEmailCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => VerifyPasswordResetByEmailCommandHandler(
      publicResetPort: container.get<IPasswordResetPublicPort>(),
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
  IamCommandRegistration.registerQueryHandler<GetActiveStoreContextQuery, ActiveStoreContextDto, GetActiveStoreContextQueryHandler>(
    bus: bus,
    factory: () => GetActiveStoreContextQueryHandler(
      accessGateway: container.get<IIamAccessGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetCurrentSessionQuery, SessionDto, GetCurrentSessionQueryHandler>(
    bus: bus,
    factory: () => GetCurrentSessionQueryHandler(
      authenticator: container.get<IAuthenticator>(),
      sessionPort: container.get<IIamSessionPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetInvitationQuery, InvitationDetailDto, GetInvitationQueryHandler>(
    bus: bus,
    factory: () => GetInvitationQueryHandler(
      readPort: container.get<ITenantInvitationReadPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetMyIdentityProfileQuery, MyIdentityProfileDto, GetMyIdentityProfileQueryHandler>(
    bus: bus,
    factory: () => GetMyIdentityProfileQueryHandler(
      identityPort: container.get<IPlatformIdentitySelfServicePort>(),
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

  IamCommandRegistration.registerQueryHandler<GetTenantAuditLogQuery, TenantAuditLogDetailDto, GetTenantAuditLogQueryHandler>(
    bus: bus,
    factory: () => GetTenantAuditLogQueryHandler(
      auditReadPort: container.get<ITenantAuditReadPort>(),
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

  IamCommandRegistration.registerQueryHandler<GetTenantMemberQuery, TenantMemberDetailDto, GetTenantMemberQueryHandler>(
    bus: bus,
    factory: () => GetTenantMemberQueryHandler(
      readGateway: container.get<ITenantMembershipReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetTenantOnboardingOperationQuery, TenantOnboardingOperationDto, GetTenantOnboardingOperationQueryHandler>(
    bus: bus,
    factory: () => GetTenantOnboardingOperationQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetTenantQuery, TenantDto, GetTenantQueryHandler>(
    bus: bus,
    factory: () => GetTenantQueryHandler(
      readGateway: container.get<ITenantProfileReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<GetTenantReadinessQuery, TenantReadinessDto, GetTenantReadinessQueryHandler>(
    bus: bus,
    factory: () => GetTenantReadinessQueryHandler(
      readinessGateway: container.get<ITenantReadinessGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<InspectInvitationTokenQuery, InvitationTokenInspectionDto, InspectInvitationTokenQueryHandler>(
    bus: bus,
    factory: () => InspectInvitationTokenQueryHandler(
      acceptancePort: container.get<ITenantInvitationAcceptancePort>(),
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

  IamCommandRegistration.registerQueryHandler<ListAssignableInvitationRolesQuery, List<AssignableRoleOptionDto>, ListAssignableInvitationRolesQueryHandler>(
    bus: bus,
    factory: () => ListAssignableInvitationRolesQueryHandler(
      readPort: container.get<IAssignableInvitationRoleReadPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<ListInvitationsQuery, CursorPageDto<InvitationSummaryDto>, ListInvitationsQueryHandler>(
    bus: bus,
    factory: () => ListInvitationsQueryHandler(
      readPort: container.get<ITenantInvitationReadPort>(),
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

  IamCommandRegistration.registerQueryHandler<ListTenantMembersQuery, CursorPageDto<TenantMemberDto>, ListTenantMembersQueryHandler>(
    bus: bus,
    factory: () => ListTenantMembersQueryHandler(
      accessGateway: container.get<IIamAccessGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<SearchPlatformAuditLogsQuery, CursorPageDto<PlatformAuditLogSummaryDto>, SearchPlatformAuditLogsQueryHandler>(
    bus: bus,
    factory: () => SearchPlatformAuditLogsQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<SearchPlatformTenantsQuery, CursorPageDto<PlatformTenantSummaryDto>, SearchPlatformTenantsQueryHandler>(
    bus: bus,
    factory: () => SearchPlatformTenantsQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<SearchPlatformUsersQuery, CursorPageDto<PlatformUserSummaryDto>, SearchPlatformUsersQueryHandler>(
    bus: bus,
    factory: () => SearchPlatformUsersQueryHandler(
      platformGateway: container.get<IPlatformAdminGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  IamCommandRegistration.registerQueryHandler<SearchTenantAuditLogsQuery, TenantAuditLogSearchPageDto, SearchTenantAuditLogsQueryHandler>(
    bus: bus,
    factory: () => SearchTenantAuditLogsQueryHandler(
      auditReadPort: container.get<ITenantAuditReadPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

