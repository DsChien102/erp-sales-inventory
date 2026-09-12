import 'package:vet45_shared_application/application.dart';

import '../../ports/i_sales_order_draft_gateway.dart';
import '../../../shared/sales_order_draft_dto.dart';
import 'save_sales_order_draft_command.dart';

@CommandHandlerFor(SaveSalesOrderDraftCommand)
final class SaveSalesOrderDraftCommandHandler
    implements ICommandHandler<SaveSalesOrderDraftCommand, SalesOrderDraftDto> {
  SaveSalesOrderDraftCommandHandler({required ISalesOrderDraftGateway gateway})
    : _gateway = gateway;

  final ISalesOrderDraftGateway _gateway;

  @override
  Future<SalesOrderDraftDto> handle(SaveSalesOrderDraftCommand command) {
    return _gateway.save(command);
  }
}
