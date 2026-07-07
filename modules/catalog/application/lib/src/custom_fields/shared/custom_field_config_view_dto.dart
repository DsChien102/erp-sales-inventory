import '../shared/custom_field_group_config_dto.dart';

/// Tenant custom field configuration view (EPIC-03/US-01).
final class CustomFieldConfigViewDto {
  const CustomFieldConfigViewDto({required this.groups});

  final List<CustomFieldGroupConfigDto> groups;
}
