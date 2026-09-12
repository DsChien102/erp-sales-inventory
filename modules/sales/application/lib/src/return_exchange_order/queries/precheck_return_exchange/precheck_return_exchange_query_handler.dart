import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_precheck_dto.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import 'precheck_return_exchange_query.dart';

@QueryHandlerFor(PrecheckReturnExchangeQuery)
final class PrecheckReturnExchangeQueryHandler
    implements IQueryHandler<PrecheckReturnExchangeQuery, ReturnExchangePrecheckDto> {
  PrecheckReturnExchangeQueryHandler({
    required IPermissionChecker permissionChecker,
    required IReturnExchangeReadGateway returnExchangeReadGateway,
  }) : _permissionChecker = permissionChecker,
       _returnExchangeReadGateway = returnExchangeReadGateway;

  final IPermissionChecker _permissionChecker;
  final IReturnExchangeReadGateway _returnExchangeReadGateway;

  @override
  Future<ReturnExchangePrecheckDto> handle(PrecheckReturnExchangeQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.createReturnExchange);
    return _returnExchangeReadGateway.precheck(query);
  }
}
