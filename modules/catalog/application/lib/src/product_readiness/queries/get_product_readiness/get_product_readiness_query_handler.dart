import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_readiness_read_port.dart';
import 'get_product_readiness_query.dart';
import 'package:vet45_catalog_application/src/product_readiness/shared/product_readiness_permission_context.dart';
import 'package:vet45_catalog_application/src/product_readiness/shared/product_readiness_permission_resolver.dart';
import 'package:vet45_catalog_application/src/product_readiness/shared/product_readiness_view_assembler.dart';
import 'product_readiness_view_dto.dart';

@QueryHandlerFor(GetProductReadinessQuery)
final class GetProductReadinessQueryHandler
    implements IQueryHandler<GetProductReadinessQuery, ProductReadinessViewDto> {
  GetProductReadinessQueryHandler({
    required IProductReadinessReadPort readinessReadPort,
    required IPermissionChecker permissionChecker,
  }) : _readinessReadPort = readinessReadPort,
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

  Future<ProductReadinessPermissionContext> _resolvePermissions() {
    return ProductReadinessPermissionResolver.resolve(_permissionChecker);
  }
}
