import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/invitation_acceptance_repository.dart';
import '../../features/catalog/data/custom_field_repository.dart';
import '../../features/catalog/data/measurement_unit_repository.dart';
import '../../features/catalog/data/product_price_repository.dart';
import '../../features/catalog/data/product_repository.dart';
import '../../features/dashboard/data/default_pair_repository.dart';
import '../../features/einvoice/data/einvoice_configuration_repository.dart';
import '../../features/einvoice/data/einvoice_processor_trigger.dart';
import '../../features/einvoice/data/einvoice_repository.dart';
import '../../features/einvoice/data/invoice_document_signed_urls.dart';
import '../../features/catalog/presentation/services/product_image_display_resolver.dart';
import '../../features/iam/data/account_repository.dart';
import '../../features/iam/data/audit_log_repository.dart';
import '../../features/iam/data/invitation_repository.dart';
import '../../features/iam/data/member_repository.dart';
import '../../features/iam/data/organization_repository.dart';
import '../../features/inventory/data/core/inventory_rpc.dart';
import '../../features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import '../../features/inventory/data/hub/warehouse_hub_repository.dart';
import '../../features/inventory/data/stock/stock_repository.dart';
import '../../features/inventory/data/stock_policy/stock_policy_repository.dart';
import '../../features/inventory/data/costing/costing_repository.dart';
import '../../features/inventory/data/reports/reports_repository.dart';
import '../../features/inventory/data/stocktake/stocktake_repository.dart';
import '../../features/inventory/data/supplier_program/supplier_program_repository.dart';
import '../../features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import '../../features/partner/data/partner_repository.dart';
import '../../features/pricing/data/customer_price_rule_repository.dart';
import '../../features/pricing/data/sales_pricing_repository.dart';
import '../../features/sales/data/return_exchange_repository.dart';
import '../../features/sales/data/sales_cancellation_repository.dart';
import '../../features/sales/data/sales_checkout_repository.dart';
import '../../features/sales/data/sales_draft_repository.dart';
import '../../features/sales/data/sales_order_repository.dart';
import '../../features/sales/data/sales_payment_repository.dart';
import '../../features/sales/data/sales_receipt_repository.dart';
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

  // Ngữ cảnh phiên cho logic sales (IExecutionContext; thay ở 9-1), đọc cùng SessionStore.
  final executionContext = CoreExecutionContext(store: sessionStore);

  getIt
    ..registerSingleton<IExecutionContext>(executionContext)
    ..registerSingleton<ICurrentUser>(executionContext)
    ..registerSingleton<ICurrentTenant>(executionContext);

  getIt
    ..registerLazySingleton<InventoryRpc>(
      () => InventoryRpc(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<WarehouseHubRepository>(
      () => WarehouseHubRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<StockPolicyRepository>(
      () => StockPolicyRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<StockRepository>(
      () => StockRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<SupplierProgramRepository>(
      () => SupplierProgramRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<SupplierRebateRepository>(
      () => SupplierRebateRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<GoodsReceiptRepository>(
      () => GoodsReceiptRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<StocktakeRepository>(
      () => StocktakeRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<CostingRepository>(
      () => CostingRepository(rpc: getIt<InventoryRpc>()),
    )
    ..registerLazySingleton<ReportsRepository>(
      () => ReportsRepository(rpc: getIt<InventoryRpc>()),
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
    )
    ..registerLazySingleton<ProductRepository>(
      () => ProductRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
        hasPermission: (code) => getIt<SessionController>().hasPermission(code),
        signUploadUrl: (key) async =>
            (await supabaseModule.client.storage
                    .from(catalogProductImagesBucket)
                    .createSignedUploadUrl(key))
                .signedUrl,
      ),
    )
    ..registerLazySingleton<MeasurementUnitRepository>(
      () => MeasurementUnitRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<CustomFieldRepository>(
      () => CustomFieldRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<ProductPriceRepository>(
      () => ProductPriceRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<DefaultPairRepository>(
      () => DefaultPairRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<CustomerPriceRuleRepository>(
      () => CustomerPriceRuleRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<SalesPricingRepository>(
      () => SalesPricingRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
      ),
    )
    ..registerLazySingleton<SalesDraftRepository>(
      () => SalesDraftRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<SalesCheckoutRepository>(
      () => SalesCheckoutRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<SalesPaymentRepository>(
      () => SalesPaymentRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<SalesOrderRepository>(
      () => SalesOrderRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<SalesReceiptRepository>(
      () => SalesReceiptRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<SalesCancellationRepository>(
      () => SalesCancellationRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<ReturnExchangeRepository>(
      () => ReturnExchangeRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<EInvoiceProcessorTrigger>(
      () => EInvoiceProcessorTrigger(supabaseModule.client.functions),
    )
    ..registerLazySingleton<EInvoiceConfigurationRepository>(
      () => EInvoiceConfigurationRepository(
        rpc: getIt<SupabaseRpc>(),
        trigger: getIt<EInvoiceProcessorTrigger>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    )
    ..registerLazySingleton<InvoiceDocumentSignedUrls>(
      () => InvoiceDocumentSignedUrls(storage: supabaseModule.client.storage),
    )
    ..registerLazySingleton<EInvoiceRepository>(
      () => EInvoiceRepository(
        rpc: getIt<SupabaseRpc>(),
        trigger: getIt<EInvoiceProcessorTrigger>(),
        signedUrls: getIt<InvoiceDocumentSignedUrls>(),
        tenantId: () => getIt<SessionController>().requireTenantId(),
        actorId: () async =>
            sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired)),
      ),
    );
}
