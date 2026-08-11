import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_resend/vet45_resend.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../adapters/audit/supabase_tenant_audit_read_port.dart';
import '../../adapters/identity/password_reset_operation_store.dart';
import '../../adapters/identity/supabase_auth_account_client.dart';
import '../../adapters/identity/supabase_password_reset_public_adapter.dart';
import '../../adapters/identity/supabase_platform_identity_provisioning_adapter.dart';
import '../../adapters/identity/supabase_platform_identity_self_service_adapter.dart';
import '../../adapters/identity/unavailable_tenant_activation_identity_port.dart';
import '../../adapters/invitation/invitation_auth_client.dart';
import '../../adapters/invitation/supabase_invitation_identity_adapter.dart';
import '../../adapters/invitation/supabase_assignable_invitation_role_read_port.dart';
import '../../domain/invitation/supabase_tenant_invitation_acceptance_port.dart';
import '../../domain/invitation/supabase_tenant_invitation_command_gateway.dart';
import '../../domain/invitation/supabase_tenant_invitation_read_port.dart';
import '../../domain/platform_user/supabase_platform_user_profile_gateway.dart';
import '../../adapters/notification/iam_email_sender_gateway.dart';
import '../../adapters/notification/supabase_email_delivery_gateways.dart';
import '../../adapters/notification/supabase_email_delivery_port.dart';
import '../../domain/access/supabase_iam_access_gateway.dart';
import '../../domain/access/supabase_platform_user_preference_port.dart';
import '../../domain/auth/supabase_authenticator.dart';
import '../../domain/membership/supabase_tenant_membership_command_gateway.dart';
import '../../domain/membership/supabase_tenant_membership_read_gateway.dart';
import '../../domain/platform/supabase_platform_admin_gateway.dart';
import '../../domain/tenant/supabase_tenant_activation_command_gateway.dart';
import '../../domain/tenant/supabase_tenant_profile_command_gateway.dart';
import '../../domain/tenant/supabase_tenant_profile_read_gateway.dart';
import '../../domain/tenant/supabase_tenant_readiness_gateway.dart';
import '../session/iam_execution_context.dart';
import '../session/iam_session.dart';
import '../session/iam_session_coordinator.dart';

/// Registers IAM gateways, session, and access checkers.
final class IamDataAccessModule {
  const IamDataAccessModule();

  void load({
    required GetIt container,
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    IResendClient? resendClient,
  }) {
    final logger = loggerFactory.named('iam.rpc');

    container
      ..registerSingleton<IamSession>(IamSession())
      ..registerSingleton<SupabaseSchemaRpcClient>(
        SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'iam',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
          logger: logger,
        ),
      )
      ..registerSingleton<IIamAccessGateway>(
        SupabaseIamAccessGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantMembershipReadGateway>(
        SupabaseTenantMembershipReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantMembershipCommandGateway>(
        SupabaseTenantMembershipCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantProfileReadGateway>(
        SupabaseTenantProfileReadGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantProfileCommandGateway>(
        SupabaseTenantProfileCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantReadinessGateway>(
        SupabaseTenantReadinessGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantActivationCommandGateway>(
        SupabaseTenantActivationCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantActivationIdentityPort>(
        UnavailableTenantActivationIdentityPort(),
      )
      ..registerSingleton<ITenantAuditReadPort>(
        SupabaseTenantAuditReadPort(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantInvitationReadPort>(
        SupabaseTenantInvitationReadPort(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IAssignableInvitationRoleReadPort>(
        SupabaseAssignableInvitationRoleReadPort(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantInvitationCommandGateway>(
        SupabaseTenantInvitationCommandGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<ITenantInvitationAcceptancePort>(
        SupabaseTenantInvitationAcceptancePort(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IInvitationIdentityPort>(
        SupabaseInvitationIdentityAdapter(
          authClient: SupabaseInvitationAuthClient(supabase),
          profileGateway: SupabasePlatformUserProfileGateway(
            rpcClient: container.get<SupabaseSchemaRpcClient>(),
          ),
        ),
      )
      ..registerSingleton<IPasswordResetPublicPort>(
        SupabasePasswordResetPublicAdapter(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPlatformIdentitySelfServicePort>(
        SupabasePlatformIdentitySelfServiceAdapter(
          profileGateway: SupabasePlatformUserProfileGateway(
            rpcClient: container.get<SupabaseSchemaRpcClient>(),
          ),
          authClient: SupabaseAuthAccountClient(supabase),
          passwordResetStore: SupabasePasswordResetOperationStore(
            rpcClient: container.get<SupabaseSchemaRpcClient>(),
          ),
        ),
      )
      ..registerSingleton<IPlatformIdentityProvisioningPort>(
        SupabasePlatformIdentityProvisioningAdapter(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPlatformAdminGateway>(
        SupabasePlatformAdminGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IPlatformUserPreferencePort>(
        SupabasePlatformUserPreferencePort(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IAuthenticator>(SupabaseAuthenticator(supabase))
      ..registerSingleton<IIamSessionPort>(
        IamSessionCoordinator(
          session: container.get<IamSession>(),
          accessGateway: container.get<IIamAccessGateway>(),
          authenticator: container.get<IAuthenticator>(),
        ),
      )
      ..registerSingleton<IPrincipalSnapshot>(container.get<IamSession>())
      ..registerSingleton<ICurrentUser>(container.get<IamSession>())
      ..registerSingleton<ICurrentTenant>(container.get<IamSession>())
      ..registerSingleton<IExecutionContext>(
        IamExecutionContext(session: container.get<IamSession>()),
      )
      ..registerSingleton<IPermissionChecker>(
        IamPermissionChecker(
          principalSnapshot: container.get<IPrincipalSnapshot>(),
          accessGateway: container.get<IIamAccessGateway>(),
          executionContext: container.get<IExecutionContext>(),
          platformGateway: container.get<IPlatformAdminGateway>(),
        ),
      )
      ..registerSingleton<ITenantAccessChecker>(
        IamTenantAccessChecker(
          accessGateway: container.get<IIamAccessGateway>(),
        ),
      )
      ..registerSingleton<IResendClient>(
        resendClient ?? ResendEmailClient(apiKey: null),
      )
      ..registerSingleton<IEmailSenderGateway>(
        IamEmailSenderGateway(
          resendClient: container.get<IResendClient>(),
        ),
      )
      ..registerSingleton<IEmailDeliveryOutcomeStore>(
        SupabaseEmailDeliveryOutcomeGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      );
  }

  /// Registers [IEmailDeliveryPort] (outcome read; enqueue is Fake/test only).
  void registerEmailDeliveryPort(GetIt container) {
    if (container.isRegistered<IEmailDeliveryPort>()) {
      return;
    }
    container.registerSingleton<IEmailDeliveryPort>(
      SupabaseEmailDeliveryPort(
        outcomes: container.get<IEmailDeliveryOutcomeStore>(),
      ),
    );
  }
}
