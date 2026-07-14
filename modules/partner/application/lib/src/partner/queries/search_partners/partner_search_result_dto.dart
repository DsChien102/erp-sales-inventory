import 'partner_list_item_dto.dart';

/// Paginated partner search result.
final class PartnerSearchResultDto {
  const PartnerSearchResultDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<PartnerListItemDto> items;
  final int page;
  final int limit;
  final int total;
}
