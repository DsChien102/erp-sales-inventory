import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_resend/vet45_resend.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../adapters/notification/iam_email_sender_gateway.dart';
import '../../adapters/notification/supabase_email_delivery_gateways.dart';
import '../../adapters/notification/supabase_email_delivery_port.dart';
import '../../domain/access/supabase_iam_access_gateway.dart';
import '../../domain/access/supabase_platform_user_preference_port.dart';
import '../../domain/auth/supabase_authenticator.dart';
import '../../domain/identity/supabase_identity_self_service_gateway.dart';
import '../../domain/platform/supabase_platform_admin_gateway.dart';
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
      ..registerSingleton<IPlatformAdminGateway>(
        SupabasePlatformAdminGateway(
          rpcClient: container.get<SupabaseSchemaRpcClient>(),
        ),
      )
      ..registerSingleton<IIdentitySelfServiceGateway>(
        SupabaseIdentitySelfServiceGateway(
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
