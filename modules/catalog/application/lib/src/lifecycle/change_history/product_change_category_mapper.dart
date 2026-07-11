import 'product_change_category.dart';
import 'product_change_history_action.dart';

/// Maps persisted change-history action codes to business categories.
abstract final class ProductChangeCategoryMapper {
  static ProductChangeCategory fromAction(String action) {
    return ProductChangeHistoryAction.tryParse(action)?.category ??
        ProductChangeCategory.other;
  }
}
