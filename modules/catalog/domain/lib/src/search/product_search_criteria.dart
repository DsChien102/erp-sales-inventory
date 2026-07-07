import '../shared/product_status.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'product_readiness_filter.dart';
import 'product_sort_order.dart';
import 'custom_field_filter_criteria.dart';
import 'search_keyword_normalizer.dart';

final class ProductSearchCriteria extends ValueObject {
  ProductSearchCriteria({
    String? keyword,
    Set<ProductStatus>? businessStatuses,
    List<CustomFieldFilterCriteria>? customFieldFilters,
    this.readinessFilter,
    this.includeSoftDeleted = false,
    this.sortOrder = ProductSortOrder.updatedAtDesc,
  }) : keyword = SearchKeywordNormalizer.normalizeKeyword(keyword),
       businessStatuses = businessStatuses == null || businessStatuses.isEmpty
           ? {ProductStatus.active}
           : Set.unmodifiable(businessStatuses),
       customFieldFilters = List.unmodifiable(customFieldFilters ?? const []);

  final String? keyword;
  final Set<ProductStatus> businessStatuses;
  final List<CustomFieldFilterCriteria> customFieldFilters;
  final ProductReadinessFilter? readinessFilter;
  final bool includeSoftDeleted;
  final ProductSortOrder sortOrder;

  bool get activeOnly =>
      businessStatuses.length == 1 && businessStatuses.contains(ProductStatus.active);

  @override
  List<Object?> get props => [
    keyword,
    businessStatuses.toList()..sort((a, b) => a.name.compareTo(b.name)),
    customFieldFilters,
    readinessFilter,
    includeSoftDeleted,
    sortOrder,
  ];
}
