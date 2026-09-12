import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_form_policy_dto.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import 'get_return_exchange_form_policy_query.dart';

@QueryHandlerFor(GetReturnExchangeFormPolicyQuery)
final class GetReturnExchangeFormPolicyQueryHandler
    implements IQueryHandler<GetReturnExchangeFormPolicyQuery, ReturnExchangeFormPolicyDto> {
  GetReturnExchangeFormPolicyQueryHandler({
    required IPermissionChecker permissionChecker,
    required IReturnExchangeReadGateway returnExchangeReadGateway,
  }) : _permissionChecker = permissionChecker,
       _returnExchangeReadGateway = returnExchangeReadGateway;

  final IPermissionChecker _permissionChecker;
  final IReturnExchangeReadGateway _returnExchangeReadGateway;

  @override
  Future<ReturnExchangeFormPolicyDto> handle(
    GetReturnExchangeFormPolicyQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.createReturnExchange);
    return _returnExchangeReadGateway.getFormPolicy(query);
  }
}
