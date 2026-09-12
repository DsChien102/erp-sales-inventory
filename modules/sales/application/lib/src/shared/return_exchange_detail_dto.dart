import 'return_exchange_detail_line_dto.dart';
import 'return_exchange_result_dto.dart';
import 'return_exchange_settlement_plan_dto.dart';
import 'return_exchange_valuation_dto.dart';
import 'sales_contract_enums.dart';

final class ReturnExchangeDetailDto {
  ReturnExchangeDetailDto({
    required this.result,
    required this.referenceNumber,
    required this.entrySource,
    required this.createdAt,
    required this.confirmedByActorId,
    required this.confirmedAt,
    required this.completedAt,
    required List<ReturnExchangeDetailLineDto> lines,
    required this.valuation,
    required this.settlementPlan,
    required this.completionReady,
  }) : lines = List.unmodifiable(lines);

  final ReturnExchangeResultDto result;
  final String referenceNumber;
  final ReturnExchangeEntrySource? entrySource;
  final DateTime? createdAt;
  final String? confirmedByActorId;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final List<ReturnExchangeDetailLineDto> lines;
  final ReturnExchangeValuationDto valuation;
  final ReturnExchangeSettlementPlanDto settlementPlan;
  final bool completionReady;
}
