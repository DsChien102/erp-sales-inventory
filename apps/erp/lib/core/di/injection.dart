import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../supabase/supabase_module.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({required SupabaseModule supabaseModule}) async {
  if (getIt.isRegistered<SupabaseModule>()) {
    return;
  }

  getIt.registerSingleton<SupabaseModule>(supabaseModule);

  getIt.registerLazySingleton<ILoggerFactory>(
    () => const LoggingLoggerFactory(),
  );

  getIt.registerLazySingleton<IEventsBus>(() => InMemoryEventBusClient());

  final iamRuntime = await IamStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    integrationEventBus: getIt<IEventsBus>(),
  );

  getIt
    ..registerSingleton<IIamModule>(iamRuntime.module)
    ..registerSingleton<IExecutionContext>(iamRuntime.executionContext)
    ..registerSingleton<IPermissionChecker>(iamRuntime.permissionChecker)
    ..registerSingleton<ITenantAccessChecker>(iamRuntime.tenantAccessChecker)
    ..registerSingleton<IamSession>(iamRuntime.session)
    ..registerSingleton<ICurrentUser>(iamRuntime.session)
    ..registerSingleton<ICurrentTenant>(iamRuntime.session)
    ..registerSingleton<IPrincipalSnapshot>(iamRuntime.session);

  final catalogModule = CatalogStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
  );

  getIt.registerSingleton<ICatalogModule>(catalogModule);
}
