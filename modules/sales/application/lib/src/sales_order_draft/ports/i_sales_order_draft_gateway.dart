import '../../shared/paged_sales_order_draft_list_dto.dart';
import '../../shared/sales_order_draft_dto.dart';
import '../../shared/sales_order_draft_for_restore_dto.dart';
import '../commands/cancel_sales_order_draft/cancel_sales_order_draft_command.dart';
import '../commands/save_sales_order_draft/save_sales_order_draft_command.dart';
import '../commands/update_sales_order_draft/update_sales_order_draft_command.dart';
import '../queries/get_sales_order_draft_for_restore/get_sales_order_draft_for_restore_query.dart';
import '../queries/list_sales_order_drafts/list_sales_order_drafts_query.dart';

abstract interface class ISalesOrderDraftGateway {
  Future<SalesOrderDraftDto> save(SaveSalesOrderDraftCommand command);

  Future<SalesOrderDraftDto> update(UpdateSalesOrderDraftCommand command);

  Future<SalesOrderDraftDto> cancel(CancelSalesOrderDraftCommand command);

  Future<SalesOrderDraftForRestoreDto> getForRestore(
    GetSalesOrderDraftForRestoreQuery query,
  );

  Future<PagedSalesOrderDraftListDto> list(ListSalesOrderDraftsQuery query);
}
