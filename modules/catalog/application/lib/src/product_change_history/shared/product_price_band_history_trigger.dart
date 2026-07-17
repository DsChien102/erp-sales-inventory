enum ProductPriceBandHistoryTrigger {
  direct,
  basePriceChanged,
  storeRuleChanged;

  static ProductPriceBandHistoryTrigger? tryParse(String? raw) {
    return switch (raw) {
      'direct' => ProductPriceBandHistoryTrigger.direct,
      'basePriceChanged' => ProductPriceBandHistoryTrigger.basePriceChanged,
      'storeRuleChanged' => ProductPriceBandHistoryTrigger.storeRuleChanged,
      _ => null,
    };
  }
}
