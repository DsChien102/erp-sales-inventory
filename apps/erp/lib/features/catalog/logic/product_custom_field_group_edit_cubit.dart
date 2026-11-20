import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/custom_field_repository.dart';
import '../data/models.dart';
import 'catalog_error_messages.dart';
import 'product_custom_field_group_edit_state.dart';

class ProductCustomFieldGroupEditCubit extends Cubit<ProductCustomFieldGroupEditState> {
  ProductCustomFieldGroupEditCubit({
    required CustomFieldRepository customFieldRepository,
  })  : _customFieldRepository = customFieldRepository,
        super(ProductCustomFieldGroupEditInitial());

  final CustomFieldRepository _customFieldRepository;

  Future<void> loadGroup(String productId, String groupId) async {
    try {
      emit(ProductCustomFieldGroupEditLoading());

      final result = await _customFieldRepository.getProductValues(
        productId,
        includeInactiveValues: true,
      );

      final group = result.groups.where((g) => g.groupId == groupId).firstOrNull;
      if (group == null) {
        emit(
          ProductCustomFieldGroupEditLoaded(
            group: ProductCustomFieldValueGroupDto(
              groupId: groupId,
              name: '',
              sortOrder: 0,
              fields: const [],
            ),
            inputs: const {},
            error: 'Nhóm thông tin không tồn tại',
          ),
        );
        return;
      }

      final Map<String, ProductCustomFieldValueInput> initialInputs = {};
      for (final field in group.fields) {
        initialInputs[field.fieldId] = ProductCustomFieldValueInput(
          fieldId: field.fieldId,
          textValue: field.textValue,
          numberValue: field.numberValue,
          dateValue: field.dateValue,
          booleanValue: field.booleanValue,
          optionId: field.optionId,
        );
      }

      emit(
        ProductCustomFieldGroupEditLoaded(
          group: group,
          inputs: initialInputs,
          initialInputs: Map<String, ProductCustomFieldValueInput>.from(initialInputs),
        ),
      );
    } catch (e) {
      emit(
        ProductCustomFieldGroupEditLoaded(
          group: ProductCustomFieldValueGroupDto(
            groupId: groupId,
            name: '',
            sortOrder: 0,
            fields: const [],
          ),
          inputs: const {},
          error: catalogErrorMessage(e, fallback: 'Lỗi tải dữ liệu'),
        ),
      );
    }
  }

  void updateInput(ProductCustomFieldValueInput input) {
    if (state is! ProductCustomFieldGroupEditLoaded) return;
    final loaded = state as ProductCustomFieldGroupEditLoaded;

    final newInputs = Map<String, ProductCustomFieldValueInput>.from(loaded.inputs);
    newInputs[input.fieldId] = input;

    // Clear validation error for this field if any
    final newErrors = Map<String, String>.from(loaded.validationErrors);
    newErrors.remove(input.fieldId);

    emit(
      loaded.copyWith(
        inputs: newInputs,
        validationErrors: newErrors,
        clearError: true,
      ),
    );
  }

  Future<void> submit(String productId) async {
    if (state is! ProductCustomFieldGroupEditLoaded) return;
    final loaded = state as ProductCustomFieldGroupEditLoaded;

    if (loaded.isSubmitting) return;

    // Edit flow: allow save even when other required fields in the group are empty.
    // Required completeness stays a readiness concern (warning UX later).

    emit(loaded.copyWith(isSubmitting: true, clearError: true));

    try {
      final activeValues = loaded.inputs.values.where((input) {
        final field = loaded.group.fields.firstWhere((f) => f.fieldId == input.fieldId);
        return field.isActive;
      }).toList();

      await _customFieldRepository.upsertProductValues(
        productId: productId,
        values: activeValues,
      );
      emit(ProductCustomFieldGroupEditSuccess());
    } on AppException catch (e) {
      if (e.code == CatalogErrorCodes.customFieldValueValidation) {
        final rawErrors = e.details?['errors'] as List<dynamic>? ?? const [];
        final fieldErrors = <String, String>{};
        for (final err in rawErrors) {
          if (err is Map) {
            final fieldId = err['field_id']?.toString() ?? '';
            final msg = err['message']?.toString() ?? 'Giá trị không hợp lệ';
            if (fieldId.isNotEmpty) {
              fieldErrors[fieldId] = msg;
            }
          }
        }
        emit(
          loaded.copyWith(
            isSubmitting: false,
            validationErrors: fieldErrors,
            error: fieldErrors.isEmpty ? catalogErrorMessage(e) : null,
          ),
        );
        return;
      }
      emit(
        loaded.copyWith(
          isSubmitting: false,
          error: catalogErrorMessage(e, fallback: 'Đã có lỗi xảy ra. Vui lòng thử lại.'),
        ),
      );
    } catch (e) {
      emit(
        loaded.copyWith(
          isSubmitting: false,
          error: catalogErrorMessage(e, fallback: 'Đã có lỗi xảy ra. Vui lòng thử lại.'),
        ),
      );
    }
  }
}
