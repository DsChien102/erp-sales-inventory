import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

class CustomFieldGroupDetailPage extends StatelessWidget {
  final String groupId;
  final CustomFieldConfigCubit cubit;

  const CustomFieldGroupDetailPage({
    super.key,
    required this.groupId,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<CustomFieldConfigCubit, CustomFieldConfigState>(
        listener: (context, state) {
          if (state.error != null) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.error!,
              type: VToastType.danger,
            );
          }
        },
        builder: (context, state) {
          final groupIndex = state.groups.indexWhere((g) => g.groupId == groupId);
          final group = groupIndex != -1 ? state.groups[groupIndex] : null;

          return Scaffold(
            backgroundColor: colors.surface,
            appBar: VAppBar(
              title: group?.name ?? 'Trường thông tin',
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: VColors.textPrimary),
                  onPressed: () {
                    if (group != null) {
                      context
                          .push(
                            '/more/product-settings/custom-fields/upsert-group?groupId=${group.groupId}',
                            extra: cubit,
                          )
                          .then((_) => cubit.loadGroups());
                    }
                  },
                ),
              ],
            ),
            body: group == null
                ? const Center(child: Text('Không tìm thấy nhóm'))
                : _buildBody(context, group, colors),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CustomFieldGroupConfigDto group, VColorScheme colors) {
    final fields = List<CustomFieldDefinitionDto>.from(group.fields);
    
    // Sort inactive fields to the bottom, keeping their relative order otherwise.
    fields.sort((a, b) {
      final aActive = a.status == CustomFieldConfigStatus.active ? 1 : 0;
      final bActive = b.status == CustomFieldConfigStatus.active ? 1 : 0;
      if (aActive != bActive) {
        return bActive.compareTo(aActive); // 1 comes before 0, so active is first.
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    final statusColor = group.status == CustomFieldConfigStatus.active
        ? VColors.success
        : VColors.textMuted;
    final statusBg = group.status == CustomFieldConfigStatus.active
        ? VColors.successBg
        : VColors.neutral100;
    final statusText = group.status == CustomFieldConfigStatus.active ? 'Đang dùng' : 'Tạm tắt';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space3,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    statusText,
                    style: VTypography.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.fieldCount} trường • ${group.requiredFieldCount} bắt buộc',
                  style: VTypography.bodySmall.copyWith(color: VColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRƯỜNG THÔNG TIN',
                  style: VTypography.bodySmall.copyWith(
                    color: VColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/more/product-settings/custom-fields/$groupId/upsert-field',
                    extra: cubit,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: VColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Thêm trường',
                        style: VTypography.bodySmall.copyWith(
                          color: VColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (fields.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyState(context, colors),
          )
        else
          SliverReorderableList(
            itemCount: fields.length,
            onReorder: (oldIndex, newIndex) {
              final originalOldField = fields[oldIndex];
              final origOldIdx = group.fields.indexWhere((f) => f.fieldId == originalOldField.fieldId);
              
              int origNewIdx;
              if (newIndex < fields.length) {
                final originalNewField = fields[newIndex];
                origNewIdx = group.fields.indexWhere((f) => f.fieldId == originalNewField.fieldId);
              } else {
                origNewIdx = group.fields.length;
              }

              if (origOldIdx != -1 && origNewIdx != -1) {
                cubit.reorderFields(groupId, origOldIdx, origNewIdx);
              }
            },
            itemBuilder: (context, index) {
              final field = fields[index];
              return _buildFieldCard(context, field, index);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, VColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.r12),
          border: Border.all(color: VColors.borderDefault, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checklist, size: 32, color: VColors.success),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có trường nào',
              style: VTypography.headingH4.copyWith(color: VColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm trường đầu tiên cho nhóm này.',
              style: VTypography.bodyDefault.copyWith(color: VColors.textSecondary),
            ),
            const SizedBox(height: 24),
            VButton(
              onPressed: () => context.push(
                '/more/product-settings/custom-fields/$groupId/upsert-field',
                extra: cubit,
              ),
              variant: VButtonVariant.primary,
              leadingIcon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: 'Thêm trường thông tin',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, CustomFieldDefinitionDto field, int index) {
    String typeLabel = '';
    switch (field.fieldType.name) {
      case 'text':
        typeLabel = 'Text';
        break;
      case 'number':
        typeLabel = 'Số';
        break;
      case 'date':
        typeLabel = 'Ngày tháng';
        break;
      case 'boolean':
        typeLabel = 'Bật/Tắt';
        break;
      case 'singleSelect':
        typeLabel = 'Single select';
        break;
      case 'multiSelect':
        typeLabel = 'Multi select';
        break;
      case 'paragraph':
        typeLabel = 'Đoạn văn dài';
        break;
      default:
        typeLabel = field.fieldType.name;
    }

    final attrs = <String>[];
    if (field.isSearchable) attrs.add('Tìm kiếm');
    if (field.isFilterable) attrs.add('Lọc');
    if (field.displayOnList) attrs.add('Hiển thị');
    final attrString = attrs.join(' • ');

    final isInactive = field.status != CustomFieldConfigStatus.active;

    return Container(
      key: ValueKey(field.fieldId),
      margin: const EdgeInsets.only(
        left: VSpacing.screenMobile,
        right: VSpacing.screenMobile,
        bottom: VSpacing.space3,
      ),
      child: VCard(
        onTap: () => context.push(
          '/more/product-settings/custom-fields/$groupId/upsert-field?fieldId=${field.fieldId}',
          extra: cubit,
        ),
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_indicator,
                color: VColors.textMuted,
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          field.name,
                          style: VTypography.headingH4.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isInactive ? VColors.textSecondary : VColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (field.isRequired) ...[
                        const SizedBox(width: 4),
                        Text('*', style: VTypography.headingH4.copyWith(color: VColors.danger)),
                      ],
                      if (isInactive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VColors.neutral100,
                            borderRadius: BorderRadius.circular(VRadius.pill),
                          ),
                          child: Text(
                            'Tạm tắt',
                            style: VTypography.caption.copyWith(
                              color: VColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      typeLabel,
                      if (field.isRequired) 'Bắt buộc',
                      if (attrString.isNotEmpty) attrString,
                    ].join(' • '),
                    style: VTypography.bodySmall.copyWith(color: VColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            const Icon(
              Icons.chevron_right,
              color: VColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
