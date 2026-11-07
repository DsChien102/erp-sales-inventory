import 'return_exchange_line_input.dart';
import 'sales_contract_enums.dart';

/// Technical recovery snapshot for an in-progress return/exchange.
///
/// Phase 1: not exposed as a user-managed draft list / restore entry point.
final class ReturnExchangeDraftDto {
  ReturnExchangeDraftDto({
    required this.returnExchangeId,
    required this.salesOrderId,
    required this.version,
    required this.status,
    required List<ReturnExchangeLineInput> lines,
  }) : lines = List.unmodifiable(lines);

  final String returnExchangeId;
  final String salesOrderId;
  final int version;
  final ReturnExchangeStatus status;
  final List<ReturnExchangeLineInput> lines;
}
