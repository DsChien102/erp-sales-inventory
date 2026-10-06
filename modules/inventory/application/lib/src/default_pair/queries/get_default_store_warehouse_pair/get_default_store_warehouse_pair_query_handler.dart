import 'package:vet45_inventory_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../ports/i_default_store_warehouse_pair_port.dart';
import '../../shared/default_store_warehouse_pair_dto.dart';
import 'get_default_store_warehouse_pair_query.dart';

@QueryHandlerFor(GetDefaultStoreWarehousePairQuery)
final class GetDefaultStoreWarehousePairQueryHandler
    implements IQueryHandler<GetDefaultStoreWarehousePairQuery, DefaultStoreWarehousePairDto> {
  GetDefaultStoreWarehousePairQueryHandler({
    required IPermissionChecker permissionChecker,
    required IExecutionContext executionContext,
    required IDefaultStoreWarehousePairPort defaultStoreWarehousePairPort,
  }) : _permissionChecker = permissionChecker,
       _executionContext = executionContext,
       _port = defaultStoreWarehousePairPort;

  final IPermissionChecker _permissionChecker;
  final IExecutionContext _executionContext;
  final IDefaultStoreWarehousePairPort _port;

  @override
  Future<DefaultStoreWarehousePairDto> handle(
    GetDefaultStoreWarehousePairQuery query,
  ) async {
    await _permissionChecker.require(InventoryPermissions.defaultPairRead);
    final tenantId = await _executionContext.requireTenantId();
    return _port.get(tenantId: tenantId);
  }
}
