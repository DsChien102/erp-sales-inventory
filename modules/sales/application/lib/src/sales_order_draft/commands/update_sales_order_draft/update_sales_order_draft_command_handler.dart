import 'package:vet45_shared_application/application.dart';

import '../../ports/i_sales_order_draft_gateway.dart';
import '../../../shared/sales_order_draft_dto.dart';
import 'update_sales_order_draft_command.dart';

@CommandHandlerFor(UpdateSalesOrderDraftCommand)
final class UpdateSalesOrderDraftCommandHandler
    implements ICommandHandler<UpdateSalesOrderDraftCommand, SalesOrderDraftDto> {
  UpdateSalesOrderDraftCommandHandler({required ISalesOrderDraftGateway gateway})
    : _gateway = gateway;

  final ISalesOrderDraftGateway _gateway;

  @override
  Future<SalesOrderDraftDto> handle(UpdateSalesOrderDraftCommand command) {
    return _gateway.update(command);
  }
}
