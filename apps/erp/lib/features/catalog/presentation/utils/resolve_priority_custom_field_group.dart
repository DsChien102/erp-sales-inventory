import '../../data/models.dart';

/// Picks the next custom-field group to open from readiness "Cập nhật trường".
///
/// Prefers groups with [CustomFieldGroupCardDto.hasRequiredMissing], ordered by
/// [CustomFieldGroupCardDto.sortOrder] (settings order, top → bottom).
String? resolvePriorityCustomFieldGroupId(
  Iterable<CustomFieldGroupCardDto> groups,
) {
  if (groups.isEmpty) return null;

  final ordered = List<CustomFieldGroupCardDto>.of(groups)
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  for (final group in ordered) {
    if (group.hasRequiredMissing) {
      return group.groupId;
    }
  }

  return null;
}
