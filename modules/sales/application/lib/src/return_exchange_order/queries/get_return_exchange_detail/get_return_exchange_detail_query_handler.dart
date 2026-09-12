import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_detail_dto.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import 'get_return_exchange_detail_query.dart';

@QueryHandlerFor(GetReturnExchangeDetailQuery)
final class GetReturnExchangeDetailQueryHandler
    implements IQueryHandler<GetReturnExchangeDetailQuery, ReturnExchangeDetailDto> {
  GetReturnExchangeDetailQueryHandler({
    required IPermissionChecker permissionChecker,
    required IReturnExchangeReadGateway returnExchangeReadGateway,
  }) : _permissionChecker = permissionChecker,
       _returnExchangeReadGateway = returnExchangeReadGateway;

  final IPermissionChecker _permissionChecker;
  final IReturnExchangeReadGateway _returnExchangeReadGateway;

  @override
  Future<ReturnExchangeDetailDto> handle(GetReturnExchangeDetailQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReturnExchange);
    return _returnExchangeReadGateway.getDetail(query);
  }
}
