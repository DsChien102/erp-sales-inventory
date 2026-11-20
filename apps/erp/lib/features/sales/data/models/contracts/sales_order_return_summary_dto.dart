import 'return_exchange_summary_dto.dart';

final class SalesOrderReturnSummaryDto {
  SalesOrderReturnSummaryDto({
    required this.salesOrderId,
    required List<ReturnExchangeSummaryDto> returns,
  }) : returns = List.unmodifiable(returns);

  final String salesOrderId;
  final List<ReturnExchangeSummaryDto> returns;
}
