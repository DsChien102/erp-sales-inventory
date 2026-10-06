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

import '../supabase/supabase_module.dart';
import '../session/restore_persisted_auth_session.dart';

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
  // Tenant selection is deferred to TenantContextCubit.bootstrap() which reads
  // user_preferences and validates via get_tenant_context — ensuring the
  // last-selected tenant (not the oldest membership) is restored on login.
  restorePersistedAuthSession(
    authenticator: iamRuntime.authenticator,
    sessionPort: iamRuntime.sessionPort,
  );

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
