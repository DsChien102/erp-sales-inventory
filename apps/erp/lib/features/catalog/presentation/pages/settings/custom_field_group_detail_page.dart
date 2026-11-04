import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation.dart';
import '../../../data/models.dart';

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

          return VPageScaffold(
            title: group?.name ?? 'Trường thông tin',
            actions: [
              IconButton(
                icon: VIcon(icon: VIcons.moreVert, color: colors.textPrimary),
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
            body: group == null
                ? const Center(child: VText('Không tìm thấy nhóm'))
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
        ? colors.success
        : colors.textMuted;
    final statusBg = group.status == CustomFieldConfigStatus.active
        ? colors.successBg
        : colors.surfaceAlt;
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
                  child: VText(
                    statusText,
                    variant: VTextVariant.bodySmall,
                    color: statusColor,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VText(
                  '${group.fieldCount} trường • ${group.requiredFieldCount} bắt buộc',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
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
                VText(
                  'TRƯỜNG THÔNG TIN',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/more/product-settings/custom-fields/$groupId/upsert-field',
                    extra: cubit,
                  ),
                  child: Row(
                    children: [
                      VIcon(icon: VIcons.add, size: 16, color: colors.success),
                      const VGap.horizontalXs(),
                      VText(
                        'Thêm trường',
                        variant: VTextVariant.bodySmall,
                        color: colors.success,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
            onReorderItem: (oldIndex, newIndex) {
              if (newIndex == oldIndex) return;

              final reordered = List<CustomFieldDefinitionDto>.from(fields);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              cubit.reorderFields(
                groupId,
                reordered.map((field) => field.fieldId).toList(),
              );
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
          border: Border.all(color: colors.borderDefault, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(VSpacing.space3),
              decoration: BoxDecoration(
                color: colors.successBg,
                borderRadius: BorderRadius.circular(VRadius.r12),
              ),
              child: VIcon(icon: VIcons.checkList, size: 32, color: colors.success),
            ),
            const SizedBox(height: VSpacing.space4),
            VText(
              'Chưa có trường nào',
              variant: VTextVariant.headingH4,
              color: colors.textPrimary,
            ),
            const SizedBox(height: VSpacing.space2),
            VText(
              'Thêm trường đầu tiên cho nhóm này.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space6),
            VButton(
              onPressed: () => context.push(
                '/more/product-settings/custom-fields/$groupId/upsert-field',
                extra: cubit,
              ),
              variant: VButtonVariant.primary,
              leading: VIcons.add,
              label: 'Thêm trường thông tin',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, CustomFieldDefinitionDto field, int index) {
    final colors = context.vColors;
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
              child: VIcon(
                icon: VIcons.gripVertical,
                color: colors.textMuted,
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
                        child: VText(
                          field.name,
                          variant: VTextVariant.headingH4,
                          color: isInactive ? colors.textSecondary : colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (field.isRequired) ...[
                        const SizedBox(width: VSpacing.space1),
                        VText('*', variant: VTextVariant.headingH4, color: colors.danger),
                      ],
                      if (isInactive) ...[
                        const SizedBox(width: VSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.surfaceAlt,
                            borderRadius: BorderRadius.circular(VRadius.pill),
                          ),
                          child: VText(
                            'Tạm tắt',
                            variant: VTextVariant.caption,
                            color: colors.textMuted,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: VSpacing.space1),
                  VText(
                    [
                      typeLabel,
                      if (field.isRequired) 'Bắt buộc',
                      if (attrString.isNotEmpty) attrString,
                    ].join(' • '),
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            VIcon(
              icon: VIcons.chevronRight,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
