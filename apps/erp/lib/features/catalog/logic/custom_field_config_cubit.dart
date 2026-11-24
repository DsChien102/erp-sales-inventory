import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/custom_field_repository.dart';
import '../data/models.dart';
import 'catalog_error_messages.dart';
import 'custom_field_config_state.dart';

class CustomFieldConfigCubit extends Cubit<CustomFieldConfigState> {
  final CustomFieldRepository _customFieldRepository;

  CustomFieldConfigCubit({
    required CustomFieldRepository customFieldRepository,
  })  : _customFieldRepository = customFieldRepository,
        super(const CustomFieldConfigState());

  Future<void> loadGroups() async {
    emit(state.copyWith(isLoading: true, error: null, clearError: true));
    try {
      final viewDto = await _customFieldRepository.listConfig();
      emit(state.copyWith(isLoading: false, groups: viewDto.groups));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: catalogErrorMessage(e)));
    }
  }

  Future<void> initializeTemplate() async {
    emit(state.copyWith(isSaving: true, error: null, clearError: true));
    try {
      await _customFieldRepository.initializeTemplate();
      emit(state.copyWith(isSaving: false));
      await loadGroups();
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: catalogErrorMessage(e)));
    }
  }

  Future<void> reorderGroups(List<String> orderedGroupIds) async {
    if (orderedGroupIds.length != state.groups.length) return;

    final byId = {for (final group in state.groups) group.groupId: group};
    final groups = <CustomFieldGroupConfigDto>[];
    for (var index = 0; index < orderedGroupIds.length; index++) {
      final group = byId[orderedGroupIds[index]];
      if (group == null) return;
      groups.add(
        CustomFieldGroupConfigDto(
          groupId: group.groupId,
          name: group.name,
          iconKey: group.iconKey,
          sortOrder: index,
          status: group.status,
          fieldCount: group.fieldCount,
          requiredFieldCount: group.requiredFieldCount,
          fields: group.fields,
        ),
      );
    }

    // Optimistic update — giữ sortOrder khớp thứ tự mới để UI không bị sort lại về cũ.
    emit(state.copyWith(groups: groups));

    try {
      await _customFieldRepository.reorderGroups(orderedGroupIds);
    } catch (e) {
      emit(state.copyWith(error: catalogErrorMessage(e)));
      await loadGroups();
    }
  }

  Future<bool> upsertGroup({
    String? groupId,
    required String name,
    String? iconKey,
    bool isActive = true,
  }) async {
    emit(state.copyWith(isSaving: true, error: null, clearError: true));
    try {
      await _customFieldRepository.upsertGroup(
        groupId: groupId,
        name: name,
        iconKey: iconKey,
        isActive: isActive,
      );
      emit(state.copyWith(isSaving: false));
      await loadGroups();
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: catalogErrorMessage(e)));
      return false;
    }
  }

  Future<void> reorderFields(String groupId, List<String> orderedFieldIds) async {
    final groupIndex = state.groups.indexWhere((g) => g.groupId == groupId);
    if (groupIndex == -1) return;

    final group = state.groups[groupIndex];
    if (orderedFieldIds.length != group.fields.length) return;

    final byId = {for (final field in group.fields) field.fieldId: field};
    final fields = <CustomFieldDefinitionDto>[];
    for (var index = 0; index < orderedFieldIds.length; index++) {
      final field = byId[orderedFieldIds[index]];
      if (field == null) return;
      fields.add(
        CustomFieldDefinitionDto(
          fieldId: field.fieldId,
          groupId: field.groupId,
          name: field.name,
          fieldType: field.fieldType,
          options: field.options,
          isRequired: field.isRequired,
          isSearchable: field.isSearchable,
          isFilterable: field.isFilterable,
          displayOnList: field.displayOnList,
          sortOrder: index,
          status: field.status,
          hasProductValues: field.hasProductValues,
        ),
      );
    }

    final updatedGroup = CustomFieldGroupConfigDto(
      groupId: group.groupId,
      name: group.name,
      iconKey: group.iconKey,
      sortOrder: group.sortOrder,
      status: group.status,
      fieldCount: group.fieldCount,
      requiredFieldCount: group.requiredFieldCount,
      fields: fields,
    );
    final updatedGroups = List<CustomFieldGroupConfigDto>.from(state.groups);
    updatedGroups[groupIndex] = updatedGroup;

    // Optimistic update
    emit(state.copyWith(groups: updatedGroups));

    try {
      await _customFieldRepository.reorderFields(
        groupId: groupId,
        orderedFieldIds: orderedFieldIds,
      );
    } catch (e) {
      emit(state.copyWith(error: catalogErrorMessage(e)));
      await loadGroups();
    }
  }

  Future<bool> upsertField({
    String? fieldId,
    required String groupId,
    required String name,
    required CustomFieldType fieldType,
    List<CustomFieldSelectOptionDto>? options,
    required bool isRequired,
    required bool displayOnList,
    required bool isSearchable,
    required bool isFilterable,
    bool isActive = true,
  }) async {
    emit(state.copyWith(isSaving: true, error: null, clearError: true));
    try {
      // 1. Upsert field definition
      final result = await _customFieldRepository.upsertField(
        groupId: groupId,
        fieldId: fieldId,
        name: name,
        fieldType: fieldType,
        options: options ?? const [],
        isActive: isActive,
      );

      // 2. Configure attributes
      final targetFieldId = fieldId ?? result.fieldId;
      await _customFieldRepository.configureAttributes(
        fieldId: targetFieldId,
        isRequired: isRequired,
        displayOnList: displayOnList,
        isSearchable: isSearchable,
        isFilterable: isFilterable,
      );

      emit(state.copyWith(isSaving: false));
      await loadGroups();
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: catalogErrorMessage(e)));
      return false;
    }
  }
}
