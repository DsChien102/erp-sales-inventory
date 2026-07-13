import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_custom_field_group_edit_state.dart';

class ProductCustomFieldGroupEditCubit extends Cubit<ProductCustomFieldGroupEditState> {
  ProductCustomFieldGroupEditCubit({
    required IExecutionContext context,
    required ICatalogModule catalogModule,
  }) : _context = context,
       _catalogModule = catalogModule,
       super(ProductCustomFieldGroupEditInitial());

  final IExecutionContext _context;
  final ICatalogModule _catalogModule;

  Future<void> loadGroup(String productId, String groupId) async {
    try {
      emit(ProductCustomFieldGroupEditLoading());
      final tenantId = await _context.requireTenantId();

      final query = GetProductCustomFieldValuesQuery(
        tenantId: tenantId,
        productId: productId,
        includeInactiveValues: true,
      );

      final result = await _catalogModule.executeQueryAsync<ProductCustomFieldValuesDto>(query);

      final group = result.groups.where((g) => g.groupId == groupId).firstOrNull;
      if (group == null) {
        emit(
          ProductCustomFieldGroupEditLoaded(
            group: ProductCustomFieldValueGroupDto(
              groupId: groupId,
              name: '',
              sortOrder: 0,
              fields: [],
            ),
            inputs: {},
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
            fields: [],
          ),
          inputs: {},
          error: 'Lỗi tải dữ liệu: $e',
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

    // Validation
    final validationErrors = <String, String>{};
    for (final field in loaded.group.fields) {
      if (field.isRequired) {
        final input = loaded.inputs[field.fieldId];
        if (input == null || input.isEmpty) {
          validationErrors[field.fieldId] = 'Trường này là bắt buộc';
        }
      }
    }

    if (validationErrors.isNotEmpty) {
      emit(loaded.copyWith(validationErrors: validationErrors));
      return;
    }

    emit(loaded.copyWith(isSubmitting: true, clearError: true));

    try {
      final tenantId = await _context.requireTenantId();

      final activeValues = loaded.inputs.values.where((input) {
        final field = loaded.group.fields.firstWhere((f) => f.fieldId == input.fieldId);
        return field.isActive;
      }).toList();

      final command = UpsertCustomFieldValuesCommand(
        tenantId: tenantId,
        productId: productId,
        values: activeValues,
      );

      await _catalogModule.executeCommandAsync<UpsertCustomFieldValuesResult>(command);
      emit(ProductCustomFieldGroupEditSuccess());
    } on CustomFieldValueValidationException catch (e) {
      final fieldErrors = {
        for (final error in e.errors) error.fieldId: error.message,
      };
      emit(
        loaded.copyWith(
          isSubmitting: false,
          validationErrors: fieldErrors,
          error: fieldErrors.isEmpty ? e.message : null,
        ),
      );
    } on ApplicationException catch (e) {
      emit(loaded.copyWith(isSubmitting: false, error: e.message));
    } catch (e) {
      emit(loaded.copyWith(isSubmitting: false, error: 'Đã có lỗi xảy ra. Vui lòng thử lại.'));
    }
  }
}
