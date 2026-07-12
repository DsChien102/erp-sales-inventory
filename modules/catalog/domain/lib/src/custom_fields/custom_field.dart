import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'custom_field_config_status.dart';
import 'custom_field_type.dart';
import 'rules/custom_field_name_required_rule.dart';
import 'rules/single_select_must_have_options_rule.dart';

/// Tenant-configurable custom field (Trường thông tin) within a group.
final class CustomField extends Entity<String> implements IAggregateRoot {
  CustomField._({
    required super.id,
    required this.groupId,
    required this.tenantId,
    required this.name,
    required this.fieldType,
    required this.status,
    required this.sortOrder,
    required this.isRequired,
    required this.isSearchable,
    required this.isFilterable,
    required this.displayOnList,
    this.options = const [],
  });

  final String groupId;
  final String tenantId;
  final String name;
  final CustomFieldType fieldType;
  final CustomFieldConfigStatus status;
  final int sortOrder;
  final bool isRequired;
  final bool isSearchable;
  final bool isFilterable;
  final bool displayOnList;
  final List<String> options;

  factory CustomField.create({
    required String id,
    required String groupId,
    required String tenantId,
    required String name,
    required CustomFieldType fieldType,
    int sortOrder = 0,
    bool isRequired = false,
    bool isSearchable = false,
    bool isFilterable = false,
    bool displayOnList = false,
    List<String> options = const [],
  }) {
    final trimmed = name.trim();
    final field = CustomField._(
      id: id,
      groupId: groupId,
      tenantId: tenantId,
      name: trimmed,
      fieldType: fieldType,
      status: CustomFieldConfigStatus.active,
      sortOrder: sortOrder,
      isRequired: isRequired,
      isSearchable: isSearchable,
      isFilterable: isFilterable,
      displayOnList: displayOnList,
      options: List.unmodifiable(options),
    );
    field.checkRule(CustomFieldNameRequiredRule(trimmed));
    field.checkRule(
      SingleSelectMustHaveOptionsRule(
        fieldType: fieldType,
        options: options,
      ),
    );
    return field;
  }

  factory CustomField.reconstitute({
    required String id,
    required String groupId,
    required String tenantId,
    required String name,
    required CustomFieldType fieldType,
    required CustomFieldConfigStatus status,
    required int sortOrder,
    required bool isRequired,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
    List<String> options = const [],
  }) {
    return CustomField._(
      id: id,
      groupId: groupId,
      tenantId: tenantId,
      name: name,
      fieldType: fieldType,
      status: status,
      sortOrder: sortOrder,
      isRequired: isRequired,
      isSearchable: isSearchable,
      isFilterable: isFilterable,
      displayOnList: displayOnList,
      options: List.unmodifiable(options),
    );
  }

  CustomField rename(String name) {
    final trimmed = name.trim();
    checkRule(CustomFieldNameRequiredRule(trimmed));
    return _copy(name: trimmed);
  }

  CustomField configureAttributes({
    bool? isRequired,
    bool? isSearchable,
    bool? isFilterable,
    bool? displayOnList,
  }) {
    return _copy(
      isRequired: isRequired ?? this.isRequired,
      isSearchable: isSearchable ?? this.isSearchable,
      isFilterable: isFilterable ?? this.isFilterable,
      displayOnList: displayOnList ?? this.displayOnList,
    );
  }

  CustomField replaceOptions(List<String> options) {
    checkRule(
      SingleSelectMustHaveOptionsRule(
        fieldType: fieldType,
        options: options,
      ),
    );
    return _copy(options: List.unmodifiable(options));
  }

  CustomField reorder(int sortOrder) => _copy(sortOrder: sortOrder);

  CustomField deactivate() => _copy(status: CustomFieldConfigStatus.inactive);

  CustomField reactivate() => _copy(status: CustomFieldConfigStatus.active);

  CustomField _copy({
    String? name,
    CustomFieldConfigStatus? status,
    int? sortOrder,
    bool? isRequired,
    bool? isSearchable,
    bool? isFilterable,
    bool? displayOnList,
    List<String>? options,
  }) {
    return CustomField._(
      id: id,
      groupId: groupId,
      tenantId: tenantId,
      name: name ?? this.name,
      fieldType: fieldType,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      isRequired: isRequired ?? this.isRequired,
      isSearchable: isSearchable ?? this.isSearchable,
      isFilterable: isFilterable ?? this.isFilterable,
      displayOnList: displayOnList ?? this.displayOnList,
      options: options ?? this.options,
    );
  }
}
