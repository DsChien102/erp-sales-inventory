import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_pricing_domain/domain.dart';

@ModuleManifest(
  name: 'pricing',
  permissions: [
    PricingPermissions.viewCustomerPriceRule,
    PricingPermissions.createCustomerPriceRule,
    PricingPermissions.updateCustomerPriceRule,
    PricingPermissions.disableCustomerPriceRule,
    PricingPermissions.reenableCustomerPriceRule,
    PricingPermissions.overrideFloorPrice,
    PricingPermissions.importCustomerPriceRule,
    PricingPermissions.savePriceMemory,
    PricingPermissions.viewCustomerPriceRuleHistory,
  ],
)
final class PricingModuleDefinition {}
