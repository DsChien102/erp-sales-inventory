import 'opaque_cursor_page_dto.dart';
import 'sales_order_list_facets_dto.dart';
import 'sales_order_list_item_dto.dart';

final class PagedSalesOrderListDto {
  const PagedSalesOrderListDto({
    required this.page,
    this.totalMatching,
    this.facets,
  });

  final OpaqueCursorPageDto<SalesOrderListItemDto> page;
  final int? totalMatching;
  final SalesOrderListFacetsDto? facets;
}
