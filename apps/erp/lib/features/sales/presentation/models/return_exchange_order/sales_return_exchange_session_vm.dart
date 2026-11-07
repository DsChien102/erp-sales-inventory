import 'package:vet45_sales_application/application.dart';

final class SalesReturnExchangeSessionVm {
  const SalesReturnExchangeSessionVm({
    required this.salesOrderId,
    required this.orderNumber,
    required this.customerDisplayName,
    required this.sourceOrderVersion,
    required this.returnableLines,
    this.returnExchangeId,
    this.draftVersion,
  });

  final String salesOrderId;
  final String orderNumber;
  final String customerDisplayName;
  final int sourceOrderVersion;
  final List<ReturnableOrderLineDto> returnableLines;
  final String? returnExchangeId;
  final int? draftVersion;
}
