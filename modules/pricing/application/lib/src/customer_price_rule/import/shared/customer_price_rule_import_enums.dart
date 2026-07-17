enum CustomerPriceRuleImportMode { createOnly, updateOnly, upsert }

enum CustomerPriceRuleImportStatus {
  failed,
  readyToImport,
  completed,
  completedWithErrors,
  canceled,
}

enum CustomerPriceRuleImportRowStatus {
  valid,
  warning,
  error,
  imported,
  skipped,
  failed,
}

enum CustomerPriceRuleImportAction { create, update, skip }

enum ProductUnitResolutionStrategy { defaultSellingUnit, ambiguous, notFound }
