import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/logic/product_custom_field_group_edit_cubit.dart';
import 'package:erp/features/catalog/logic/product_custom_field_group_edit_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockCustomFieldRepository extends Fake implements CustomFieldRepository {
  _MockCustomFieldRepository({
    this.onGetProductValues,
    this.onUpsertProductValues,
  });

  final Future<ProductCustomFieldValuesDto> Function(String productId, {bool includeInactiveValues})?
      onGetProductValues;
  final Future<void> Function({
    required String productId,
    required List<ProductCustomFieldValueInput> values,
  })? onUpsertProductValues;

  @override
  Future<ProductCustomFieldValuesDto> getProductValues(
    String productId, {
    bool includeInactiveValues = false,
  }) async {
    if (onGetProductValues != null) {
      return onGetProductValues!(productId, includeInactiveValues: includeInactiveValues);
    }
    return const ProductCustomFieldValuesDto(
      productId: 'prod-1',
      groups: [],
    );
  }

  @override
  Future<void> upsertProductValues({
    required String productId,
    required List<ProductCustomFieldValueInput> values,
  }) async {
    if (onUpsertProductValues != null) {
      return onUpsertProductValues!(
        productId: productId,
        values: values,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('ProductCustomFieldGroupEditCubit (H12)', () {
    const dummyGroup = ProductCustomFieldValueGroupDto(
      groupId: 'group-1',
      name: 'Thông tin bổ sung',
      sortOrder: 0,
      fields: [
        ProductCustomFieldValueFieldDto(
          fieldId: 'field-1',
          groupId: 'group-1',
          name: 'Hàm lượng',
          fieldType: 'text',
          isRequired: true,
          isActive: true,
        ),
        ProductCustomFieldValueFieldDto(
          fieldId: 'field-2',
          groupId: 'group-1',
          name: 'Nhiệt độ bảo quản',
          fieldType: 'number',
          isRequired: true,
          isActive: true,
        ),
      ],
    );

    test('maps CUSTOM_FIELD_VALUE_VALIDATION errors into validationErrors per field (2 fields)', () async {
      final repo = _MockCustomFieldRepository(
        onGetProductValues: (id, {includeInactiveValues = false}) async {
          return const ProductCustomFieldValuesDto(
            productId: 'prod-1',
            groups: [dummyGroup],
          );
        },
        onUpsertProductValues: ({required productId, required values}) async {
          throw const AppException(
            CatalogErrorCodes.customFieldValueValidation,
            details: {
              'errors': [
                {
                  'field_id': 'field-1',
                  'message': 'Hàm lượng không được để trống.',
                },
                {
                  'field_id': 'field-2',
                  'message': 'Nhiệt độ bảo quản phải là số dương.',
                },
              ],
            },
          );
        },
      );

      final cubit = ProductCustomFieldGroupEditCubit(customFieldRepository: repo);
      await cubit.loadGroup('prod-1', 'group-1');

      expect(cubit.state, isA<ProductCustomFieldGroupEditLoaded>());

      await cubit.submit('prod-1');

      expect(cubit.state, isA<ProductCustomFieldGroupEditLoaded>());
      final loaded = cubit.state as ProductCustomFieldGroupEditLoaded;
      expect(loaded.isSubmitting, isFalse);
      expect(loaded.validationErrors.length, 2);
      expect(loaded.validationErrors['field-1'], 'Hàm lượng không được để trống.');
      expect(loaded.validationErrors['field-2'], 'Nhiệt độ bảo quản phải là số dương.');
    });

    test('loadGroup failure emits loaded state with empty group and error message', () async {
      final repo = _MockCustomFieldRepository(
        onGetProductValues: (id, {includeInactiveValues = false}) async {
          throw Exception('Failed to load values');
        },
      );

      final cubit = ProductCustomFieldGroupEditCubit(customFieldRepository: repo);
      await cubit.loadGroup('prod-1', 'group-1');

      expect(cubit.state, isA<ProductCustomFieldGroupEditLoaded>());
      final loaded = cubit.state as ProductCustomFieldGroupEditLoaded;
      expect(loaded.group.fields, isEmpty);
      expect(loaded.error, isNotNull);
    });
  });
}
