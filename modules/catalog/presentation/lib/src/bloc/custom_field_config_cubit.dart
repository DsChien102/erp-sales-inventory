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

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    final groups = _reorderItems(state.groups, oldIndex, newIndex);
    if (groups == null) return;
    final orderedIds = groups.map((e) => e.groupId).toList();

    // Optimistic update
    emit(state.copyWith(groups: groups));

    try {
      final tenantId = await _executionContext.requireTenantId();
      final command = ReorderCustomFieldGroupsCommand(
        tenantId: tenantId,
        orderedGroupIds: orderedIds,
      );
      await _mediator.executeCommandAsync(command);
    } catch (e) {
      // Revert on error
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

  Future<void> reorderFields(String groupId, int oldIndex, int newIndex) async {
    final groupIndex = state.groups.indexWhere((g) => g.groupId == groupId);
    if (groupIndex == -1) return;

    final group = state.groups[groupIndex];
    final fields = _reorderItems(group.fields, oldIndex, newIndex);
    if (fields == null) return;

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

    final orderedIds = fields.map((e) => e.fieldId).toList();

    // Optimistic update
    emit(state.copyWith(groups: updatedGroups));

    try {
      final tenantId = await _executionContext.requireTenantId();
      final command = ReorderCustomFieldsCommand(
        tenantId: tenantId,
        groupId: groupId,
        orderedFieldIds: orderedIds,
      );
      await _mediator.executeCommandAsync(command);
    } catch (e) {
      // Revert
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
  /// ReorderableListView passes [newIndex] relative to the list before removal.
  /// When dragging down, decrement [newIndex] after [oldIndex] is removed.
  List<T>? _reorderItems<T>(List<T> items, int oldIndex, int newIndex) {
    if (items.isEmpty || oldIndex < 0 || oldIndex >= items.length) {
      return null;
    }

    var insertIndex = newIndex;
    if (insertIndex > oldIndex) {
      insertIndex -= 1;
    }
    if (insertIndex == oldIndex) {
      return null;
    }

    final reordered = List<T>.from(items);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(insertIndex.clamp(0, reordered.length), item);
    return reordered;
  }
}
