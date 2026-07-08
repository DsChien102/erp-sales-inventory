/// Business grouping for product change history entries (EPIC-07/US-04).
enum ProductChangeCategory {
  profile,
  images,
  units,
  stock,
  pricing,
  customFields,
  status,
  lifecycle,
  other,
}

extension ProductChangeCategoryCodec on ProductChangeCategory {
  String get wireValue => switch (this) {
    ProductChangeCategory.profile => 'profile',
    ProductChangeCategory.images => 'images',
    ProductChangeCategory.units => 'units',
    ProductChangeCategory.stock => 'stock',
    ProductChangeCategory.pricing => 'pricing',
    ProductChangeCategory.customFields => 'custom_fields',
    ProductChangeCategory.status => 'status',
    ProductChangeCategory.lifecycle => 'lifecycle',
    ProductChangeCategory.other => 'other',
  };

  static ProductChangeCategory? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return switch (value.trim().toLowerCase()) {
      'profile' => ProductChangeCategory.profile,
      'images' => ProductChangeCategory.images,
      'units' => ProductChangeCategory.units,
      'stock' => ProductChangeCategory.stock,
      'pricing' => ProductChangeCategory.pricing,
      'custom_fields' => ProductChangeCategory.customFields,
      'status' => ProductChangeCategory.status,
      'lifecycle' => ProductChangeCategory.lifecycle,
      'other' => ProductChangeCategory.other,
      _ => null,
    };
  }
}
