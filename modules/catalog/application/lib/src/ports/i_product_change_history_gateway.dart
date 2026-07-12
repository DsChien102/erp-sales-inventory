import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_category.dart';
import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_page.dart';

abstract interface class IProductChangeHistoryGateway {
  Future<ProductChangeHistoryPage> listHistory({
    required String tenantId,
    required String productId,
    required int limit,
    required int offset,
    List<ProductChangeCategory> changeCategories,
  });
}
