import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/logic/custom_field_config_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockCustomFieldRepository extends Fake implements CustomFieldRepository {
  _MockCustomFieldRepository({
    this.onUpsertGroup,
    this.onUpsertField,
    this.onConfigureAttributes,
  });

  final Future<void> Function({
    String? groupId,
    required String name,
    String? iconKey,
    bool isActive,
  })? onUpsertGroup;
  final Future<CustomFieldDefinitionDto> Function({
    required String groupId,
    String? fieldId,
    required String name,
    required CustomFieldType fieldType,
    List<CustomFieldSelectOptionDto> options,
    bool isActive,
  })? onUpsertField;
  final Future<void> Function({
    required String fieldId,
    required bool isRequired,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
  })? onConfigureAttributes;

  @override
  Future<CustomFieldConfigViewDto> listConfig() async {
    return const CustomFieldConfigViewDto(groups: []);
  }

  @override
  Future<void> upsertGroup({
    String? groupId,
    required String name,
    String? iconKey,
    bool isActive = true,
  }) async {
    if (onUpsertGroup != null) {
      return onUpsertGroup!(
        groupId: groupId,
        name: name,
        iconKey: iconKey,
        isActive: isActive,
      );
    }
    throw UnimplementedError();
  }

  @override
  Future<CustomFieldDefinitionDto> upsertField({
    required String groupId,
    String? fieldId,
    required String name,
    required CustomFieldType fieldType,
    List<CustomFieldSelectOptionDto> options = const [],
    bool isActive = true,
  }) async {
    if (onUpsertField != null) {
      return onUpsertField!(
        groupId: groupId,
        fieldId: fieldId,
        name: name,
        fieldType: fieldType,
        options: options,
        isActive: isActive,
      );
    }
    throw UnimplementedError();
  }

  @override
  Future<void> configureAttributes({
    required String fieldId,
    required bool isRequired,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
  }) async {
    if (onConfigureAttributes != null) {
      return onConfigureAttributes!(
        fieldId: fieldId,
        isRequired: isRequired,
        isSearchable: isSearchable,
        isFilterable: isFilterable,
        displayOnList: displayOnList,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('CustomFieldConfigCubit (H11)', () {
    test('1. upsertField for new field passes new result.fieldId to configureAttributes', () async {
      String? configuredFieldId;
      final repo = _MockCustomFieldRepository(
        onUpsertField: ({
          required groupId,
          fieldId,
          required name,
          required fieldType,
          options = const [],
          isActive = true,
        }) async {
          return const CustomFieldDefinitionDto(
            fieldId: 'field-new-uuid',
            groupId: 'group-1',
            name: 'Thời gian bảo quản',
            fieldType: CustomFieldType.text,
            isRequired: false,
            isSearchable: false,
            isFilterable: false,
            displayOnList: false,
            sortOrder: 0,
            status: CustomFieldConfigStatus.active,
            hasProductValues: false,
          );
        },
        onConfigureAttributes: ({
          required fieldId,
          required isRequired,
          required isSearchable,
          required isFilterable,
          required displayOnList,
        }) async {
          configuredFieldId = fieldId;
        },
      );

      final cubit = CustomFieldConfigCubit(customFieldRepository: repo);

      final success = await cubit.upsertField(
        groupId: 'group-1',
        name: 'Thời gian bảo quản',
        fieldType: CustomFieldType.text,
        isRequired: true,
        displayOnList: true,
        isSearchable: true,
        isFilterable: false,
      );

      expect(success, isTrue);
      expect(configuredFieldId, 'field-new-uuid');
    });

    test('2. upsertGroup with duplicate name sets duplicate group error message', () async {
      final repo = _MockCustomFieldRepository(
        onUpsertGroup: ({groupId, required name, iconKey, isActive = true}) async {
          throw const AppException(
            CatalogErrorCodes.duplicateCustomFieldGroupName,
            details: {'value': 'Thông tin chung'},
          );
        },
      );

      final cubit = CustomFieldConfigCubit(customFieldRepository: repo);

      final success = await cubit.upsertGroup(name: 'Thông tin chung');

      expect(success, isFalse);
      expect(cubit.state.error, 'Tên nhóm đã tồn tại.');
    });
  });
}
