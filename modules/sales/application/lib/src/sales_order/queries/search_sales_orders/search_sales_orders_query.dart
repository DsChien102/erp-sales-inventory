import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/paged_sales_order_list_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_list_filter_input.dart';

@RequiresPermission(SalesPermissions.viewOrder)
@RequiresTenant()
final class SearchSalesOrdersQuery extends SalesReadContract<PagedSalesOrderListDto> {
  SearchSalesOrdersQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.searchText,
    this.cursor,
    this.pageSize = 25,
    this.filter,
  });

  final String searchText;
  final String? cursor;
  final int pageSize;
  final SalesOrderListFilterInput? filter;

  SearchSalesOrdersQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => SearchSalesOrdersQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    searchText: searchText,
    cursor: cursor,
    pageSize: pageSize,
    filter: filter,
  );
}
