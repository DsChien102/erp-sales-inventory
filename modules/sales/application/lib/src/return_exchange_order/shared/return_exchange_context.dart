import '../../shared/return_exchange_draft_dto.dart';

final class ReturnExchangeContext {
  ReturnExchangeContext({
    required this.draft,
    required this.currencyCode,
    required this.sourceOrderVersion,
    required this.sourceSettlementVersion,
    required List<String> reservationIds,
  }) : reservationIds = List.unmodifiable(reservationIds);

  final ReturnExchangeDraftDto draft;
  final String currencyCode;
  final int sourceOrderVersion;
  final int sourceSettlementVersion;
  final List<String> reservationIds;
}
