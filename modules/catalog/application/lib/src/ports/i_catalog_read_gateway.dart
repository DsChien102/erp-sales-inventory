import 'package:vet45_catalog_application/src/product/queries/get_product_control_center/product_control_center_read_model.dart';
import 'package:vet45_catalog_application/src/product/queries/list_custom_field_filter_options/custom_field_filter_option_dto.dart';
import 'package:vet45_catalog_application/src/product/queries/search_products/product_list_item_dto.dart';
import 'package:vet45_catalog_application/src/product/queries/search_products/product_search_result_dto.dart';
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

  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  });

  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  });
}
