import 'partner_list_item_dto.dart';

final class PartnerSearchResultDto {
  const PartnerSearchResultDto({
    required this.items,
    required this.totalCount,
  });

  final List<PartnerListItemDto> items;
  final int totalCount;
}
