import 'custom_field_card_field_dto.dart';

/// Custom field group card on Product Control Center (EPIC-01/US-02/FR-03).
final class CustomFieldGroupCardDto {
  const CustomFieldGroupCardDto({
    required this.groupId,
    required this.name,
    this.iconKey,
    this.sortOrder = 0,
    this.fields = const [],
    this.hasRequiredMissing = false,
  });

  final String groupId;
  final String name;
  final String? iconKey;
  final int sortOrder;
  final List<CustomFieldCardFieldDto> fields;
  final bool hasRequiredMissing;
}
