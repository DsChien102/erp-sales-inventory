import 'opaque_cursor_page_dto.dart';
import 'sales_order_draft_dto.dart';

final class PagedSalesOrderDraftListDto {
  const PagedSalesOrderDraftListDto({required this.page});

  final OpaqueCursorPageDto<SalesOrderDraftDto> page;
}
