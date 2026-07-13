import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import 'custom_field_config_state.dart';

class CustomFieldConfigCubit extends Cubit<CustomFieldConfigState> {
  final IModuleMediator _mediator;
  final IExecutionContext _executionContext;

  CustomFieldConfigCubit(
    this._mediator,
    this._executionContext,
  ) : super(const CustomFieldConfigState());

  Future<void> loadGroups() async {
    emit(state.copyWith(isLoading: true, error: null, clearError: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final query = ListCustomFieldConfigQuery(
        tenantId: tenantId,
      );
      final viewDto = await _mediator.executeQueryAsync(query);
      emit(state.copyWith(isLoading: false, groups: viewDto.groups));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> initializeTemplate() async {
    emit(state.copyWith(isSaving: true, error: null, clearError: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final command = InitializeCustomFieldTemplateCommand(
        tenantId: tenantId,
      );
      await _mediator.executeCommandAsync(command);
      emit(state.copyWith(isSaving: false));
      await loadGroups();
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
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
      final tenantId = await _executionContext.requireTenantId();
      final command = ReorderCustomFieldGroupsCommand(
        tenantId: tenantId,
        orderedGroupIds: orderedGroupIds,
      );
      await _mediator.executeCommandAsync(command);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
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
      final tenantId = await _executionContext.requireTenantId();
      final command = UpsertCustomFieldGroupCommand(
        tenantId: tenantId,
        groupId: groupId,
        name: name,
        iconKey: iconKey,
        isActive: isActive,
      );
      await _mediator.executeCommandAsync(command);
      emit(state.copyWith(isSaving: false));
      await loadGroups();
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
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
      final tenantId = await _executionContext.requireTenantId();
      final command = ReorderCustomFieldsCommand(
        tenantId: tenantId,
        groupId: groupId,
        orderedFieldIds: orderedFieldIds,
      );
      await _mediator.executeCommandAsync(command);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
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
      final tenantId = await _executionContext.requireTenantId();
      // 1. Upsert field definition
      final upsertCommand = UpsertCustomFieldCommand(
        tenantId: tenantId,
        groupId: groupId,
        fieldId: fieldId,
        name: name,
        fieldType: fieldType,
        options: options ?? const [],
        isActive: isActive,
      );
      final result = await _mediator.executeCommandAsync(upsertCommand);

      // 2. Configure attributes
      final targetFieldId = fieldId ?? result.fieldId;
      final configCommand = ConfigureCustomFieldAttributesCommand(
        tenantId: tenantId,
        fieldId: targetFieldId,
        isRequired: isRequired,
        displayOnList: displayOnList,
        isSearchable: isSearchable,
        isFilterable: isFilterable,
      );
      await _mediator.executeCommandAsync(configCommand);

      emit(state.copyWith(isSaving: false));
      await loadGroups();
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
      return false;
    }
  }
}
