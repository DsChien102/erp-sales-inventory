import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class ReadyDefaultPairInventoryModule implements IInventoryModule {
  const ReadyDefaultPairInventoryModule();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    return const EnsureDefaultStoreWarehousePairResultDto(
          storeId: 'store-ready',
          storeName: 'Default Store',
          warehouseId: 'wh-ready',
          warehouseName: 'Kho mặc định',
          replayed: true,
        )
        as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return const DefaultStoreWarehousePairDto(
          storeId: 'store-ready',
          storeName: 'Default Store',
          warehouseId: 'wh-ready',
          warehouseName: 'Kho mặc định',
        )
        as TResult;
  }
}
