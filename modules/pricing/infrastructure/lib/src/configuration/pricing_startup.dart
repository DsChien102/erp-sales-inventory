import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../pricing_module.dart';
import 'data_access/data_access_module.dart';
import 'mediation/mediation_module.dart';
import 'pricing_composition_root.dart';
import 'processing/generated/pricing_access_metadata.g.dart';
import 'processing/pricing_query_access_guard.dart';

abstract final class PricingStartup {
  static IPricingModule initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IExecutionContext executionContext,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
  }) => _configure(
    GetIt.asNewInstance(),
    supabase: supabase,
    loggerFactory: loggerFactory,
    executionContext: executionContext,
    permissionChecker: permissionChecker,
    tenantAccessChecker: tenantAccessChecker,
  );

  @visibleForTesting
  static IPricingModule initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IExecutionContext? executionContext,
    IPermissionChecker? permissionChecker,
    ITenantAccessChecker? tenantAccessChecker,
  }) => _configure(
    container ?? GetIt.asNewInstance(),
    supabase: supabase,
    loggerFactory: loggerFactory ?? const NullLoggerFactory(),
    executionContext: executionContext ?? const _TestingExecutionContext(),
    permissionChecker: permissionChecker ?? _AllowAllPermissionChecker(),
    tenantAccessChecker: tenantAccessChecker ?? _AllowAllTenantAccessChecker(),
  );

  static IPricingModule _configure(
    GetIt container, {
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IExecutionContext executionContext,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
  }) {
    final commandLogger = loggerFactory.named('pricing.commands');
    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<IExecutionContext>(executionContext)
      ..registerSingleton<IPermissionChecker>(
        _PricingPermissionChecker(permissionChecker),
      )
      ..registerSingleton<ITenantAccessChecker>(
        _PricingTenantAccessChecker(tenantAccessChecker),
      )
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());
    const PricingDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
    );
    container.registerSingleton<IAccessMetadataRegistry>(
      pricingAccessMetadataRegistry,
    );
    container.registerFactory<SearchCustomerPriceRulesQueryValidator>(
      SearchCustomerPriceRulesQueryValidator.new,
    );
    container.registerFactory<GetCustomerPriceRuleDetailQueryValidator>(
      GetCustomerPriceRuleDetailQueryValidator.new,
    );
    container.registerFactory<GetCustomerPriceRuleHistoryQueryValidator>(
      GetCustomerPriceRuleHistoryQueryValidator.new,
    );
    container.registerFactory<PrecheckCustomerPriceRuleReenableQueryValidator>(
      PrecheckCustomerPriceRuleReenableQueryValidator.new,
    );
    container.registerSingleton<PricingQueryAccessGuard>(
      PricingQueryAccessGuard(
        executionContext: executionContext,
        accessMetadata: container.get<IAccessMetadataRegistry>(),
        permissionChecker: container.get<IPermissionChecker>(),
        tenantAccessChecker: container.get<ITenantAccessChecker>(),
      ),
    );
    const PricingMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );
    PricingCompositionRoot.setContainer(container);
    final module = PricingModule(
      executionContext: executionContext,
      queryAccessGuard: container.get<PricingQueryAccessGuard>(),
    );
    container.registerSingleton<IPricingModule>(module);
    return module;
  }
}

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _AllowAllTenantAccessChecker implements ITenantAccessChecker {
  @override
  Future<void> ensureAccess(String tenantId) async {}
}

final class _TestingExecutionContext implements IExecutionContext {
  const _TestingExecutionContext();

  @override
  String get correlationId => 'pricing-test';

  @override
  Future<String> requireTenantId() async => 'tenant-test';

  @override
  Future<String> requireUserId() async => 'user-test';
}

final class _PricingPermissionChecker implements IPermissionChecker {
  const _PricingPermissionChecker(this._inner);

  final IPermissionChecker _inner;

  @override
  Future<void> require(String permissionCode) async {
    try {
      await _inner.require(permissionCode);
    } on ApplicationException {
      throw PricingBlockedException(
        PricingBlockedCodes.noPermission,
        message: 'Permission denied.',
        details: {'permission': permissionCode},
      );
    }
  }
}

final class _PricingTenantAccessChecker implements ITenantAccessChecker {
  const _PricingTenantAccessChecker(this._inner);

  final ITenantAccessChecker _inner;

  @override
  Future<void> ensureAccess(String tenantId) async {
    try {
      await _inner.ensureAccess(tenantId);
    } on ApplicationException {
      throw const PricingBlockedException(
        PricingBlockedCodes.noPermission,
        message: 'Tenant access denied.',
        details: {'reason': 'tenantAccessDenied'},
      );
    }
  }
}
