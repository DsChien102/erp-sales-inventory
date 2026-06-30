import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../domain/access/supabase_iam_access_gateway.dart';
import '../../domain/auth/supabase_authenticator.dart';
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
        ),
      )
      ..registerSingleton<ITenantAccessChecker>(
        IamTenantAccessChecker(
          accessGateway: container.get<IIamAccessGateway>(),
        ),
      )
      ..registerSingleton(
        SignInCommandHandler(
          authenticator: container.get<IAuthenticator>(),
          sessionPort: container.get<IIamSessionPort>(),
        ),
      )
      ..registerSingleton(
        SignOutCommandHandler(
          authenticator: container.get<IAuthenticator>(),
          sessionPort: container.get<IIamSessionPort>(),
        ),
      )
      ..registerSingleton(
        GetCurrentSessionQueryHandler(
          sessionPort: container.get<IIamSessionPort>(),
        ),
      );
  }
}
