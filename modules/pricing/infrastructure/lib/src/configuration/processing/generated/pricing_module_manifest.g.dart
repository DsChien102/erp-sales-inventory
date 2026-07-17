// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final pricingModuleManifest = GeneratedModuleManifest(
  name: 'pricing',
  permissions: [
    'pricing.customer_price_rule.create',
    'pricing.customer_price_rule.disable',
    'pricing.customer_price_rule.import',
    'pricing.customer_price_rule.override_floor_price',
    'pricing.customer_price_rule.reenable',
    'pricing.customer_price_rule.save_memory',
    'pricing.customer_price_rule.update',
    'pricing.customer_price_rule.view',
    'pricing.customer_price_rule.view_history',
  ],
  commandTypes: [
    CancelCustomerPriceRuleImportCommand,
    ConfirmCustomerPriceRuleImportCommand,
    CreateCustomerPriceRuleCommand,
    DisableCustomerPriceRuleCommand,
    ReenableCustomerPriceRuleCommand,
    SaveRememberedPriceFromOrderCommand,
    StartCustomerPriceRuleImportCommand,
    UpdateCustomerPriceRuleCommand,
  ],
  queryTypes: [
    GetCustomerPriceRuleDetailQuery,
    GetCustomerPriceRuleHistoryQuery,
    GetCustomerPriceRuleImportQuery,
    GetCustomerPriceRuleImportTemplateQuery,
    PrecheckCustomerPriceRuleReenableQuery,
    SearchCustomerPriceRulesQuery,
  ],
);

