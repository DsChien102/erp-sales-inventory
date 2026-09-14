import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_receipt_dto.dart';
import '../../ports/i_sales_receipt_gateway.dart';
import 'archive_sales_receipt_command.dart';

@CommandHandlerFor(ArchiveSalesReceiptCommand)
final class ArchiveSalesReceiptCommandHandler
    implements ICommandHandler<ArchiveSalesReceiptCommand, SalesReceiptDto> {
  ArchiveSalesReceiptCommandHandler({required ISalesReceiptGateway receiptGateway})
    : _receiptGateway = receiptGateway;

  final ISalesReceiptGateway _receiptGateway;

  @override
  Future<SalesReceiptDto> handle(ArchiveSalesReceiptCommand command) =>
      _receiptGateway.archive(command);
}
