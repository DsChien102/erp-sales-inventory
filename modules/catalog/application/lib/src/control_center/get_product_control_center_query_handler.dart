import 'package:vet45_shared_application/application.dart';

import '../control_center/product_control_center_assembler.dart';
import '../control_center/product_control_center_dto.dart';
import '../ports/i_catalog_read_gateway.dart';
import '../readiness/product_readiness_permission_resolver.dart';
import 'get_product_control_center_query.dart';

@QueryHandlerFor(GetProductControlCenterQuery)
final class GetProductControlCenterQueryHandler
    implements IQueryHandler<GetProductControlCenterQuery, ProductControlCenterDto> {
  GetProductControlCenterQueryHandler({
    required ICatalogReadGateway readGateway,
    required IPermissionChecker permissionChecker,
  }) : _readGateway = readGateway,
       _permissionChecker = permissionChecker;

  final ICatalogReadGateway _readGateway;
  final IPermissionChecker _permissionChecker;

  @override
  Future<ProductControlCenterDto> handle(
    GetProductControlCenterQuery query,
  ) async {
    final model = await _readGateway.loadControlCenter(
      tenantId: query.tenantId,
      productId: query.productId,
    );

    if (model == null) {
      throw ApplicationException('Product not found');
    }

    final permissions = await ProductReadinessPermissionResolver.resolve(_permissionChecker);
    final includeHistory = await ProductReadinessPermissionResolver.canViewHistory(
      _permissionChecker,
    );

    return ProductControlCenterAssembler.assemble(
      model: model,
      permissions: permissions,
      includeChangeHistory: includeHistory,
    );
  }
}
