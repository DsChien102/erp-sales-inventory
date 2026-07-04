enum ProductBusinessStatus {
  active,
  inactive,
  softDeleted,
}

extension ProductBusinessStatusUi on ProductBusinessStatus {
  String get label => switch (this) {
        ProductBusinessStatus.active => 'Đang KD',
        ProductBusinessStatus.inactive => 'Ngừng KD',
        ProductBusinessStatus.softDeleted => 'Đã xóa',
      };
}
