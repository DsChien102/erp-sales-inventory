/// Custom field filter option models and parsers.
library;

/// Formats a custom field group name for display without changing stored data.
String customFieldGroupDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final firstRune = String.fromCharCode(trimmed.runes.first).toUpperCase();
  final remainingRunes = String.fromCharCodes(trimmed.runes.skip(1));
  return '$firstRune$remainingRunes';
}

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

  factory CustomFieldSelectOptionDto.fromJson(Map<String, dynamic> row) {
    return CustomFieldSelectOptionDto(
      optionId: row['option_id'] as String,
      label: row['label'] as String,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

final class CustomFieldFilterOptionDto {
  const CustomFieldFilterOptionDto({
    required this.fieldId,
    required this.groupId,
    required this.groupName,
    required this.fieldName,
    required this.fieldType,
    required this.options,
    required this.sortOrder,
  });

  final String fieldId;
  final String groupId;
  final String groupName;
  final String fieldName;
  final String fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final int sortOrder;

  factory CustomFieldFilterOptionDto.fromJson(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = optionsRaw is List
        ? optionsRaw
            .whereType<Map>()
            .map((item) => CustomFieldSelectOptionDto.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <CustomFieldSelectOptionDto>[];

    return CustomFieldFilterOptionDto(
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      groupName: customFieldGroupDisplayName(row['group_name'] as String),
      fieldName: row['field_name'] as String,
      fieldType: row['field_type'] as String,
      options: options,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static List<CustomFieldFilterOptionDto> listFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => CustomFieldFilterOptionDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

