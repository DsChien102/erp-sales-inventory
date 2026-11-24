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

}
