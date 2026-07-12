import 'store_price_rule_change_history_entry_dto.dart';

/// Kết quả phân trang lịch sử Store Price Rule.
final class StorePriceRuleChangeHistoryResultDto {
  const StorePriceRuleChangeHistoryResultDto({
    required this.items,
    required this.totalCount,
  });

  final List<StorePriceRuleChangeHistoryEntryDto> items;
  final int totalCount;
}
