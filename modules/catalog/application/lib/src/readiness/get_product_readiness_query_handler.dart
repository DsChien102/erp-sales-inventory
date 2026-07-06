import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_readiness_read_port.dart';
import 'get_product_readiness_query.dart';
import 'product_readiness_permission_context.dart';
import 'product_readiness_view_assembler.dart';
import 'product_readiness_view_dto.dart';

@QueryHandlerFor(GetProductReadinessQuery)
final class GetProductReadinessQueryHandler
    implements
        IQueryHandler<GetProductReadinessQuery, ProductReadinessViewDto> {
  GetProductReadinessQueryHandler({
    required IProductReadinessReadPort readinessReadPort,
    required IPermissionChecker permissionChecker,
  })  : _readinessReadPort = readinessReadPort,
        _permissionChecker = permissionChecker;

  final IProductReadinessReadPort _readinessReadPort;
  final IPermissionChecker _permissionChecker;

  @override
  Future<ProductReadinessViewDto> handle(GetProductReadinessQuery query) async {
    final facts = await _readinessReadPort.loadFacts(
      tenantId: query.tenantId,
      productId: query.productId,
    );

    if (facts == null) {
      throw ApplicationException('Product not found');
    }

    final readiness = ProductReadinessEvaluator.compute(facts);
    final permissions = await _resolvePermissions();

    return ProductReadinessViewAssembler.assemble(
      facts: facts,
      readiness: readiness,
      permissions: permissions,
    );
  }

  Future<ProductReadinessPermissionContext> _resolvePermissions() async {
    return ProductReadinessPermissionContext(
      canManageUnits: await _can(CatalogPermissions.manageUnits),
      canManageStock: await _can(CatalogPermissions.manageStock),
      canManagePricing: await _can(CatalogPermissions.managePricing),
      canUpdateProduct: await _can(CatalogPermissions.update),
      canCreateProduct: await _can(CatalogPermissions.create),
      canViewDetail: await _can(CatalogPermissions.viewDetail),
    );
  }

  Future<bool> _can(String permissionCode) async {
    try {
      await _permissionChecker.require(permissionCode);
      return true;
    } on ApplicationException {
      return false;
    }
  }
}
