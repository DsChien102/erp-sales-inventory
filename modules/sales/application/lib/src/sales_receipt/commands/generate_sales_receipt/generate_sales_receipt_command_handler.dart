import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_receipt_dto.dart';
import '../../ports/i_sales_receipt_gateway.dart';
import 'generate_sales_receipt_command.dart';

@CommandHandlerFor(GenerateSalesReceiptCommand)
final class GenerateSalesReceiptCommandHandler
    implements ICommandHandler<GenerateSalesReceiptCommand, SalesReceiptDto> {
  GenerateSalesReceiptCommandHandler({required ISalesReceiptGateway receiptGateway})
    : _receiptGateway = receiptGateway;

  final ISalesReceiptGateway _receiptGateway;

  @override
  Future<SalesReceiptDto> handle(GenerateSalesReceiptCommand command) =>
      _receiptGateway.generate(command);
}
