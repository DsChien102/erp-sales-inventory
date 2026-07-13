import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import '../../../../../core/di/injection.dart';

class CustomFieldGroupsPage extends StatefulWidget {
  const CustomFieldGroupsPage({super.key});

  @override
  State<CustomFieldGroupsPage> createState() => _CustomFieldGroupsPageState();
}

class _CustomFieldGroupsPageState extends State<CustomFieldGroupsPage> {
  late final CustomFieldConfigCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = CustomFieldConfigCubit(
      getIt<ICatalogModule>(),
      getIt<IExecutionContext>(),
    )..loadGroups();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: VAppBar(
          title: 'Nhóm & trường thông tin',
          showBackButton: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: colors.primary),
              onPressed: () async {
                await context.push(
                  '/more/product-settings/custom-fields/upsert-group',
                  extra: _cubit,
                );
                _cubit.loadGroups();
              },
            ),
          ],
        ),
        body: BlocConsumer<CustomFieldConfigCubit, CustomFieldConfigState>(
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
            if (state.isLoading && state.groups.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: colors.textMuted),
                    const SizedBox(height: VSpacing.space4),
                    Text(
                      'Chưa có nhóm thông tin nào',
                      style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: VSpacing.space4),
                    VButton(
                      label: 'Tạo mẫu mặc định',
                      onPressed: () => _cubit.initializeTemplate(),
                    ),
                  ],
                ),
              );
            }

            final groups = List<CustomFieldGroupConfigDto>.from(state.groups);
            // Sort inactive groups to the bottom, keeping their relative order otherwise.
            groups.sort((a, b) {
              final aActive = a.status.name == 'active' ? 1 : 0;
              final bActive = b.status.name == 'active' ? 1 : 0;
              if (aActive != bActive) {
                return bActive.compareTo(aActive);
              }
              return a.sortOrder.compareTo(b.sortOrder);
            });

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.screenMobile,
                    vertical: VSpacing.space3,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(VSpacing.space3),
                      decoration: BoxDecoration(
                        color: VColors.infoBg,
                        borderRadius: BorderRadius.circular(VRadius.r8),
                        border: Border.all(color: VColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: VColors.info, size: 20),
                          const SizedBox(width: VSpacing.space2),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'Thứ tự nhóm và trường sẽ hiển thị tương ứng trong màn hình sản phẩm. Kéo ',
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      Icons.drag_indicator,
                                      size: 16,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  const TextSpan(text: ' để sắp xếp.'),
                                ],
                              ),
                              style: VTypography.bodySmall.copyWith(color: colors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverReorderableList(
                  itemCount: groups.length,
                  onReorder: (oldIndex, newIndex) {
                    final originalOldGroup = groups[oldIndex];
                    final origOldIdx = state.groups.indexWhere((g) => g.groupId == originalOldGroup.groupId);
                    
                    int origNewIdx;
                    if (newIndex < groups.length) {
                      final originalNewGroup = groups[newIndex];
                      origNewIdx = state.groups.indexWhere((g) => g.groupId == originalNewGroup.groupId);
                    } else {
                      origNewIdx = state.groups.length;
                    }

                    if (origOldIdx != -1 && origNewIdx != -1) {
                      _cubit.reorderGroups(origOldIdx, origNewIdx);
                    }
                  },
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildGroupCard(context, group, index);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, CustomFieldGroupConfigDto group, int index) {
    final colors = context.vColors;

    return Container(
      key: ValueKey(group.groupId),
      margin: const EdgeInsets.only(
        left: VSpacing.screenMobile,
        right: VSpacing.screenMobile,
        bottom: VSpacing.space3,
      ),
      child: VCard(
        onTap: () async {
          await context.push(
            '/more/product-settings/custom-fields/${group.groupId}',
            extra: _cubit,
          );
          _cubit.loadGroups();
        },
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: VSpacing.space3),
                child: Icon(
                  Icons.drag_indicator,
                  color: colors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: VTypography.headingH4.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: VSpacing.space2),
                      VBadge(
                        label: group.status.name == 'active' ? 'Đang dùng' : 'Tạm tắt',
                        status: group.status.name == 'active'
                            ? VBadgeStatus.success
                            : VBadgeStatus.draft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.fieldCount} trường • ${group.requiredFieldCount} bắt buộc',
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Icon(
              Icons.chevron_right,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
