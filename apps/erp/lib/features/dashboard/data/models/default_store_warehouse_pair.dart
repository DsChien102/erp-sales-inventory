final class DefaultStoreWarehousePair {
  const DefaultStoreWarehousePair({
    required this.storeId,
    required this.storeName,
    required this.warehouseId,
    required this.warehouseName,
    this.replayed = false,
  });

  factory DefaultStoreWarehousePair.fromJson(Map<String, dynamic> json) {
    return DefaultStoreWarehousePair(
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      warehouseId: json['warehouseId'] as String,
      warehouseName: json['warehouseName'] as String,
      replayed: (json['replayed'] as bool?) ?? false,
    );
  }

  final String storeId;
  final String storeName;
  final String warehouseId;
  final String warehouseName;
  final bool replayed;
}

