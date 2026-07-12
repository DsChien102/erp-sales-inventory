import 'package:vet45_catalog_domain/domain.dart';

import 'custom_field_definition_dto.dart';

/// Custom field group in tenant config (EPIC-03/US-01).
final class CustomFieldGroupConfigDto {
  const CustomFieldGroupConfigDto({
    required this.groupId,
    required this.name,
    this.iconKey,
    this.sortOrder = 0,
    this.status = CustomFieldConfigStatus.active,
    this.fieldCount = 0,
    this.requiredFieldCount = 0,
    this.fields = const [],
  });

  final String groupId;
  final String name;
  final String? iconKey;
  final int sortOrder;
  final CustomFieldConfigStatus status;
  final int fieldCount;
  final int requiredFieldCount;
  final List<CustomFieldDefinitionDto> fields;
}
