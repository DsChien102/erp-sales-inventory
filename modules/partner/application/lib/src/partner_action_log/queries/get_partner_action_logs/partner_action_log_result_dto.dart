import 'partner_action_log_item_dto.dart';

/// Paginated partner action-log result.
final class PartnerActionLogResultDto {
  const PartnerActionLogResultDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<PartnerActionLogItemDto> items;
  final int page;
  final int limit;
  final int total;
}
