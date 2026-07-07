/// Select option for single-select custom fields (EPIC-03/US-01).
final class CustomFieldSelectOptionDto {
  const CustomFieldSelectOptionDto({
    required this.optionId,
    required this.label,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String optionId;
  final String label;
  final int sortOrder;
  final bool isActive;
}
