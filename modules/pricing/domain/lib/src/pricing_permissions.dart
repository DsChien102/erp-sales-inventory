/// Pricing-owned permission codes used by access metadata and database checks.
abstract final class PricingPermissions {
  static const viewCustomerPriceRule = 'pricing.customer_price_rule.view';
  static const createCustomerPriceRule = 'pricing.customer_price_rule.create';
  static const updateCustomerPriceRule = 'pricing.customer_price_rule.update';
  static const disableCustomerPriceRule = 'pricing.customer_price_rule.disable';
  static const reenableCustomerPriceRule =
      'pricing.customer_price_rule.reenable';
  static const overrideFloorPrice =
      'pricing.customer_price_rule.override_floor_price';
  static const importCustomerPriceRule = 'pricing.customer_price_rule.import';
  static const savePriceMemory = 'pricing.customer_price_rule.save_memory';
  static const viewCustomerPriceRuleHistory =
      'pricing.customer_price_rule.view_history';
}
