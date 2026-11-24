import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/models/custom_field_config.dart';
import 'package:erp/features/catalog/data/models/custom_field_filter_option.dart';
import 'package:erp/features/catalog/data/models/product_control_center.dart';
import 'package:erp/features/catalog/data/models/product_custom_field_values.dart';
import 'package:erp/features/catalog/data/models/product_inputs.dart';
import 'package:erp/features/catalog/data/models/product_search.dart';

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
    this.isSearchable = false,
    this.isFilterable = false,
    this.displayOnList = false,
    this.sortOrder = 0,
    this.isActive = true,
  }) : isRequired = false;

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

/// Helper to fold Vietnamese diacritics for fake in-memory search.
String foldVietnameseForSearch(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final codeUnit in lower.codeUnits) {
    buffer.writeCharCode(_foldCodeUnit(codeUnit));
  }
  return buffer.toString();
}

int _foldCodeUnit(int codeUnit) {
  const map = <int, int>{
    0x00E0: 0x61, 0x00E1: 0x61, 0x00E2: 0x61, 0x00E3: 0x61, 0x00E8: 0x65,
    0x00E9: 0x65, 0x00EA: 0x65, 0x00EC: 0x69, 0x00ED: 0x69, 0x00F2: 0x6F,
    0x00F3: 0x6F, 0x00F4: 0x6F, 0x00F5: 0x6F, 0x00F9: 0x75, 0x00FA: 0x75,
    0x00FD: 0x79, 0x0111: 0x64, 0x0103: 0x61, 0x01A1: 0x6F, 0x01B0: 0x75,
    0x1EA1: 0x61, 0x1EA3: 0x61, 0x1EA5: 0x61, 0x1EA7: 0x61, 0x1EA9: 0x61,
    0x1EAB: 0x61, 0x1EAD: 0x61, 0x1EAF: 0x61, 0x1EB1: 0x61, 0x1EB3: 0x61,
    0x1EB5: 0x61, 0x1EB7: 0x61, 0x1EB9: 0x65, 0x1EBB: 0x65, 0x1EBD: 0x65,
    0x1EBF: 0x65, 0x1EC1: 0x65, 0x1EC3: 0x65, 0x1EC5: 0x65, 0x1EC7: 0x65,
    0x1EC9: 0x69, 0x1ECB: 0x69, 0x1ECD: 0x6F, 0x1ECF: 0x6F, 0x1ED1: 0x6F,
    0x1ED3: 0x6F, 0x1ED5: 0x6F, 0x1ED7: 0x6F, 0x1ED9: 0x6F, 0x1EDB: 0x6F,
    0x1EDD: 0x6F, 0x1EDF: 0x6F, 0x1EE1: 0x6F, 0x1EE3: 0x6F, 0x1EE5: 0x75,
    0x1EE7: 0x75, 0x1EE9: 0x75, 0x1EEB: 0x75, 0x1EED: 0x75, 0x1EEF: 0x75,
    0x1EF1: 0x75, 0x1EF3: 0x79, 0x1EF5: 0x79, 0x1EF7: 0x79, 0x1EF9: 0x79,
  };
  return map[codeUnit] ?? codeUnit;
}

/// In-memory custom field config store for [FakeCatalogBackend].
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
      throw const AppException(
        AppErrorCode.noPermission,
        serverMessage: 'Permission denied',
      );
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
      name: customFieldGroupDisplayName(group.name),
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
          name: customFieldGroupDisplayName(group.name),
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

  Future<void> initializeTemplate(String tenantId, {String? templateId}) async {
    _assertCustomFieldPermission();

    final id = templateId ?? _defaultTemplateId;
    if (id != _defaultTemplateId) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Template not found.',
      );
    }

    for (final spec in _vetPharmacyTemplate) {
      final existingGroup = _findActiveGroupByName(tenantId, spec.name);
      late final _StoredCustomFieldGroup group;
      if (existingGroup != null) {
        group = existingGroup;
      } else {
        group = _StoredCustomFieldGroup(
          groupId: 'cf-group-$_nextGroupId',
          tenantId: tenantId,
          name: spec.name,
          iconKey: spec.iconKey,
          sortOrder: _groupsForTenant(tenantId).length,
        );
        _nextGroupId++;
        _groups.add(group);
      }

      for (final fieldSpec in spec.fields) {
        final existingField = _findActiveFieldByName(group.groupId, fieldSpec.name);
        if (existingField != null) {
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
      }
    }
  }

  Future<void> upsertGroup(
    String tenantId, {
    String? groupId,
    required String name,
    required int sortOrder,
    String? iconKey,
    String? description,
    bool isActive = true,
  }) async {
    _assertCustomFieldPermission();

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Group name must not be empty.',
      );
    }

    if (scenario == FakeCatalogScenario.cfGroupDuplicateName) {
      throw AppException(
        CatalogErrorCodes.duplicateCustomFieldGroupName,
        details: {'value': trimmed},
      );
    }

    if (groupId != null) {
      final group = _findGroup(groupId);
      if (group == null || group.tenantId != tenantId) {
        throw const AppException(CatalogErrorCodes.customFieldGroupNotFound);
      }
      final duplicate = _findActiveGroupByName(
        tenantId,
        trimmed,
        excludeGroupId: group.groupId,
      );
      if (duplicate != null) {
        throw AppException(
          CatalogErrorCodes.duplicateCustomFieldGroupName,
          details: {'value': trimmed},
        );
      }
      group.name = trimmed;
      group.iconKey = iconKey;
      group.isActive = isActive;
      return;
    }

    final duplicate = _findActiveGroupByName(tenantId, trimmed);
    if (duplicate != null) {
      throw AppException(
        CatalogErrorCodes.duplicateCustomFieldGroupName,
        details: {'value': trimmed},
      );
    }

    final group = _StoredCustomFieldGroup(
      groupId: 'cf-group-$_nextGroupId',
      tenantId: tenantId,
      name: trimmed,
      iconKey: iconKey,
      sortOrder: _groupsForTenant(tenantId).length,
      isActive: isActive,
    );
    _nextGroupId++;
    _groups.add(group);
  }

  Future<void> reorderGroups(String tenantId, List<String> orderedGroupIds) async {
    _assertCustomFieldPermission();

    final tenantGroups = _groupsForTenant(tenantId);
    if (orderedGroupIds.length != tenantGroups.length) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Ordered group ids must include all groups.',
      );
    }

    for (var index = 0; index < orderedGroupIds.length; index++) {
      final groupId = orderedGroupIds[index];
      final group = _findGroup(groupId);
      if (group == null || group.tenantId != tenantId) {
        throw const AppException(CatalogErrorCodes.customFieldGroupNotFound);
      }
      group.sortOrder = index;
    }
  }

  Future<CustomFieldDefinitionDto> upsertField(
    String tenantId, {
    required String groupId,
    String? fieldId,
    required String name,
    required CustomFieldType fieldType,
    bool isRequired = false,
    List<String>? singleSelectOptions,
    String? description,
    int? sortOrder,
    bool isActive = true,
  }) async {
    _assertCustomFieldPermission();

    final group = _findGroup(groupId);
    if (group == null || group.tenantId != tenantId) {
      throw const AppException(CatalogErrorCodes.customFieldGroupNotFound);
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Field name must not be empty.',
      );
    }

    final rawOptions = singleSelectOptions ?? const <String>[];
    if (scenario == FakeCatalogScenario.cfFieldSingleSelectNoOptions &&
        fieldType == CustomFieldType.singleSelect &&
        rawOptions.isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Single select field requires options.',
      );
    }

    if (fieldType == CustomFieldType.singleSelect &&
        rawOptions.isEmpty &&
        fieldId == null) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Single select field requires options.',
      );
    }

    if (fieldId != null) {
      final field = _findField(fieldId);
      if (field == null || field.groupId != groupId) {
        throw AppException(
          CatalogErrorCodes.customFieldNotFound,
          details: {'value': fieldId},
        );
      }
      if (fieldType != field.fieldType && _hasProductValues(field.fieldId)) {
        throw const AppException(CatalogErrorCodes.customFieldTypeChangeBlocked);
      }
      final duplicate = _findActiveFieldByName(
        groupId,
        trimmed,
        excludeFieldId: field.fieldId,
      );
      if (duplicate != null) {
        throw AppException(
          CatalogErrorCodes.duplicateCustomFieldName,
          details: {'value': trimmed},
        );
      }
      field.name = trimmed;
      field.fieldType = fieldType;
      field.isActive = isActive;
      if (rawOptions.isNotEmpty) {
        field.options = [
          for (var i = 0; i < rawOptions.length; i++)
            _StoredCustomFieldOption(
              optionId: 'cf-option-${_nextOptionId++}',
              label: rawOptions[i],
              sortOrder: i + 1,
              isActive: true,
            ),
        ];
      }
      return _toFieldDto(field);
    }

    final duplicate = _findActiveFieldByName(groupId, trimmed);
    if (duplicate != null) {
      throw AppException(
        CatalogErrorCodes.duplicateCustomFieldName,
        details: {'value': trimmed},
      );
    }

    final field = _StoredCustomField(
      fieldId: 'cf-field-$_nextFieldId',
      groupId: groupId,
      name: trimmed,
      fieldType: fieldType,
      sortOrder: _fieldsForGroup(groupId).length,
      isActive: isActive,
      options: [
        for (var i = 0; i < rawOptions.length; i++)
          _StoredCustomFieldOption(
            optionId: 'cf-option-${_nextOptionId++}',
            label: rawOptions[i],
            sortOrder: i + 1,
            isActive: true,
          ),
      ],
    );
    _nextFieldId++;
    _fields.add(field);
    return _toFieldDto(field);
  }

  Future<void> configureAttributes(
    String tenantId, {
    required String fieldId,
    bool isRequired = false,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
  }) async {
    _assertCustomFieldPermission();

    final field = _findField(fieldId);
    if (field == null) {
      throw AppException(
        CatalogErrorCodes.customFieldNotFound,
        details: {'value': fieldId},
      );
    }

    final group = _findGroup(field.groupId);
    if (group == null || group.tenantId != tenantId) {
      throw AppException(
        CatalogErrorCodes.customFieldNotFound,
        details: {'value': fieldId},
      );
    }

    field.isRequired = isRequired;
    field.isSearchable = isSearchable;
    field.isFilterable = isFilterable;
    field.displayOnList = displayOnList;
  }

  Future<void> reorderFields(
    String tenantId, {
    required String groupId,
    required List<String> orderedFieldIds,
  }) async {
    _assertCustomFieldPermission();

    final group = _findGroup(groupId);
    if (group == null || group.tenantId != tenantId) {
      throw const AppException(CatalogErrorCodes.customFieldGroupNotFound);
    }

    final groupFields = _fieldsForGroup(groupId);
    if (orderedFieldIds.length != groupFields.length) {
      throw const AppException(
        AppErrorCode.validation,
        serverMessage: 'Ordered field ids must include all fields.',
      );
    }

    for (var index = 0; index < orderedFieldIds.length; index++) {
      final fieldId = orderedFieldIds[index];
      final field = _findField(fieldId);
      if (field == null || field.groupId != groupId) {
        throw AppException(
          CatalogErrorCodes.customFieldNotFound,
          details: {'value': fieldId},
        );
      }
      field.sortOrder = index;
    }
  }

  CustomFieldConfigViewDto listConfigSync(String tenantId) {
    _assertCustomFieldPermission();
    final groups = _groupsForTenant(tenantId).map(_toGroupDto).toList();
    return CustomFieldConfigViewDto(groups: groups);
  }

  Future<CustomFieldConfigViewDto> listConfig(String tenantId) async {
    return listConfigSync(tenantId);
  }

  Future<ProductCustomFieldValuesDto> getValues({
    required String tenantId,
    required String productId,
    bool includeInactiveValues = false,
  }) async {
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
            name: customFieldGroupDisplayName(group.name),
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

  Future<void> upsertValues({
    required String tenantId,
    required String productId,
    required List<ProductCustomFieldValueInput> values,
  }) async {
    final byFieldId = {
      for (final value in values) value.fieldId: value,
    };
    final errors = <Map<String, dynamic>>[];

    for (final group in _groupsForTenant(tenantId).where((g) => g.isActive)) {
      for (final field in _fieldsForGroup(group.groupId).where((f) => f.isActive)) {
        final input = byFieldId[field.fieldId];
        if (input != null) {
          final error = _validateInput(group, field, input);
          if (error != null) {
            errors.add(error);
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      throw AppException(
        CatalogErrorCodes.customFieldValueValidation,
        details: {'errors': errors},
      );
    }

    for (final input in values) {
      final field = _findField(input.fieldId);
      if (field == null) {
        throw AppException(
          CatalogErrorCodes.customFieldNotFound,
          details: {'value': input.fieldId},
        );
      }
      final group = _findGroup(field.groupId);
      if (group == null || group.tenantId != tenantId) {
        throw AppException(
          CatalogErrorCodes.customFieldNotFound,
          details: {'value': input.fieldId},
        );
      }
      if (!group.isActive || !field.isActive) {
        throw AppException(
          CatalogErrorCodes.customFieldValueValidation,
          details: {
            'errors': [
              {
                'field_id': field.fieldId,
                'group_id': group.groupId,
                'code': 'inactive_field',
                'message': '${field.name} đang tạm tắt.',
              },
            ],
          },
        );
      }
      final key = _valueKey(productId, field.fieldId);
      if (input.isEmpty) {
        _productValues.remove(key);
        continue;
      }
      _productValues[key] = _StoredProductCustomFieldValue(
        productId: productId,
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
    final requiresPrescription = _StoredCustomField(
      fieldId: 'cf-requires-prescription',
      groupId: group.groupId,
      name: 'Yêu cầu kê đơn',
      fieldType: CustomFieldType.boolean,
      isSearchable: false,
      isFilterable: true,
      displayOnList: true,
      sortOrder: 3,
    );
    _fields.addAll([dosageForm, indication, requiresPrescription]);

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
    _productValues[_valueKey(
      'product-1',
      requiresPrescription.fieldId,
    )] = _StoredProductCustomFieldValue(
      productId: 'product-1',
      fieldId: requiresPrescription.fieldId,
      booleanValue: true,
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
            groupName: customFieldGroupDisplayName(group.name),
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
    final foldedKeyword = foldVietnameseForSearch(keyword);
    for (final group in _groups.where((group) => group.isActive)) {
      for (final field in _fieldsForGroup(group.groupId)) {
        if (!field.isActive || !field.isSearchable) {
          continue;
        }
        final value = _displayValue(field, _findValue(productId, field.fieldId));
        if (value != null && foldVietnameseForSearch(value).contains(foldedKeyword)) {
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

  Future<List<CustomFieldFilterOptionDto>> listFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) async {
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
            groupName: customFieldGroupDisplayName(group.name),
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

  Map<String, dynamic>? _validateInput(
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
      return {
        'field_id': field.fieldId,
        'group_id': group.groupId,
        'code': 'invalid_type',
        'message': '${field.name} không đúng kiểu dữ liệu.',
      };
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
        return {
          'field_id': field.fieldId,
          'group_id': group.groupId,
          'code': 'invalid_option',
          'message': '${field.name} không có lựa chọn hợp lệ.',
        };
      }
    }
    return null;
  }
}
