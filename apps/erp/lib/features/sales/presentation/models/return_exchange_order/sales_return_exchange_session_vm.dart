import 'package:vet45_sales_application/application.dart';

final class SalesReturnExchangeSessionVm {
  const SalesReturnExchangeSessionVm({
    required this.salesOrderId,
    required this.orderNumber,
    required this.customerDisplayName,
    required this.sourceOrderVersion,
    required this.returnableLines,
    required this.reasons,
    required this.conditions,
    this.returnExchangeId,
    this.draftVersion,
  });

  final String salesOrderId;
  final String orderNumber;
  final String customerDisplayName;
  final int sourceOrderVersion;
  final List<ReturnableOrderLineDto> returnableLines;
  final List<ReturnExchangePolicyOptionDto> reasons;
  final List<ReturnExchangePolicyOptionDto> conditions;
  final String? returnExchangeId;
  final int? draftVersion;
}
