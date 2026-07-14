import 'partner_history_item_dto.dart';

/// Paginated partner history result.
final class PartnerHistoryResultDto {
  const PartnerHistoryResultDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<PartnerHistoryItemDto> items;
  final int page;
  final int limit;
  final int total;
}
