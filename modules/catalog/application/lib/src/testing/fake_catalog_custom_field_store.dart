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

class _StoredProductCustomFieldValue {
  _StoredProductCustomFieldValue({
    required this.productId,
    required this.fieldId,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
    this.optionId,
  });

  final String productId;
  final String fieldId;
  String? textValue;
  double? numberValue;
  DateTime? dateValue;
  bool? booleanValue;
  String? optionId;

  bool get isEmpty =>
      (textValue == null || textValue!.trim().isEmpty) &&
      numberValue == null &&
      dateValue == null &&
      booleanValue == null &&
      (optionId == null || optionId!.trim().isEmpty);
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
  final Map<String, _StoredProductCustomFieldValue> _productValues = {};
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

  String _valueKey(String productId, String fieldId) => '$productId::$fieldId';

  _StoredProductCustomFieldValue? _findValue(String productId, String fieldId) {
    return _productValues[_valueKey(productId, fieldId)];
  }

  String? _displayValue(
    _StoredCustomField field,
    _StoredProductCustomFieldValue? value,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return switch (field.fieldType) {
      CustomFieldType.text => value.textValue,
      CustomFieldType.number => _formatNumber(value.numberValue),
      CustomFieldType.date => _formatDate(value.dateValue),
      CustomFieldType.boolean =>
        value.booleanValue == null ? null : (value.booleanValue! ? 'Có' : 'Không'),
      CustomFieldType.singleSelect => _optionLabel(field, value.optionId),
    };
  }

  String? _formatNumber(double? value) {
    if (value == null) {
      return null;
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String? _optionLabel(_StoredCustomField field, String? optionId) {
    if (optionId == null || optionId.trim().isEmpty) {
      return null;
    }
    for (final option in field.options) {
      if (option.optionId == optionId) {
        return option.label;
      }
    }
    return optionId;
  }

  bool _hasValue(String productId, _StoredCustomField field) {
    final value = _findValue(productId, field.fieldId);
    return value != null && !value.isEmpty;
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
      status: field.isActive ? CustomFieldConfigStatus.active : CustomFieldConfigStatus.inactive,
      hasProductValues: _hasProductValues(field.fieldId),
    );
  }

  bool _hasProductValues(String fieldId) {
    for (final value in _productValues.values) {
      if (value.fieldId == fieldId) {
        return true;
      }
    }
    return false;
  }

  CustomFieldGroupConfigDto _toGroupDto(_StoredCustomFieldGroup group) {
    final fields = _fieldsForGroup(group.groupId);
    final activeFields = fields.where((field) => field.isActive);
    return CustomFieldGroupConfigDto(
      groupId: group.groupId,
      name: group.name,
      iconKey: group.iconKey,
      sortOrder: group.sortOrder,
      status: group.isActive ? CustomFieldConfigStatus.active : CustomFieldConfigStatus.inactive,
      fieldCount: activeFields.length,
      requiredFieldCount: activeFields.where((field) => field.isRequired).length,
      fields: fields.map(_toFieldDto).toList(),
    );
  }

  List<CustomFieldGroupCardDto> toActiveGroupCards({String? productId}) {
    final cards = <CustomFieldGroupCardDto>[];
    for (final group in _groups.where((g) => g.isActive)) {
      var hasRequiredMissing = false;
      final fields = _fieldsForGroup(group.groupId).where((field) => field.isActive).map(
        (field) {
          final value = productId == null ? null : _findValue(productId, field.fieldId);
          final isMissing = field.isRequired && (productId == null || !_hasValue(productId, field));
          if (isMissing) {
            hasRequiredMissing = true;
          }
          return CustomFieldCardFieldDto(
            fieldId: field.fieldId,
            name: field.name,
            fieldType: field.fieldType.name,
            displayValue: _displayValue(field, value),
            sortOrder: field.sortOrder,
            isRequired: field.isRequired,
            isMissing: isMissing,
          );
        },
      ).toList();
      cards.add(
        CustomFieldGroupCardDto(
          groupId: group.groupId,
          name: group.name,
          iconKey: group.iconKey,
          sortOrder: group.sortOrder,
          fields: fields,
          hasRequiredMissing: hasRequiredMissing,
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
      if (command.fieldType != field.fieldType && _hasProductValues(field.fieldId)) {
        throw CustomFieldTypeChangeBlockedException(fieldId: field.fieldId);
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
              optionId: option.optionId.isNotEmpty ? option.optionId : 'cf-option-$_nextOptionId++',
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
              optionId: option.optionId.isNotEmpty ? option.optionId : 'cf-option-$_nextOptionId++',
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

    final missingCount = !wasRequired && command.isRequired ? productsMissingRequiredCount : 0;

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

  ProductCustomFieldValuesDto getValues({
    required String tenantId,
    required String productId,
    bool includeInactiveValues = false,
  }) {
    final groups = <ProductCustomFieldValueGroupDto>[];
    for (final group in _groupsForTenant(tenantId)) {
      if (!group.isActive && !includeInactiveValues) {
        continue;
      }
      final fields = <ProductCustomFieldValueFieldDto>[];
      for (final field in _fieldsForGroup(group.groupId)) {
        final value = _findValue(productId, field.fieldId);
        if (!field.isActive && (!includeInactiveValues || value == null)) {
          continue;
        }
        final isMissing =
            group.isActive && field.isActive && field.isRequired && !_hasValue(productId, field);
        fields.add(
          ProductCustomFieldValueFieldDto(
            fieldId: field.fieldId,
            groupId: group.groupId,
            name: field.name,
            fieldType: field.fieldType.name,
            options: field.options.map(_toOptionDto).toList(),
            isRequired: field.isRequired,
            isMissing: isMissing,
            sortOrder: field.sortOrder,
            displayValue: _displayValue(field, value),
            textValue: value?.textValue,
            numberValue: value?.numberValue,
            dateValue: value?.dateValue,
            booleanValue: value?.booleanValue,
            optionId: value?.optionId,
          ),
        );
      }
      if (group.isActive || fields.isNotEmpty) {
        groups.add(
          ProductCustomFieldValueGroupDto(
            groupId: group.groupId,
            name: group.name,
            iconKey: group.iconKey,
            sortOrder: group.sortOrder,
            fields: fields,
          ),
        );
      }
    }
    groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ProductCustomFieldValuesDto(productId: productId, groups: groups);
  }

  void upsertValues(UpsertCustomFieldValuesCommand command) {
    final byFieldId = {
      for (final value in command.values) value.fieldId: value,
    };
    final errors = <CustomFieldValueValidationErrorDto>[];

    for (final group in _groupsForTenant(command.tenantId).where((g) => g.isActive)) {
      for (final field in _fieldsForGroup(group.groupId).where((f) => f.isActive)) {
        final input = byFieldId[field.fieldId];
        if (input != null) {
          final error = _validateInput(group, field, input);
          if (error != null) {
            errors.add(error);
          }
        }
        // Required empty fields do not block upsert on product edit; readiness
        // still reflects missing_required_custom_fields separately.
      }
    }

    if (errors.isNotEmpty) {
      throw CustomFieldValueValidationException(errors: errors);
    }

    for (final input in command.values) {
      final field = _findField(input.fieldId);
      if (field == null) {
        throw CustomFieldNotFoundException(fieldId: input.fieldId);
      }
      final group = _findGroup(field.groupId);
      if (group == null || group.tenantId != command.tenantId) {
        throw CustomFieldNotFoundException(fieldId: input.fieldId);
      }
      if (!group.isActive || !field.isActive) {
        throw CustomFieldValueValidationException(
          errors: [
            CustomFieldValueValidationErrorDto(
              fieldId: field.fieldId,
              groupId: group.groupId,
              code: 'inactive_field',
              message: '${field.name} đang tạm tắt.',
            ),
          ],
        );
      }
      final key = _valueKey(command.productId, field.fieldId);
      if (input.isEmpty) {
        _productValues.remove(key);
        continue;
      }
      _productValues[key] = _StoredProductCustomFieldValue(
        productId: command.productId,
        fieldId: field.fieldId,
        textValue: input.textValue?.trim(),
        numberValue: input.numberValue,
        dateValue: input.dateValue,
        booleanValue: input.booleanValue,
        optionId: input.optionId,
      );
    }
  }

  bool hasRequiredValues(String productId) {
    for (final group in _groups.where((g) => g.isActive)) {
      for (final field in _fieldsForGroup(group.groupId)) {
        if (!field.isActive || !field.isRequired) {
          continue;
        }
        if (!_hasValue(productId, field)) {
          return false;
        }
      }
    }
    return true;
  }

  void seedSearchContractData({bool deactivateFilterableField = false}) {
    if (_groups.isNotEmpty) {
      return;
    }
    final group = _StoredCustomFieldGroup(
      groupId: 'cf-group-medicine',
      tenantId: 'tenant-1',
      name: 'Thông tin thuốc',
      sortOrder: 1,
    );
    _groups.add(group);

    final dosageForm = _StoredCustomField(
      fieldId: 'cf-dosage-form',
      groupId: group.groupId,
      name: 'Dạng dùng',
      fieldType: CustomFieldType.singleSelect,
      options: [
        _StoredCustomFieldOption(optionId: 'opt-solution', label: 'Dung dịch', sortOrder: 1),
        _StoredCustomFieldOption(optionId: 'opt-tablet', label: 'Viên nén', sortOrder: 2),
      ],
      isSearchable: true,
      isFilterable: true,
      displayOnList: true,
      sortOrder: 1,
      isActive: !deactivateFilterableField,
    );
    final indication = _StoredCustomField(
      fieldId: 'cf-indication',
      groupId: group.groupId,
      name: 'Chỉ định',
      fieldType: CustomFieldType.text,
      isSearchable: true,
      displayOnList: false,
      sortOrder: 2,
    );
    _fields.addAll([dosageForm, indication]);

    _productValues[_valueKey('product-1', dosageForm.fieldId)] = _StoredProductCustomFieldValue(
      productId: 'product-1',
      fieldId: dosageForm.fieldId,
      optionId: 'opt-solution',
    );
    _productValues[_valueKey('product-1', indication.fieldId)] = _StoredProductCustomFieldValue(
      productId: 'product-1',
      fieldId: indication.fieldId,
      textValue: 'hỗ trợ tiêu hóa',
    );
  }

  List<CustomFieldListValueDto> listDisplayValuesForProduct(String productId) {
    final values = <CustomFieldListValueDto>[];
    for (final group in _groups.where((group) => group.isActive)) {
      for (final field in _fieldsForGroup(group.groupId)) {
        if (!field.isActive || !field.displayOnList) {
          continue;
        }
        final displayValue = _displayValue(field, _findValue(productId, field.fieldId));
        if (displayValue == null || displayValue.trim().isEmpty) {
          continue;
        }
        values.add(
          CustomFieldListValueDto(
            fieldId: field.fieldId,
            groupId: group.groupId,
            groupName: group.name,
            fieldName: field.name,
            fieldType: field.fieldType.name,
            displayValue: displayValue,
            sortOrder: group.sortOrder * 1000 + field.sortOrder,
          ),
        );
      }
    }
    values.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return values;
  }

  bool matchesSearchKeyword(String productId, String keyword) {
    final foldedKeyword = SearchKeywordNormalizer.foldForSearch(keyword);
    for (final group in _groups.where((group) => group.isActive)) {
      for (final field in _fieldsForGroup(group.groupId)) {
        if (!field.isActive || !field.isSearchable) {
          continue;
        }
        final value = _displayValue(field, _findValue(productId, field.fieldId));
        if (value != null && SearchKeywordNormalizer.foldForSearch(value).contains(foldedKeyword)) {
          return true;
        }
      }
    }
    return false;
  }

  bool matchesFilters(String productId, List<CustomFieldFilterCriteria> filters) {
    for (final filter in filters) {
      final field = _findField(filter.fieldId);
      if (field == null || !field.isActive || !field.isFilterable) {
        return false;
      }
      final value = _findValue(productId, field.fieldId);
      if (filter.optionId != null && value?.optionId != filter.optionId) {
        return false;
      }
      if (filter.booleanValue != null && value?.booleanValue != filter.booleanValue) {
        return false;
      }
    }
    return true;
  }

  List<CustomFieldFilterOptionDto> listFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) {
    final options = <CustomFieldFilterOptionDto>[];
    for (final group in _groupsForTenant(tenantId).where((group) => group.isActive)) {
      for (final field in _fieldsForGroup(group.groupId)) {
        if (!field.isActive || !field.isFilterable) {
          continue;
        }
        if (field.fieldType != CustomFieldType.singleSelect &&
            field.fieldType != CustomFieldType.boolean) {
          continue;
        }
        final fieldOptions = field.fieldType == CustomFieldType.singleSelect
            ? field.options
                  .where((option) => option.isActive)
                  .take(maxOptionsPerField)
                  .map(_toOptionDto)
                  .toList()
            : <CustomFieldSelectOptionDto>[];
        options.add(
          CustomFieldFilterOptionDto(
            fieldId: field.fieldId,
            groupId: group.groupId,
            groupName: group.name,
            fieldName: field.name,
            fieldType: field.fieldType.name,
            options: fieldOptions,
            sortOrder: group.sortOrder * 1000 + field.sortOrder,
          ),
        );
      }
    }
    options.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return options;
  }

  ProductCustomFieldSnapshotDto getSnapshot({
    required String tenantId,
    required List<String> productIds,
    required bool includeInactiveValues,
  }) {
    final products = <String, List<ProductCustomFieldSnapshotFieldDto>>{};
    for (final productId in productIds) {
      final fields = <ProductCustomFieldSnapshotFieldDto>[];
      for (final group in _groupsForTenant(tenantId)) {
        if (!group.isActive && !includeInactiveValues) {
          continue;
        }
        for (final field in _fieldsForGroup(group.groupId)) {
          if (!field.isActive && !includeInactiveValues) {
            continue;
          }
          final value = _findValue(productId, field.fieldId);
          if (value == null || value.isEmpty) {
            continue;
          }
          fields.add(
            ProductCustomFieldSnapshotFieldDto(
              productId: productId,
              fieldId: field.fieldId,
              groupId: group.groupId,
              groupName: group.name,
              fieldName: field.name,
              fieldType: field.fieldType.name,
              displayValue: _displayValue(field, value),
              textValue: value.textValue,
              numberValue: value.numberValue,
              dateValue: value.dateValue,
              booleanValue: value.booleanValue,
              optionId: value.optionId,
              optionLabel: _optionLabel(field, value.optionId),
              isActive: field.isActive && group.isActive,
            ),
          );
        }
      }
      products[productId] = fields;
    }
    return ProductCustomFieldSnapshotDto(products: products);
  }

  CustomFieldValueValidationErrorDto? _validateInput(
    _StoredCustomFieldGroup group,
    _StoredCustomField field,
    ProductCustomFieldValueInput input,
  ) {
    if (input.isEmpty) {
      return null;
    }
    final hasCorrectValue = switch (field.fieldType) {
      CustomFieldType.text =>
        input.textValue != null &&
            input.numberValue == null &&
            input.dateValue == null &&
            input.booleanValue == null &&
            input.optionId == null,
      CustomFieldType.number =>
        input.numberValue != null &&
            input.textValue == null &&
            input.dateValue == null &&
            input.booleanValue == null &&
            input.optionId == null,
      CustomFieldType.date =>
        input.dateValue != null &&
            input.textValue == null &&
            input.numberValue == null &&
            input.booleanValue == null &&
            input.optionId == null,
      CustomFieldType.boolean =>
        input.booleanValue != null &&
            input.textValue == null &&
            input.numberValue == null &&
            input.dateValue == null &&
            input.optionId == null,
      CustomFieldType.singleSelect =>
        input.optionId != null &&
            input.textValue == null &&
            input.numberValue == null &&
            input.dateValue == null &&
            input.booleanValue == null,
    };
    if (!hasCorrectValue) {
      return CustomFieldValueValidationErrorDto(
        fieldId: field.fieldId,
        groupId: group.groupId,
        code: 'invalid_type',
        message: '${field.name} không đúng kiểu dữ liệu.',
      );
    }
    if (field.fieldType == CustomFieldType.singleSelect) {
      _StoredCustomFieldOption? option;
      for (final candidate in field.options) {
        if (candidate.optionId == input.optionId) {
          option = candidate;
          break;
        }
      }
      if (option == null || !option.isActive) {
        return CustomFieldValueValidationErrorDto(
          fieldId: field.fieldId,
          groupId: group.groupId,
          code: 'invalid_option',
          message: '${field.name} không có lựa chọn hợp lệ.',
        );
      }
    }
    return null;
  }
}
