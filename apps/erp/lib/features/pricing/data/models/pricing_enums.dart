enum CustomerPriceRuleStatus { active, disabled, needsReview, deleted }

enum CustomerPriceRuleSourceType { manual, excelImport, salesOrder, migration }

enum CustomerPriceRuleType { specialPrice, rememberedPrice }

enum CustomerPriceRuleDerivedStatus {
  applying,
  notYetEffective,
  disabled,
  expired,
  needsReview,
  deleted,
}

enum CustomerPriceRuleQuickFilter { all, applying, belowFloor }

enum CustomerPriceRuleActivityType {
  created,
  updated,
  disabled,
  reenabled,
  deleted,
  importCreated,
  importUpdated,
  memoryCreated,
  memoryUpdated,
}

enum CustomerPriceRuleReferenceState { valid, inactive, missing }

enum CustomerPriceRulePriceBandState {
  current,
  currencyMismatch,
  invalidMinorUnits,
  unavailable,
}

