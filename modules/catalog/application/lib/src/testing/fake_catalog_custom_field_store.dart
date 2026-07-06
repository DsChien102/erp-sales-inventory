import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'fake_catalog_scenario.dart';

class _StoredCustomFieldOption {
  _StoredCustomFieldOption({
    required this.optionId,
    required this.label,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String optionId;
  String label;
  int sortOrder;
  bool isActive;
}

class _StoredCustomField {
  _StoredCustomField({
    required this.fieldId,
    required this.groupId,
    required this.name,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isSearchable = false,
    this.isFilterable = false,
    this.displayOnList = false,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String fieldId;
  final String groupId;
  String name;
  CustomFieldType fieldType;
  List<_StoredCustomFieldOption> options;
  bool isRequired;
  bool isSearchable;
  bool isFilterable;
  bool displayOnList;
  int sortOrder;
  bool isActive;
}

class _StoredCustomFieldGroup {
  _StoredCustomFieldGroup({
    required this.groupId,
    required this.tenantId,
    required this.name,
    this.iconKey,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String groupId;
  final String tenantId;
  String name;
  String? iconKey;
  int sortOrder;
  bool isActive;
}

class _TemplateFieldSpec {
  const _TemplateFieldSpec({required this.name, required this.fieldType});

  final String name;
  final CustomFieldType fieldType;
}

class _TemplateGroupSpec {
  const _TemplateGroupSpec({
    required this.name,
    this.iconKey,
    this.fields = const [],
  });

  final String name;
  final String? iconKey;
  final List<_TemplateFieldSpec> fields;
}

/// In-memory custom field config store for [FakeCatalogModule].
final class FakeCatalogCustomFieldStore {
  FakeCatalogCustomFieldStore({
    required this.scenario,
    this.productsMissingRequiredCount = 3,
  });

  final String scenario;
  final int productsMissingRequiredCount;

  final List<_StoredCustomFieldGroup> _groups = [];
  final List<_StoredCustomField> _fields = [];
  int _nextGroupId = 1;
  int _nextFieldId = 1;
  int _nextOptionId = 1;

  static const _defaultTemplateId = 'vet_pharmacy_default';

  static const _vetPharmacyTemplate = [
    _TemplateGroupSpec(
      name: 'Thông tin thuốc',
      iconKey: '💊',
      fields: [
        _TemplateFieldSpec(name: 'Thành phần', fieldType: CustomFieldType.text),
        _TemplateFieldSpec(name: 'Chỉ định', fieldType: CustomFieldType.text),
      ],
    ),
    _TemplateGroupSpec(
      name: 'Quy cách & bảo quản',
      fields: [
        _TemplateFieldSpec(name: 'Bảo quản', fieldType: CustomFieldType.text),
      ],
    ),
  ];

  void _assertCustomFieldPermission() {
    if (scenario == FakeCatalogScenario.cfPermissionDenied) {
      throw ApplicationException('Permission denied');
    }
  }

  String _normalizeName(String name) => name.trim().toLowerCase();

  _StoredCustomFieldGroup? _findGroup(String groupId) {
    for (final group in _groups) {
      if (group.groupId == groupId) {
        return group;
      }
    }
    return null;
  }

  _StoredCustomField? _findField(String fieldId) {
    for (final field in _fields) {
      if (field.fieldId == fieldId) {
        return field;
      }
    }
    return null;
  }

  List<_StoredCustomField> _fieldsForGroup(String groupId) {
    return _fields.where((field) => field.groupId == groupId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<_StoredCustomFieldGroup> _groupsForTenant(String tenantId) {
    return _groups.where((group) => group.tenantId == tenantId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  _StoredCustomFieldGroup? _findActiveGroupByName(
    String tenantId,
    String name, {
    String? excludeGroupId,
  }) {
    final normalized = _normalizeName(name);
    for (final group in _groups) {
      if (group.tenantId != tenantId) {
        continue;
      }
      if (!group.isActive) {
        continue;
      }
      if (excludeGroupId != null && group.groupId == excludeGroupId) {
        continue;
      }
      if (_normalizeName(group.name) == normalized) {
        return group;
      }
    }
    return null;
  }

  _StoredCustomField? _findActiveFieldByName(
    String groupId,
    String name, {
    String? excludeFieldId,
  }) {
    final normalized = _normalizeName(name);
    for (final field in _fields) {
      if (field.groupId != groupId) {
        continue;
      }
      if (!field.isActive) {
        continue;
      }
      if (excludeFieldId != null && field.fieldId == excludeFieldId) {
        continue;
      }
      if (_normalizeName(field.name) == normalized) {
        return field;
      }
    }
    return null;
  }

  CustomFieldSelectOptionDto _toOptionDto(_StoredCustomFieldOption option) {
    return CustomFieldSelectOptionDto(
      optionId: option.optionId,
      label: option.label,
      sortOrder: option.sortOrder,
      isActive: option.isActive,
    );
  }

  CustomFieldDefinitionDto _toFieldDto(_StoredCustomField field) {
    return CustomFieldDefinitionDto(
      fieldId: field.fieldId,
      groupId: field.groupId,
      name: field.name,
      fieldType: field.fieldType,
      options: field.options.map(_toOptionDto).toList(),
      isRequired: field.isRequired,
      isSearchable: field.isSearchable,
      isFilterable: field.isFilterable,
      displayOnList: field.displayOnList,
      sortOrder: field.sortOrder,
      status: field.isActive
          ? CustomFieldConfigStatus.active
          : CustomFieldConfigStatus.inactive,
    );
  }

  CustomFieldGroupConfigDto _toGroupDto(_StoredCustomFieldGroup group) {
    final fields = _fieldsForGroup(group.groupId);
    final activeFields = fields.where((field) => field.isActive);
    return CustomFieldGroupConfigDto(
      groupId: group.groupId,
      name: group.name,
      iconKey: group.iconKey,
      sortOrder: group.sortOrder,
      status: group.isActive
          ? CustomFieldConfigStatus.active
          : CustomFieldConfigStatus.inactive,
      fieldCount: activeFields.length,
      requiredFieldCount: activeFields.where((field) => field.isRequired).length,
      fields: fields.map(_toFieldDto).toList(),
    );
  }

  List<CustomFieldGroupCardDto> toActiveGroupCards() {
    final cards = <CustomFieldGroupCardDto>[];
    for (final group in _groups.where((g) => g.isActive)) {
      final fields = _fieldsForGroup(group.groupId)
          .where((field) => field.isActive)
          .map(
            (field) => CustomFieldCardFieldDto(
              fieldId: field.fieldId,
              name: field.name,
              fieldType: field.fieldType.name,
              sortOrder: field.sortOrder,
              isRequired: field.isRequired,
            ),
          )
          .toList();
      cards.add(
        CustomFieldGroupCardDto(
          groupId: group.groupId,
          name: group.name,
          iconKey: group.iconKey,
          sortOrder: group.sortOrder,
          fields: fields,
        ),
      );
    }
    cards.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return cards;
  }

  InitializeCustomFieldTemplateResult initializeTemplate(
    InitializeCustomFieldTemplateCommand command,
  ) {
    _assertCustomFieldPermission();

    final templateId = command.templateId ?? _defaultTemplateId;
    if (templateId != _defaultTemplateId) {
      throw ValidationException('Template not found.');
    }

    var groupsCreated = 0;
    var fieldsCreated = 0;
    var skippedCount = 0;

    for (final spec in _vetPharmacyTemplate) {
      final existingGroup = _findActiveGroupByName(command.tenantId, spec.name);
      late final _StoredCustomFieldGroup group;
      if (existingGroup != null) {
        group = existingGroup;
        skippedCount++;
      } else {
        group = _StoredCustomFieldGroup(
          groupId: 'cf-group-$_nextGroupId',
          tenantId: command.tenantId,
          name: spec.name,
          iconKey: spec.iconKey,
          sortOrder: _groupsForTenant(command.tenantId).length,
        );
        _nextGroupId++;
        _groups.add(group);
        groupsCreated++;
      }

      for (final fieldSpec in spec.fields) {
        final existingField = _findActiveFieldByName(group.groupId, fieldSpec.name);
        if (existingField != null) {
          skippedCount++;
          continue;
        }
        _fields.add(
          _StoredCustomField(
            fieldId: 'cf-field-$_nextFieldId',
            groupId: group.groupId,
            name: fieldSpec.name,
            fieldType: fieldSpec.fieldType,
            sortOrder: _fieldsForGroup(group.groupId).length,
          ),
        );
        _nextFieldId++;
        fieldsCreated++;
      }
    }

    return InitializeCustomFieldTemplateResult(
      groupsCreated: groupsCreated,
      fieldsCreated: fieldsCreated,
      skippedCount: skippedCount,
    );
  }

  CustomFieldGroupConfigDto upsertGroup(UpsertCustomFieldGroupCommand command) {
    _assertCustomFieldPermission();

    final name = command.name.trim();
    if (name.isEmpty) {
      throw ValidationException('Group name must not be empty.');
    }

    if (scenario == FakeCatalogScenario.cfGroupDuplicateName) {
      throw DuplicateCustomFieldGroupNameException(
        name: name,
        existingGroupId: 'cf-group-existing',
      );
    }

    if (command.groupId != null) {
      final group = _findGroup(command.groupId!);
      if (group == null || group.tenantId != command.tenantId) {
        throw CustomFieldGroupNotFoundException(groupId: command.groupId!);
      }
      final duplicate = _findActiveGroupByName(
        command.tenantId,
        name,
        excludeGroupId: group.groupId,
      );
      if (duplicate != null) {
        throw DuplicateCustomFieldGroupNameException(
          name: name,
          existingGroupId: duplicate.groupId,
        );
      }
      group.name = name;
      group.iconKey = command.iconKey;
      group.isActive = command.isActive;
      return _toGroupDto(group);
    }

    final duplicate = _findActiveGroupByName(command.tenantId, name);
    if (duplicate != null) {
      throw DuplicateCustomFieldGroupNameException(
        name: name,
        existingGroupId: duplicate.groupId,
      );
    }

    final group = _StoredCustomFieldGroup(
      groupId: 'cf-group-$_nextGroupId',
      tenantId: command.tenantId,
      name: name,
      iconKey: command.iconKey,
      sortOrder: _groupsForTenant(command.tenantId).length,
      isActive: command.isActive,
    );
    _nextGroupId++;
    _groups.add(group);
    return _toGroupDto(group);
  }

  void reorderGroups(ReorderCustomFieldGroupsCommand command) {
    _assertCustomFieldPermission();

    final tenantGroups = _groupsForTenant(command.tenantId);
    if (command.orderedGroupIds.length != tenantGroups.length) {
      throw ValidationException('Ordered group ids must include all groups.');
    }

    for (var index = 0; index < command.orderedGroupIds.length; index++) {
      final groupId = command.orderedGroupIds[index];
      final group = _findGroup(groupId);
      if (group == null || group.tenantId != command.tenantId) {
        throw CustomFieldGroupNotFoundException(groupId: groupId);
      }
      group.sortOrder = index;
    }
  }

  CustomFieldDefinitionDto upsertField(UpsertCustomFieldCommand command) {
    _assertCustomFieldPermission();

    final group = _findGroup(command.groupId);
    if (group == null || group.tenantId != command.tenantId) {
      throw CustomFieldGroupNotFoundException(groupId: command.groupId);
    }

    final name = command.name.trim();
    if (name.isEmpty) {
      throw ValidationException('Field name must not be empty.');
    }

    if (scenario == FakeCatalogScenario.cfFieldSingleSelectNoOptions &&
        command.fieldType == CustomFieldType.singleSelect &&
        command.options.isEmpty) {
      throw ValidationException('Single select field requires options.');
    }

    if (command.fieldType == CustomFieldType.singleSelect &&
        command.options.isEmpty &&
        command.fieldId == null) {
      throw ValidationException('Single select field requires options.');
    }

    if (command.fieldId != null) {
      final field = _findField(command.fieldId!);
      if (field == null || field.groupId != command.groupId) {
        throw CustomFieldNotFoundException(fieldId: command.fieldId!);
      }
      final duplicate = _findActiveFieldByName(
        command.groupId,
        name,
        excludeFieldId: field.fieldId,
      );
      if (duplicate != null) {
        throw DuplicateCustomFieldNameException(
          name: name,
          groupId: command.groupId,
          existingFieldId: duplicate.fieldId,
        );
      }
      field.name = name;
      field.fieldType = command.fieldType;
      field.isActive = command.isActive;
      field.options = command.options
          .map(
            (option) => _StoredCustomFieldOption(
              optionId: option.optionId.isNotEmpty
                  ? option.optionId
                  : 'cf-option-$_nextOptionId++',
              label: option.label,
              sortOrder: option.sortOrder,
              isActive: option.isActive,
            ),
          )
          .toList();
      return _toFieldDto(field);
    }

    final duplicate = _findActiveFieldByName(command.groupId, name);
    if (duplicate != null) {
      throw DuplicateCustomFieldNameException(
        name: name,
        groupId: command.groupId,
        existingFieldId: duplicate.fieldId,
      );
    }

    final field = _StoredCustomField(
      fieldId: 'cf-field-$_nextFieldId',
      groupId: command.groupId,
      name: name,
      fieldType: command.fieldType,
      sortOrder: _fieldsForGroup(command.groupId).length,
      isActive: command.isActive,
      options: command.options
          .map(
            (option) => _StoredCustomFieldOption(
              optionId: option.optionId.isNotEmpty
                  ? option.optionId
                  : 'cf-option-$_nextOptionId++',
              label: option.label,
              sortOrder: option.sortOrder,
              isActive: option.isActive,
            ),
          )
          .toList(),
    );
    _nextFieldId++;
    _fields.add(field);
    return _toFieldDto(field);
  }

  ConfigureCustomFieldAttributesResult configureAttributes(
    ConfigureCustomFieldAttributesCommand command,
  ) {
    _assertCustomFieldPermission();

    final field = _findField(command.fieldId);
    if (field == null) {
      throw CustomFieldNotFoundException(fieldId: command.fieldId);
    }

    final group = _findGroup(field.groupId);
    if (group == null || group.tenantId != command.tenantId) {
      throw CustomFieldNotFoundException(fieldId: command.fieldId);
    }

    final wasRequired = field.isRequired;
    field.isRequired = command.isRequired;
    field.isSearchable = command.isSearchable;
    field.isFilterable = command.isFilterable;
    field.displayOnList = command.displayOnList;

    final missingCount = !wasRequired && command.isRequired
        ? productsMissingRequiredCount
        : 0;

    return ConfigureCustomFieldAttributesResult(
      field: _toFieldDto(field),
      existingProductsMissingCount: missingCount,
    );
  }

  void reorderFields(ReorderCustomFieldsCommand command) {
    _assertCustomFieldPermission();

    final group = _findGroup(command.groupId);
    if (group == null || group.tenantId != command.tenantId) {
      throw CustomFieldGroupNotFoundException(groupId: command.groupId);
    }

    final groupFields = _fieldsForGroup(command.groupId);
    if (command.orderedFieldIds.length != groupFields.length) {
      throw ValidationException('Ordered field ids must include all fields.');
    }

    for (var index = 0; index < command.orderedFieldIds.length; index++) {
      final fieldId = command.orderedFieldIds[index];
      final field = _findField(fieldId);
      if (field == null || field.groupId != command.groupId) {
        throw CustomFieldNotFoundException(fieldId: fieldId);
      }
      field.sortOrder = index;
    }
  }

  CustomFieldConfigViewDto listConfig(String tenantId) {
    _assertCustomFieldPermission();
    final groups = _groupsForTenant(tenantId).map(_toGroupDto).toList();
    return CustomFieldConfigViewDto(groups: groups);
  }
}
