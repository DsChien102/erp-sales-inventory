enum ProductReadinessStatus {
  ready,
  missingBaseUnit,
  missingPriceBand,
  missingStockSource,
  needsReview,
}

extension ProductReadinessStatusUi on ProductReadinessStatus {
  String get label => switch (this) {
    ProductReadinessStatus.ready => 'Sẵn sàng bán',
    ProductReadinessStatus.missingBaseUnit => 'Thiếu đơn vị',
    ProductReadinessStatus.missingPriceBand => 'Thiếu giá',
    ProductReadinessStatus.missingStockSource => 'Chưa có nguồn tồn',
    ProductReadinessStatus.needsReview => 'Cần kiểm tra',
  };
}
