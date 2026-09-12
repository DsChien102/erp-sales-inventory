/// Saved-search quick chips on SG-07 list (Figma).
enum SalesOrderSavedSearchPreset {
  all,
  outstandingReceivable,
  eInvoicePending,
}

extension SalesOrderSavedSearchPresetX on SalesOrderSavedSearchPreset {
  String get label {
    return switch (this) {
      SalesOrderSavedSearchPreset.all => 'Tất cả',
      SalesOrderSavedSearchPreset.outstandingReceivable => 'Còn phải thu',
      SalesOrderSavedSearchPreset.eInvoicePending => 'Chưa phát hành HĐĐT',
    };
  }

  /// Chip label with count — only shows count when count > 0 (SG-07 Figma).
  String labelWithCount(int count) => count > 0 ? '$label ($count)' : label;
}
