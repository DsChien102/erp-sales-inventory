import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_receipt_dto.dart';
import '../../ports/i_sales_receipt_gateway.dart';
import 'get_sales_receipt_query.dart';

@QueryHandlerFor(GetSalesReceiptQuery)
final class GetSalesReceiptQueryHandler
    implements IQueryHandler<GetSalesReceiptQuery, SalesReceiptDto> {
  GetSalesReceiptQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesReceiptGateway receiptGateway,
  }) : _permissionChecker = permissionChecker,
       _receiptGateway = receiptGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesReceiptGateway _receiptGateway;

  @override
  Future<SalesReceiptDto> handle(GetSalesReceiptQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReceipt);
    return _receiptGateway.getReceipt(query);
  }
}
