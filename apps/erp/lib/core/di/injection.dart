import 'package:async_query/async_query.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_inventory_infrastructure/infrastructure.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/iam/data/account_repository.dart';
import '../../features/iam/data/organization_repository.dart';
import '../../features/partner/data/partner_repository.dart';
import '../router/session_refresh.dart';
import '../session/session_controller.dart';
import '../supabase/supabase_module.dart';
import '../supabase/supabase_rpc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({required SupabaseModule supabaseModule}) async {
  if (getIt.isRegistered<SupabaseModule>()) {
    return;
  }

  getIt.registerSingleton<SupabaseModule>(supabaseModule);

  getIt.registerLazySingleton<QueryClient>(
    () => QueryClient(
      options: const QueryClientOptions(
        queries: QueryOptionsDefaults(gcTime: Duration(minutes: 5)),
      ),
    ),
  );

  getIt.registerLazySingleton<ILoggerFactory>(
    () => const LoggingLoggerFactory(),
  );

  getIt.registerLazySingleton<IEventsBus>(() => InMemoryEventBusClient());

  final iamRuntime = await IamStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    integrationEventBus: getIt<IEventsBus>(),
  );

  // Bootstrap session identity only (no tenant context).
  // Tenant selection is deferred to SessionController.bootstrap() which reads
  // user_preferences and validates via get_tenant_context — ensuring the
  // last-selected tenant (not the oldest membership) is restored on login.
  final session = SessionController(
    iamModule: iamRuntime.module,
    auth: supabaseModule.client.auth,
    iamSession: iamRuntime.session,
    sessionPort: iamRuntime.sessionPort,
  )..start();
  getIt.registerSingleton<SessionController>(
    session,
    dispose: (controller) {
      controller.close();
    },
  );
  sessionRefresh.attach(session);

  getIt
    ..registerSingleton<IIamModule>(iamRuntime.module)
    ..registerSingleton<IExecutionContext>(iamRuntime.executionContext)
    ..registerSingleton<IPermissionChecker>(iamRuntime.permissionChecker)
    ..registerSingleton<ITenantAccessChecker>(iamRuntime.tenantAccessChecker)
    ..registerSingleton<IActiveStoreContext>(iamRuntime.activeStoreContext)
    ..registerSingleton<IamSession>(iamRuntime.session)
    ..registerSingleton<ICurrentUser>(iamRuntime.session)
    ..registerSingleton<ICurrentTenant>(iamRuntime.session)
    ..registerSingleton<IPrincipalSnapshot>(iamRuntime.session);

  getIt
    ..registerLazySingleton<SupabaseRpc>(() => SupabaseRpc(supabaseModule.client))
    ..registerLazySingleton<PartnerRepository>(
      () => PartnerRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepository(
        rpc: getIt<SupabaseRpc>(),
        auth: supabaseModule.client.auth,
      ),
    )
    ..registerLazySingleton<OrganizationRepository>(
      () => OrganizationRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        rpc: getIt<SupabaseRpc>(),
        auth: supabaseModule.client.auth,
      ),
    );

  final catalogModule = CatalogStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
  );

  getIt.registerSingleton<ICatalogModule>(catalogModule);

  final partnerModule = PartnerStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
  );

  getIt.registerSingleton<IPartnerModule>(partnerModule);

  final pricingModule = PricingStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    executionContext: iamRuntime.executionContext,
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
  );

  getIt.registerSingleton<IPricingModule>(pricingModule);

  final salesModule = SalesStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
  );

  getIt.registerSingleton<ISalesModule>(salesModule);

  final einvoiceRuntime = EinvoiceStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
    integrationEventBus: getIt<IEventsBus>(),
  );

  getIt.registerSingleton<IEInvoiceModule>(einvoiceRuntime.module);

  final inventoryModule = InventoryStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    executionContext: iamRuntime.executionContext,
    permissionChecker: iamRuntime.permissionChecker,
    tenantAccessChecker: iamRuntime.tenantAccessChecker,
  );
  getIt.registerSingleton<IInventoryModule>(inventoryModule);
}
