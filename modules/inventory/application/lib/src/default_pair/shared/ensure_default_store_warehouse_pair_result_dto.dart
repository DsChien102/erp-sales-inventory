class EnsureDefaultStoreWarehousePairResultDto {
  const EnsureDefaultStoreWarehousePairResultDto({
    required this.storeId,
    required this.storeName,
    required this.warehouseId,
    required this.warehouseName,
    required this.replayed,
  });

  final String storeId;
  final String storeName;
  final String warehouseId;
  final String warehouseName;
  final bool replayed;
}
