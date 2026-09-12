import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/returnable_order_lines_dto.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import 'get_returnable_order_lines_query.dart';

@QueryHandlerFor(GetReturnableOrderLinesQuery)
final class GetReturnableOrderLinesQueryHandler
    implements IQueryHandler<GetReturnableOrderLinesQuery, ReturnableOrderLinesDto> {
  GetReturnableOrderLinesQueryHandler({
    required IPermissionChecker permissionChecker,
    required IReturnExchangeReadGateway returnExchangeReadGateway,
  }) : _permissionChecker = permissionChecker,
       _returnExchangeReadGateway = returnExchangeReadGateway;

  final IPermissionChecker _permissionChecker;
  final IReturnExchangeReadGateway _returnExchangeReadGateway;

  @override
  Future<ReturnableOrderLinesDto> handle(GetReturnableOrderLinesQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReturnExchange);
    return _returnExchangeReadGateway.getReturnableLines(query);
  }
}
