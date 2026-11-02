import 'package:async_query/async_query.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_inventory_infrastructure/infrastructure.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/invitation_acceptance_repository.dart';
import '../../features/iam/data/account_repository.dart';
import '../../features/iam/data/audit_log_repository.dart';
import '../../features/iam/data/invitation_repository.dart';
import '../../features/iam/data/member_repository.dart';
import '../../features/iam/data/organization_repository.dart';
import '../../features/inventory/data/goods_receipt_repository.dart';
import '../../features/inventory/data/valuation_repository.dart';
import '../../features/partner/data/partner_repository.dart';
import '../errors/app_exception.dart';
import '../router/session_refresh.dart';
import '../session/session_contracts.dart';
import '../session/session_controller.dart';
import '../session/session_repository.dart';
import '../session/session_store.dart';
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

  getIt.registerLazySingleton<SupabaseRpc>(() => SupabaseRpc(supabaseModule.client));
  getIt.registerLazySingleton<SessionRepository>(
    () => SessionRepository(rpc: getIt<SupabaseRpc>()),
  );

  final sessionStore = SessionStore(repository: getIt<SessionRepository>());
  getIt.registerSingleton<SessionStore>(sessionStore);

  // Bootstrap session identity only (no tenant context).
  // Tenant selection is deferred to SessionController.bootstrap() which reads
  // the last-selected tenant and validates via get_tenant_context.
  final session = SessionController(
    repository: getIt<SessionRepository>(),
    auth: supabaseModule.client.auth,
    store: sessionStore,
  )..start();
  getIt.registerSingleton<SessionController>(
    session,
    dispose: (controller) {
      controller.close();
    },
  );
  sessionRefresh.attach(session);

  // Ngữ cảnh / quyền cho các module nghiệp vụ cũ, đọc cùng SessionStore.
  final executionContext = CoreExecutionContext(store: sessionStore);
  final permissionChecker = CorePermissionChecker(
    store: sessionStore,
    repository: getIt<SessionRepository>(),
    executionContext: executionContext,
  );
  final tenantAccessChecker = CoreTenantAccessChecker(
    repository: getIt<SessionRepository>(),
  );

  getIt
    ..registerSingleton<IExecutionContext>(executionContext)
    ..registerSingleton<ICurrentUser>(executionContext)
    ..registerSingleton<ICurrentTenant>(executionContext)
    ..registerSingleton<IPermissionChecker>(permissionChecker)
    ..registerSingleton<ITenantAccessChecker>(tenantAccessChecker);

  getIt
    ..registerLazySingleton<ValuationRepository>(() => ValuationRepository())
    ..registerLazySingleton<GoodsReceiptRepository>(
      () => GoodsReceiptRepository(valuation: getIt<ValuationRepository>()),
    )
    ..registerLazySingleton<PartnerRepository>(
      () => PartnerRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
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
    ..registerLazySingleton<MemberRepository>(
      () => MemberRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<InvitationRepository>(
      () => InvitationRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<AuditLogRepository>(
      () => AuditLogRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        rpc: getIt<SupabaseRpc>(),
        auth: supabaseModule.client.auth,
      ),
    )
    ..registerLazySingleton<InvitationAcceptanceRepository>(
      () => InvitationAcceptanceRepository(
        rpc: getIt<SupabaseRpc>(),
        functions: supabaseModule.client.functions,
      ),
    );

  final catalogModule = CatalogStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: permissionChecker,
    tenantAccessChecker: tenantAccessChecker,
  );

  getIt.registerSingleton<ICatalogModule>(catalogModule);

  final pricingModule = PricingStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    executionContext: executionContext,
    permissionChecker: permissionChecker,
    tenantAccessChecker: tenantAccessChecker,
  );

  getIt.registerSingleton<IPricingModule>(pricingModule);

  final salesModule = SalesStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: permissionChecker,
    tenantAccessChecker: tenantAccessChecker,
  );

  getIt.registerSingleton<ISalesModule>(salesModule);

  final einvoiceRuntime = EinvoiceStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    permissionChecker: permissionChecker,
    tenantAccessChecker: tenantAccessChecker,
    integrationEventBus: getIt<IEventsBus>(),
  );

  getIt.registerSingleton<IEInvoiceModule>(einvoiceRuntime.module);

  final inventoryModule = InventoryStartup.initialize(
    supabase: supabaseModule.client,
    loggerFactory: getIt<ILoggerFactory>(),
    executionContext: executionContext,
    permissionChecker: permissionChecker,
    tenantAccessChecker: tenantAccessChecker,
  );
  getIt.registerSingleton<IInventoryModule>(inventoryModule);
}
