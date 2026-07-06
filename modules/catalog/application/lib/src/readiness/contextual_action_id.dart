/// Stable action ids for readiness contextual actions (EPIC-02/US-03 FR-03).
abstract final class ContextualActionId {
  static const setBaseUnit = 'set_base_unit';
  static const setInitialStock = 'set_initial_stock';
  static const setManualBasePrice = 'set_manual_base_price';
  static const setPriceBand = 'set_price_band';
  static const fillCustomFields = 'fill_custom_fields';
  static const createAnotherProduct = 'create_another_product';
  static const openInventory = 'open_inventory';
  static const openCosting = 'open_costing';
}
