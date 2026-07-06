import '../control_center/product_control_center_dto.dart';
import '../product_search/product_list_item_dto.dart';
import '../product_search/product_search_result_dto.dart';
import 'package:vet45_catalog_domain/domain.dart';

/// Read gateway for catalog list and control-center projections (EPIC-01).
abstract interface class ICatalogReadGateway {
  Future<ProductSearchResultDto> search({
    required String tenantId,
    required ProductSearchCriteria criteria,
    required int limit,
    required int offset,
  });

  Future<ProductListItemDto?> findByBarcode({
    required String tenantId,
    required String barcode,
  });

  Future<ProductControlCenterDto> getControlCenter({
    required String tenantId,
    required String productId,
  });
}
