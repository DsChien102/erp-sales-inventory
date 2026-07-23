import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class PricingQueryAccessGuard {
  const PricingQueryAccessGuard({
    required IExecutionContext executionContext,
    required IAccessMetadataRegistry accessMetadata,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
  }) : _executionContext = executionContext,
       _accessMetadata = accessMetadata,
       _permissionChecker = permissionChecker,
       _tenantAccessChecker = tenantAccessChecker;

  final IExecutionContext _executionContext;
  final IAccessMetadataRegistry _accessMetadata;
  final IPermissionChecker _permissionChecker;
  final ITenantAccessChecker _tenantAccessChecker;

  Future<IQuery<TResult>> bindAndAuthorize<TResult>(
    IQuery<TResult> query,
  ) async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final effectiveQuery = switch (query) {
        SearchCustomerPriceRulesQuery search =>
          search.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
        GetCustomerPriceRuleDetailQuery detail =>
          detail.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
        PrecheckCustomerPriceRuleReenableQuery precheck =>
          precheck.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
        GetCustomerPriceRuleImportTemplateQuery template =>
          template.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
        GetCustomerPriceRuleImportQuery getImport =>
          getImport.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
        GetCustomerPriceRuleHistoryQuery history =>
          history.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
        _ => query,
      };
      final metadata = _accessMetadata.forType(effectiveQuery.runtimeType);
      if (metadata == null) {
        throw const PricingBlockedException(
          PricingBlockedCodes.noPermission,
          message: 'Query access metadata is required.',
        );
      }
      if (metadata.permission case final permission?) {
        await _permissionChecker.require(permission);
      }
      if (metadata.requiresTenant) {
        await _tenantAccessChecker.ensureAccess(tenantId);
      }
      return effectiveQuery;
    } on PricingBlockedException {
      rethrow;
    } on ApplicationException catch (error) {
      if (error.cause != null) {
        throw const PricingBlockedException(
          PricingBlockedCodes.systemError,
          message: 'Pricing access check failed.',
        );
      }
      throw const PricingBlockedException(
        PricingBlockedCodes.noPermission,
        message: 'Execution context is required.',
      );
    }
  }
}
