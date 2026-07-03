import 'partner_transaction_history_item_dto.dart';

final class PartnerTransactionHistoryResultDto {
  const PartnerTransactionHistoryResultDto({
    required this.items,
    required this.totalCount,
  });

  final List<PartnerTransactionHistoryItemDto> items;
  final int totalCount;
}
