import '../shared/default_store_warehouse_pair_dto.dart';
import '../shared/ensure_default_store_warehouse_pair_result_dto.dart';

abstract interface class IDefaultStoreWarehousePairPort {
  Future<EnsureDefaultStoreWarehousePairResultDto> ensure({
    required String tenantId,
    required String correlationId,
  });

  Future<DefaultStoreWarehousePairDto> get({required String tenantId});

  Future<void> matches({
    required String tenantId,
    required String storeId,
    required String warehouseId,
  });
}
